import 'dart:math';
import 'booking_model.dart';
import 'firestore_service.dart';
import 'idempotency_manager.dart';
import 'simulated_confirmation_engine.dart';
import '../../services/central_trace_logger.dart';

class BookingAgentService {
  final FirestoreService _firestoreService;
  final IdempotencyManager _idempotencyManager;
  final SimulatedConfirmationEngine _confirmationEngine;
  final CentralTraceLogger _traceLogger;

  BookingAgentService({
    FirestoreService? firestoreService,
    IdempotencyManager? idempotencyManager,
    SimulatedConfirmationEngine? confirmationEngine,
    CentralTraceLogger? traceLogger,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _idempotencyManager = idempotencyManager ?? IdempotencyManager(firestoreService: firestoreService),
        _confirmationEngine = confirmationEngine ?? SimulatedConfirmationEngine(),
        _traceLogger = traceLogger ?? CentralTraceLogger();

  Future<BookingResponse> processRequest(BookingRequest request) async {
    final traceId = 'trace_book_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    try {
      // 0. Early Return Protection
      final activeSessionDoc = await _firestoreService.getDocument('orchestration_sessions', request.sessionId);
      if (activeSessionDoc != null) {
        final pipelineStatus = activeSessionDoc['pipeline_status'] as String?;
        if (pipelineStatus == 'running_bookingagent' || pipelineStatus == 'completed') {
          print('Booking already processing or completed. Returning early.');
          return _buildDegradedFallbackResponse(request, traceId, 'Booking already in progress');
        }
      }

      // 1. Validate Orchestration Session Integrity
      final isSessionValid = await _idempotencyManager.validateSession(request.sessionId);
      final activeSessionId = isSessionValid ? request.sessionId : 'temp_sess_${request.sessionId.hashCode}';
      final isSessionDegraded = !isSessionValid;

      // 2. Validate Pricing Data Integrity
      final isPricingValid = request.pricingData.totalPricePkr > 0;
      final activePrice = isPricingValid ? request.pricingData.totalPricePkr : 500.0;
      final isPricingDegraded = !isPricingValid;

      final isOrchestrationDegraded = isSessionDegraded || isPricingDegraded;
      final activeOrchestrationStatus = isOrchestrationDegraded ? 'failed_degraded' : 'success';

      // 3. Perform Availability & Idempotency Check (using activeSessionId)
      final checkResult = await _idempotencyManager.checkSafety(
        sessionId: activeSessionId,
        providerId: request.selectedProvider.providerId,
        requestedTime: request.userRequest.requestedTime,
      );

      // Handle Idempotent Match (Identical session already exists)
      if (checkResult.state == BookingCheckState.idempotentMatch) {
        final existing = checkResult.existingBooking!;
        final bookingId = existing['booking_id'] as String? ?? 'book_$activeSessionId';
        final status = existing['booking_status'] as String? ?? 'confirmed';

        final response = BookingResponse(
          bookingId: bookingId,
          bookingStatus: status,
          provider: request.selectedProvider,
          scheduledTime: request.userRequest.requestedTime,
          customerSummary: CustomerSummary(
            customerId: 'user_customer_999',
            name: 'Valued Customer',
            contactNumber: '+923001234567',
          ),
          notificationRequired: true,
          orchestrationMetadata: OrchestrationMetadata(
            sessionId: activeSessionId,
            requestId: request.requestId,
            traceId: traceId,
            orchestrationStatus: activeOrchestrationStatus,
            currentAgent: 'BookingAgent',
            nextAgent: 'NotificationAgent',
          ),
          alternativeRecommendation: null,
          pricingData: {
            'total_price_pkr': activePrice,
            'confidence_score': request.pricingData.confidenceScore,
            'breakdown': request.pricingData.breakdown,
          },
          notificationPayload: _buildNotificationPayload(request, bookingId, activePrice),
        );

        // Async log trace
        _traceLogger.logTrace(
          traceId: traceId,
          sessionId: activeSessionId,
          userId: request.requestId,
          agentName: 'BookingAgent',
          decision: 'Idempotent transaction. Existing booking returned: $bookingId',
          confidence: 1.0,
          orchestrationStatus: response.orchestrationMetadata.orchestrationStatus,
          reasoning: {
            'idempotency': 'matched',
            'provider_availability': 'skipped_idempotent',
            'slot_simulation': 'skipped_idempotent',
            'session_degraded': isSessionDegraded,
            'pricing_degraded': isPricingDegraded,
          },
        );

        return response;
      }

      // Handle Provider Unavailable or Double Booking Conflict
      if (checkResult.state == BookingCheckState.providerUnavailable ||
          checkResult.state == BookingCheckState.providerDoubleBookedConflict) {
        
        final failureReason = checkResult.state == BookingCheckState.providerUnavailable
            ? 'provider_unavailable'
            : 'provider_double_booked';

        // Query active alternative providers
        final backupDoc = await _idempotencyManager.findBackupProvider(
          serviceType: request.selectedProvider.serviceType,
          excludedProviderId: request.selectedProvider.providerId,
        );

        AlternativeRecommendation? altRec;
        if (backupDoc != null) {
          final rating = (backupDoc['rating'] as num?)?.toDouble() ?? 4.5;
          final name = backupDoc['name'] as String? ?? 'Backup Provider';
          altRec = AlternativeRecommendation(
            providerId: backupDoc['provider_id'] as String? ?? '',
            name: name,
            rating: rating,
            serviceType: backupDoc['service_type'] as String? ?? request.selectedProvider.serviceType,
            reason: 'Next best available ${request.selectedProvider.serviceType.replaceAll('_', ' ')} with rating $rating',
          );
        }

        final response = _buildConflictOrFailedResponse(
          request: request,
          traceId: traceId,
          activeSessionId: activeSessionId,
          failureReason: failureReason,
          alternativeRecommendation: altRec,
          activePrice: activePrice,
        );

        _traceLogger.logTrace(
          traceId: traceId,
          sessionId: activeSessionId,
          userId: request.requestId,
          agentName: 'BookingAgent',
          decision: 'Booking rejected: $failureReason.',
          confidence: 1.0,
          orchestrationStatus: response.orchestrationMetadata.orchestrationStatus,
          reasoning: {
            'idempotency': 'clear',
            'provider_availability': checkResult.state == BookingCheckState.providerUnavailable ? 'unavailable' : 'active',
            'slot_simulation': checkResult.state == BookingCheckState.providerDoubleBookedConflict ? 'blocked_conflict' : 'not_started',
            'session_degraded': isSessionDegraded,
            'pricing_degraded': isPricingDegraded,
            'alternative_provider_found': altRec != null,
          },
        );
        return response;
      }

      // 4. Simulate Provider Confirmation outreach via Gemini Simulation Engine
      final providerDoc = await _firestoreService.getDocument('providers', request.selectedProvider.providerId);
      final rating = (providerDoc?['rating'] as num?)?.toDouble() ?? 4.5;

      final simResult = _confirmationEngine.simulate(
        providerName: request.selectedProvider.name,
        providerId: request.selectedProvider.providerId,
        providerRating: rating,
        serviceType: request.selectedProvider.serviceType,
        requestedTime: request.userRequest.requestedTime,
        urgency: request.userRequest.urgency,
        totalPricePkr: activePrice,
      );

      final bookingId = 'book_$activeSessionId';

      if (simResult.confirmed) {
        // Construct successful Response
        final response = BookingResponse(
          bookingId: bookingId,
          bookingStatus: 'confirmed',
          provider: request.selectedProvider,
          scheduledTime: request.userRequest.requestedTime,
          customerSummary: CustomerSummary(
            customerId: 'user_customer_999',
            name: 'Valued Customer',
            contactNumber: '+923001234567',
          ),
          notificationRequired: true,
          orchestrationMetadata: OrchestrationMetadata(
            sessionId: activeSessionId,
            requestId: request.requestId,
            traceId: traceId,
            orchestrationStatus: activeOrchestrationStatus,
            currentAgent: 'BookingAgent',
            nextAgent: 'NotificationAgent',
          ),
          alternativeRecommendation: null,
          pricingData: {
            'total_price_pkr': activePrice,
            'confidence_score': request.pricingData.confidenceScore,
            'breakdown': request.pricingData.breakdown,
          },
          notificationPayload: _buildNotificationPayload(request, bookingId, activePrice),
        );

        // Write Booking document to Firestore
        final bookingData = {
          'booking_id': bookingId,
          'session_id': activeSessionId,
          'request_id': request.requestId,
          'provider_id': request.selectedProvider.providerId,
          'customer_id': 'user_customer_999',
          'service_type': request.selectedProvider.serviceType,
          'requested_time': request.userRequest.requestedTime.toIso8601String(),
          'total_price_pkr': activePrice,
          'pricing_breakdown': request.pricingData.breakdown,
          'booking_status': 'confirmed',
          'payment_method': request.bookingMetadata?.paymentMethod ?? 'cash_on_delivery',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'idempotency_key': activeSessionId,
          'simulated_confirmation_trace': simResult.reasoningTrace,
        };
        await _firestoreService.saveDocument('bookings', bookingId, bookingData);

        // Async log trace
        _traceLogger.logTrace(
          traceId: traceId,
          sessionId: activeSessionId,
          userId: request.requestId,
          agentName: 'BookingAgent',
          decision: 'Booking successfully confirmed by provider.',
          confidence: simResult.confidenceScore,
          orchestrationStatus: response.orchestrationMetadata.orchestrationStatus,
          reasoning: {
            'idempotency': 'clear',
            'provider_availability': 'verified_active',
            'slot_simulation': 'confirmed',
            'monologue': simResult.reasoningTrace,
            'session_degraded': isSessionDegraded,
            'pricing_degraded': isPricingDegraded,
          },
        );

        return response;
      } else {
        // Gemini Simulation Engine returned false (confirmation failed)
        // Find alternative since original provider declined
        final backupDoc = await _idempotencyManager.findBackupProvider(
          serviceType: request.selectedProvider.serviceType,
          excludedProviderId: request.selectedProvider.providerId,
        );

        AlternativeRecommendation? altRec;
        if (backupDoc != null) {
          final rating = (backupDoc['rating'] as num?)?.toDouble() ?? 4.5;
          final name = backupDoc['name'] as String? ?? 'Backup Provider';
          altRec = AlternativeRecommendation(
            providerId: backupDoc['provider_id'] as String? ?? '',
            name: name,
            rating: rating,
            serviceType: backupDoc['service_type'] as String? ?? request.selectedProvider.serviceType,
            reason: 'Next best available ${request.selectedProvider.serviceType.replaceAll('_', ' ')} with rating $rating',
          );
        }

        final response = _buildConflictOrFailedResponse(
          request: request,
          traceId: traceId,
          activeSessionId: activeSessionId,
          failureReason: 'provider_declined',
          alternativeRecommendation: altRec,
          activePrice: activePrice,
        );

        _traceLogger.logTrace(
          traceId: traceId,
          sessionId: activeSessionId,
          userId: request.requestId,
          agentName: 'BookingAgent',
          decision: 'Booking declined by provider during simulation.',
          confidence: simResult.confidenceScore,
          orchestrationStatus: response.orchestrationMetadata.orchestrationStatus,
          reasoning: {
            'idempotency': 'clear',
            'provider_availability': 'verified_active',
            'slot_simulation': 'declined',
            'monologue': simResult.reasoningTrace,
            'session_degraded': isSessionDegraded,
            'pricing_degraded': isPricingDegraded,
          },
        );
        return response;
      }
    } catch (e) {
      // Graceful Fallback on catastrophic outage
      return _buildDegradedFallbackResponse(request, traceId, e.toString());
    }
  }

  BookingResponse _buildConflictOrFailedResponse({
    required BookingRequest request,
    required String traceId,
    required String activeSessionId,
    required String failureReason,
    required AlternativeRecommendation? alternativeRecommendation,
    required double activePrice,
  }) {
    RecipientNotification userNotification;
    
    if (alternativeRecommendation != null) {
      final name = alternativeRecommendation.name;
      final rating = alternativeRecommendation.rating.toStringAsFixed(1);
      userNotification = RecipientNotification(
        recipientId: 'user_customer_999',
        channel: 'sms',
        template: 'booking_conflict_recommendation',
        message: 'Assalam-o-Alaikum! ${request.selectedProvider.name} is currently busy at that hour. We recommend $name (Rating: $rating) who is available immediately. Reply YES to confirm booking.',
      );
    } else {
      userNotification = RecipientNotification(
        recipientId: 'user_customer_999',
        channel: 'sms',
        template: 'booking_failed',
        message: 'Booking failed: $failureReason',
      );
    }

    return BookingResponse(
      bookingId: 'book_$activeSessionId',
      bookingStatus: 'failed',
      provider: request.selectedProvider,
      scheduledTime: request.userRequest.requestedTime,
      customerSummary: CustomerSummary(
        customerId: 'user_customer_999',
        name: 'Valued Customer',
        contactNumber: '+923001234567',
      ),
      notificationRequired: true,
      orchestrationMetadata: OrchestrationMetadata(
        sessionId: activeSessionId,
        requestId: request.requestId,
        traceId: traceId,
        orchestrationStatus: 'failed',
        currentAgent: 'BookingAgent',
        nextAgent: 'NotificationAgent',
      ),
      alternativeRecommendation: alternativeRecommendation,
      pricingData: {
        'total_price_pkr': activePrice,
        'confidence_score': request.pricingData.confidenceScore,
      },
      notificationPayload: NotificationPayload(
        user: userNotification,
        provider: RecipientNotification(
          recipientId: request.selectedProvider.providerId,
          channel: 'sms',
          template: 'booking_failed',
          message: 'Booking failed: $failureReason',
        ),
      ),
    );
  }

  BookingRequest _copyWithActiveSessionAndPrice(
    BookingRequest original,
    String activeSession,
    double activePrice,
  ) {
    return BookingRequest(
      requestId: original.requestId,
      sessionId: activeSession,
      orchestrationStatus: original.orchestrationStatus,
      selectedProvider: original.selectedProvider,
      pricingData: PricingData(
        totalPricePkr: activePrice,
        confidenceScore: original.pricingData.confidenceScore,
        breakdown: original.pricingData.breakdown,
      ),
      userRequest: original.userRequest,
      bookingMetadata: original.bookingMetadata,
    );
  }

  BookingResponse _buildDegradedFallbackResponse(
    BookingRequest request,
    String traceId,
    String error,
  ) {
    final bookingId = 'book_fallback_${request.sessionId}';
    final response = BookingResponse(
      bookingId: bookingId,
      bookingStatus: 'failed',
      provider: request.selectedProvider,
      scheduledTime: request.userRequest.requestedTime,
      customerSummary: CustomerSummary(
        customerId: 'user_customer_999',
        name: 'Valued Customer',
        contactNumber: '+923001234567',
      ),
      notificationRequired: false,
      orchestrationMetadata: OrchestrationMetadata(
        sessionId: request.sessionId,
        requestId: request.requestId,
        traceId: traceId,
        orchestrationStatus: 'failed_degraded',
        currentAgent: 'BookingAgent',
        nextAgent: 'NotificationAgent',
      ),
      alternativeRecommendation: null,
      pricingData: {
        'error': 'Catastrophic Booking Agent failure: $error',
        'total_price_pkr': request.pricingData.totalPricePkr > 0 ? request.pricingData.totalPricePkr : 500.0,
      },
      notificationPayload: NotificationPayload(
        user: RecipientNotification(
          recipientId: 'user_customer_999',
          channel: 'sms',
          template: 'booking_pending_manual',
          message: 'Assalam-o-Alaikum! Your booking request has been received, but we are experiencing a connection lag. We will notify you shortly.',
        ),
        provider: RecipientNotification(
          recipientId: request.selectedProvider.providerId,
          channel: 'sms',
          template: 'booking_pending_manual',
          message: 'A booking slot has been requested but session is degraded. Please check app shortly.',
        ),
      ),
    );

    // Attempt to log failure trace
    _traceLogger.logTrace(
      traceId: traceId,
      sessionId: request.sessionId,
      userId: request.requestId,
      agentName: 'BookingAgent',
      decision: 'Catastrophic error triggered fallback execution.',
      confidence: 0.1,
      orchestrationStatus: response.orchestrationMetadata.orchestrationStatus,
      reasoning: {
        'error': error,
        'status': 'degraded',
      },
    );

    return response;
  }

  NotificationPayload _buildNotificationPayload(BookingRequest request, String bookingId, double activePrice) {
    final formattedTime = '${request.userRequest.requestedTime.hour.toString().padLeft(2, '0')}:${request.userRequest.requestedTime.minute.toString().padLeft(2, '0')}';
    final providerName = request.selectedProvider.name;
    final service = request.selectedProvider.serviceType.replaceAll('_', ' ').toUpperCase();
    final price = activePrice.toStringAsFixed(0);

    return NotificationPayload(
      user: RecipientNotification(
        recipientId: 'user_customer_999',
        channel: 'sms',
        template: 'booking_confirmed',
        message: 'Assalam-o-Alaikum! Your booking for $service ($providerName) has been CONFIRMED for $formattedTime. Total amount: $price PKR. Thank you for choosing BolDo!',
      ),
      provider: RecipientNotification(
        recipientId: request.selectedProvider.providerId,
        channel: 'sms',
        template: 'new_job_assigned',
        message: 'New job assigned! You have a booking for $service on $formattedTime. Total earning: $price PKR. Please confirm availability in the app.',
      ),
    );
  }
}
