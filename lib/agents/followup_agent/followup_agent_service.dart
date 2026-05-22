import 'dart:math';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart' show SelectedProvider, CustomerSummary, OrchestrationMetadata;
import 'firestore_service.dart';
import 'followup_model.dart';
import '../../services/central_trace_logger.dart';

class FollowUpAgentService {
  final FirestoreService _firestoreService;
  final CentralTraceLogger _traceLogger;

  FollowUpAgentService({
    FirestoreService? firestoreService,
    CentralTraceLogger? traceLogger,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _traceLogger = traceLogger ?? CentralTraceLogger();

  Future<void> _persistFollowUpDocument({
    required String docId,
    required String sessionId,
    required String bookingId,
    required String recipientId,
    required String followupType,
    required String message,
    required String scheduledAt,
  }) async {
    final data = {
      'followup_id': docId,
      'session_id': sessionId,
      'booking_id': bookingId,
      'recipient_id': recipientId,
      'followup_type': followupType,
      'message': message,
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'scheduled_at': scheduledAt,
    };
    await _firestoreService.saveDocument('followups', docId, data);
  }

  Future<FollowUpResponse> processRequest(FollowUpRequest request) async {
    final traceId = 'trace_follow_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    try {
      // 1. Input Validation
      if (request.bookingId.trim().isEmpty) {
        throw ArgumentError('booking_id cannot be empty');
      }
      if (request.sessionId.trim().isEmpty) {
        throw ArgumentError('session_id cannot be empty');
      }
      if (request.bookingStatus.trim().isEmpty) {
        throw ArgumentError('booking_status cannot be empty');
      }

      final docId = 'followup_${request.sessionId}';

      // 2. Idempotency Check (repeat requests)
      final existingRecord = await _firestoreService.getDocument('followups', docId);
      if (existingRecord != null) {
        final List<FollowUpAction> actions = [];
        if (existingRecord['actions'] != null) {
          for (final a in existingRecord['actions'] as List) {
            actions.add(FollowUpAction.fromJson(Map<String, dynamic>.from(a as Map)));
          }
        }

        final response = FollowUpResponse(
          status: 'success',
          followupsCreated: actions.length,
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          agent: 'FollowUpAgent',
          timestamp: DateTime.now().toUtc().toIso8601String(),
          orchestrationStatus: request.orchestrationMetadata.orchestrationStatus,
          isSuccess: true,
          actions: actions,
          followUpRecord: existingRecord,
        );

        // Log trace for idempotency match
        await _traceLogger.logTrace(
          traceId: traceId,
          sessionId: request.sessionId,
          userId: request.orchestrationMetadata.requestId,
          agentName: 'FollowUpAgent',
          decision: 'Idempotency Match: Follow-up engagement already processed.',
          confidence: 1.0,
          orchestrationStatus: request.orchestrationMetadata.orchestrationStatus,
          reasoning: {
            'idempotency': 'matched',
            'saved_status': existingRecord['status'],
            'skipped_regeneration': true,
            'generated_followups_count': actions.length,
          },
        );

        return response;
      }

      // 3. Process according to booking status
      final List<FollowUpAction> generatedActions = [];
      final Map<String, dynamic> recordData = {
        'booking_id': request.bookingId,
        'session_id': request.sessionId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'rating': request.rating,
        'feedback': request.feedback,
        'sentiment': null,
        're_engagement_triggered': false,
        'dispute_triggered': false,
      };

      String decisionMessage = '';
      double confidence = 1.0;
      final Map<String, dynamic> reasoningBreakdown = {
        'idempotency': 'clear',
        'status': request.bookingStatus,
      };

      if (request.bookingStatus == 'confirmed') {
        // Determine reminder time: 1 hour before scheduled time. If already past or within 1 hour, set for 5 minutes from now.
        final now = DateTime.now();
        var reminderTime = request.scheduledTime.subtract(const Duration(hours: 1));
        if (reminderTime.isBefore(now)) {
          reminderTime = now.add(const Duration(minutes: 5));
        }
        final serviceEndTime = request.scheduledTime.add(const Duration(hours: 2));

        final serviceReminderMsg = 'Reminder: your ${request.provider.serviceType} booking is scheduled soon.';
        final completionCheckMsg = 'Was your service completed successfully?';
        final ratingRequestMsg = 'Please rate your experience from 1-5.';

        final reminderAction = FollowUpAction(
          type: 'service_reminder',
          scheduledTime: reminderTime.toUtc().toIso8601String(),
          payload: {
            'recipient_id': request.customerSummary.customerId,
            'channel': 'sms',
            'message': serviceReminderMsg,
          },
        );
        generatedActions.add(reminderAction);
        await _persistFollowUpDocument(
          docId: 'followup_reminder_${request.sessionId}',
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          recipientId: request.customerSummary.customerId,
          followupType: 'service_reminder',
          message: serviceReminderMsg,
          scheduledAt: reminderTime.toUtc().toIso8601String(),
        );

        final completionCheckAction = FollowUpAction(
          type: 'completion_check',
          scheduledTime: serviceEndTime.toUtc().toIso8601String(),
          payload: {
            'recipient_id': request.customerSummary.customerId,
            'channel': 'sms',
            'message': completionCheckMsg,
          },
        );
        generatedActions.add(completionCheckAction);
        await _persistFollowUpDocument(
          docId: 'followup_completion_${request.sessionId}',
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          recipientId: request.customerSummary.customerId,
          followupType: 'completion_check',
          message: completionCheckMsg,
          scheduledAt: serviceEndTime.toUtc().toIso8601String(),
        );

        final ratingRequestAction = FollowUpAction(
          type: 'rating_request',
          scheduledTime: serviceEndTime.toUtc().toIso8601String(),
          payload: {
            'recipient_id': request.customerSummary.customerId,
            'channel': 'sms',
            'message': ratingRequestMsg,
          },
        );
        generatedActions.add(ratingRequestAction);
        await _persistFollowUpDocument(
          docId: 'followup_rating_${request.sessionId}',
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          recipientId: request.customerSummary.customerId,
          followupType: 'rating_request',
          message: ratingRequestMsg,
          scheduledAt: serviceEndTime.toUtc().toIso8601String(),
        );

        recordData['status'] = 'confirmed_followups_scheduled';
        recordData['reminders'] = [
          {
            'reminder_time': reminderTime.toUtc().toIso8601String(),
            'message': serviceReminderMsg,
            'status': 'scheduled',
            'recipient_id': request.customerSummary.customerId,
          }
        ];
        recordData['completion_checks'] = [
          {
            'check_time': serviceEndTime.toUtc().toIso8601String(),
            'message': completionCheckMsg,
            'status': 'scheduled',
            'recipient_id': request.customerSummary.customerId,
          }
        ];
        recordData['rating_requests'] = [
          {
            'request_time': serviceEndTime.toUtc().toIso8601String(),
            'message': ratingRequestMsg,
            'status': 'scheduled',
            'recipient_id': request.customerSummary.customerId,
          }
        ];

        decisionMessage = 'Successfully scheduled service reminder, completion check, and rating request.';
        reasoningBreakdown['service_reminder_created'] = true;
        reasoningBreakdown['completion_check_created'] = true;
        reasoningBreakdown['rating_request_created'] = true;

      } else if (request.bookingStatus == 'completed') {
        // Step 4: Feedback Collection & Sentiment Detection
        final double? rating = request.rating;
        final String? feedback = request.feedback;

        final ratingRequestMsg = 'Please rate your experience from 1-5.';
        final ratingRequestAction = FollowUpAction(
          type: 'rating_request',
          scheduledTime: DateTime.now().toUtc().toIso8601String(),
          payload: {
            'recipient_id': request.customerSummary.customerId,
            'channel': 'sms',
            'message': ratingRequestMsg,
          },
        );
        generatedActions.add(ratingRequestAction);
        await _persistFollowUpDocument(
          docId: 'followup_rating_${request.sessionId}',
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          recipientId: request.customerSummary.customerId,
          followupType: 'rating_request',
          message: ratingRequestMsg,
          scheduledAt: DateTime.now().toUtc().toIso8601String(),
        );

        if (rating != null) {
          // Sentiment analysis
          String sentiment = 'neutral';
          final fText = (feedback ?? '').toLowerCase();
          final negativeKeywords = ['bad', 'worst', 'poor', 'slow', 'unprofessional', 'fraud', 'broken', 'disappointed', 'terrible', 'waste'];
          bool hasNegativeWord = false;
          for (final kw in negativeKeywords) {
            if (fText.contains(kw)) {
              hasNegativeWord = true;
              break;
            }
          }

          if (rating >= 4.0 && !hasNegativeWord) {
            sentiment = 'positive';
          } else if (rating <= 2.0 || hasNegativeWord) {
            sentiment = 'negative';
          }

          recordData['sentiment'] = sentiment;
          reasoningBreakdown['rating_received'] = rating;
          reasoningBreakdown['feedback_received'] = feedback ?? '';
          reasoningBreakdown['detected_sentiment'] = sentiment;

          if (sentiment == 'negative' || rating <= 2.0) {
            // Trigger Dispute Suggestions
            final disputeMsg = 'Assalam-o-Alaikum! We are sorry to hear that you had a poor experience. A dispute support agent has been notified and will contact you shortly to resolve this.';
            final disputeAction = FollowUpAction(
              type: 'dispute_suggestion',
              scheduledTime: DateTime.now().toUtc().toIso8601String(),
              payload: {
                'recipient_id': request.customerSummary.customerId,
                'channel': 'sms',
                'message': disputeMsg,
              },
            );
            generatedActions.add(disputeAction);
            await _persistFollowUpDocument(
              docId: 'followup_dispute_${request.sessionId}',
              sessionId: request.sessionId,
              bookingId: request.bookingId,
              recipientId: request.customerSummary.customerId,
              followupType: 'dispute_suggestion',
              message: disputeMsg,
              scheduledAt: DateTime.now().toUtc().toIso8601String(),
            );

            recordData['status'] = 'disputed';
            recordData['dispute_triggered'] = true;
            decisionMessage = 'Negative feedback/rating detected. Triggered dispute workflow.';
            reasoningBreakdown['dispute_triggered'] = true;

          } else {
            // Trigger Re-engagement Flow
            final stars = rating.toInt();
            final reEngageMsg = 'Assalam-o-Alaikum! Thank you for the wonderful $stars-star rating! Share BolDo with your friends and get 10% off your next booking.';
            final reEngageAction = FollowUpAction(
              type: 're_engagement_flow',
              scheduledTime: DateTime.now().toUtc().toIso8601String(),
              payload: {
                'recipient_id': request.customerSummary.customerId,
                'channel': 'sms',
                'message': reEngageMsg,
              },
            );
            generatedActions.add(reEngageAction);
            await _persistFollowUpDocument(
              docId: 'followup_re_engagement_${request.sessionId}',
              sessionId: request.sessionId,
              bookingId: request.bookingId,
              recipientId: request.customerSummary.customerId,
              followupType: 're_engagement_flow',
              message: reEngageMsg,
              scheduledAt: DateTime.now().toUtc().toIso8601String(),
            );

            recordData['status'] = 're_engaged';
            recordData['re_engagement_triggered'] = true;

            // Step 5: Update Provider Score
            try {
              final providerDoc = await _firestoreService.getDocument('providers', request.provider.providerId);
              double currentRating = 4.5;
              int currentCount = 5;
              if (providerDoc != null) {
                currentRating = (providerDoc['rating'] as num?)?.toDouble() ?? 4.5;
                currentCount = (providerDoc['rating_count'] as num?)?.toInt() ?? 5;
              }
              final newCount = currentCount + 1;
              final newRating = ((currentRating * currentCount) + rating) / newCount;
              final roundedRating = double.parse(newRating.toStringAsFixed(1));

              await _firestoreService.saveDocument('providers', request.provider.providerId, {
                'rating': roundedRating,
                'rating_count': newCount,
              });

              reasoningBreakdown['provider_rating_updated'] = true;
              reasoningBreakdown['old_rating'] = currentRating;
              reasoningBreakdown['new_rating'] = roundedRating;
            } catch (ex) {
              reasoningBreakdown['provider_rating_updated'] = false;
              reasoningBreakdown['provider_rating_error'] = ex.toString();
            }

            decisionMessage = 'Positive feedback/rating detected. Triggered re-engagement flow and updated provider score.';
            reasoningBreakdown['re_engagement_triggered'] = true;
          }
        } else {
          recordData['status'] = 'feedback_requested';
          decisionMessage = 'Service completed. Rating request generated and pending feedback.';
          reasoningBreakdown['rating_received'] = null;
        }

        recordData['reminders'] = [];

      } else if (request.bookingStatus == 'failed') {
        final retryMsg = 'We can help you find another provider.';
        final retryAction = FollowUpAction(
          type: 'retry_suggestion',
          scheduledTime: DateTime.now().toUtc().toIso8601String(),
          payload: {
            'recipient_id': request.customerSummary.customerId,
            'channel': 'sms',
            'message': retryMsg,
          },
        );
        generatedActions.add(retryAction);
        await _persistFollowUpDocument(
          docId: 'followup_retry_${request.sessionId}',
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          recipientId: request.customerSummary.customerId,
          followupType: 'retry_suggestion',
          message: retryMsg,
          scheduledAt: DateTime.now().toUtc().toIso8601String(),
        );

        recordData['status'] = 'retry_suggestion_sent';
        recordData['re_engagement_triggered'] = true;
        recordData['reminders'] = [];

        decisionMessage = 'Booking failed. Retry suggestion follow-up generated.';
        reasoningBreakdown['retry_suggestion_created'] = true;

      } else if (request.bookingStatus == 'rescheduled') {
        final rescheduledMsg = 'Your booking time has been updated.';
        final rescheduledAction = FollowUpAction(
          type: 'updated_reminder',
          scheduledTime: DateTime.now().toUtc().toIso8601String(),
          payload: {
            'recipient_id': request.customerSummary.customerId,
            'channel': 'sms',
            'message': rescheduledMsg,
          },
        );
        generatedActions.add(rescheduledAction);
        await _persistFollowUpDocument(
          docId: 'followup_reminder_${request.sessionId}',
          sessionId: request.sessionId,
          bookingId: request.bookingId,
          recipientId: request.customerSummary.customerId,
          followupType: 'updated_reminder',
          message: rescheduledMsg,
          scheduledAt: DateTime.now().toUtc().toIso8601String(),
        );

        recordData['status'] = 'updated_reminder_sent';
        recordData['reminders'] = [];

        decisionMessage = 'Booking rescheduled. Updated reminder follow-up generated.';
        reasoningBreakdown['updated_reminder_created'] = true;

      } else {
        // Unknown status fallback
        recordData['status'] = 'unknown';
        recordData['reminders'] = [];
        decisionMessage = 'Unknown booking status received. No active actions scheduled.';
      }

      // Persist follow-up record to Firestore
      recordData['actions'] = generatedActions.map((a) => a.toJson()).toList();
      await _firestoreService.saveDocument('followups', docId, recordData);

      final response = FollowUpResponse(
        status: 'success',
        followupsCreated: generatedActions.length,
        sessionId: request.sessionId,
        bookingId: request.bookingId,
        agent: 'FollowUpAgent',
        timestamp: DateTime.now().toUtc().toIso8601String(),
        orchestrationStatus: request.orchestrationMetadata.orchestrationStatus,
        isSuccess: true,
        actions: generatedActions,
        followUpRecord: recordData,
      );

      // Log Trace and update central orchestration status
      await _traceLogger.logTrace(
        traceId: traceId,
        sessionId: request.sessionId,
        userId: request.orchestrationMetadata.requestId,
        agentName: 'FollowUpAgent',
        decision: decisionMessage,
        confidence: confidence,
        orchestrationStatus: request.orchestrationMetadata.orchestrationStatus,
        reasoning: {
          ...reasoningBreakdown,
          'generated_followups_count': generatedActions.length,
        },
      );

      return response;
    } catch (e) {
      // Degraded fallback on catastrophic failure
      return _buildFallbackResponse(request, traceId, e.toString());
    }
  }

  FollowUpResponse _buildFallbackResponse(FollowUpRequest request, String traceId, String error) {
    final recordData = {
      'booking_id': request.bookingId,
      'session_id': request.sessionId,
      'status': 'degraded',
      'reminders': [],
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final response = FollowUpResponse(
      status: 'failed',
      followupsCreated: 0,
      sessionId: request.sessionId,
      bookingId: request.bookingId,
      agent: 'FollowUpAgent',
      timestamp: timestamp,
      orchestrationStatus: 'failed_degraded',
      isSuccess: false,
      error: error,
      actions: [],
      followUpRecord: recordData,
    );

    // Run async trace log
    _traceLogger.logTrace(
      traceId: traceId,
      sessionId: request.sessionId,
      userId: request.orchestrationMetadata.requestId,
      agentName: 'FollowUpAgent',
      decision: 'Catastrophic error in FollowUp Agent. Initiated degraded fallback.',
      confidence: 0.1,
      orchestrationStatus: 'failed_degraded',
      reasoning: {
        'error': error,
        'status': 'degraded',
        'generated_followups_count': 0,
      },
    );

    return response;
  }
}
