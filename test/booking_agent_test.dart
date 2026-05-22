// ==============================
// SUPERVISOR AGENT PIPELINE FIX
// Replace your booking pipeline section
// inside supervisor_agent_service.dart
// ==============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boldo_ai/agents/booking_agent/booking_model.dart'
    as booking;

// AFTER pricingResponse success:

await FirebaseFirestore.instance
    .collection('orchestration_sessions')
    .doc(sessionId)
    .set({
  'session_id': sessionId,
  'pipeline_status': 'pricing_completed',

  'completed_agents': {
    'PricingAgent': true,
  },

  'last_updated': DateTime.now()
      .toUtc()
      .toIso8601String(),
}, SetOptions(merge: true));


// ==============================
// CREATE VALID BOOKING REQUEST
// ==============================

final bookingRequest = booking.BookingRequest(
  requestId: requestId,
  sessionId: sessionId,

  orchestrationStatus: 'success',

  selectedProvider: booking.SelectedProvider(
    providerId:
        rankedProvider['provider_id'] ?? 'provider_001',

    name:
        rankedProvider['name'] ?? 'Unknown Provider',

    serviceType: serviceType,
  ),

  pricingData: booking.PricingData(
    totalPricePkr:
        pricingResponse.pricingData.totalPricePkr,

    confidenceScore:
        pricingResponse.pricingData.confidenceScore,

    breakdown:
        pricingResponse.pricingData.breakdown,
  ),

  userRequest: booking.UserRequest(
    serviceType: serviceType,

    urgency: urgency ?? 'normal',

    requestedTime:
        DateTime.now().add(
      const Duration(hours: 2),
    ),
  ),

  bookingMetadata: booking.BookingMetadata(
    paymentMethod: 'cash_on_delivery',
  ),
);


// ==============================
// RUN BOOKING AGENT
// ==============================

final bookingAgent = BookingAgentService();

final bookingResponse =
    await bookingAgent.processRequest(
  bookingRequest,
);


// ==============================
// BOOKING FAILURE CHECK
// ==============================

if (bookingResponse.bookingStatus == 'failed') {
  throw Exception(
    "Booking slot processing failed.",
  );
}


// ==============================
// NOTIFICATION AGENT
// ==============================

final notificationAgent =
    NotificationAgentService();

final notificationResponse =
    await notificationAgent.processResponse(
  bookingResponse,
);


// ==============================
// FOLLOWUP AGENT
// ==============================

final followupRequest = FollowUpRequest(
  bookingId: bookingResponse.bookingId,

  sessionId: sessionId,

  bookingStatus:
      bookingResponse.bookingStatus,

  scheduledTime:
      bookingResponse.scheduledTime,

  provider:
      bookingResponse.provider,

  customerSummary:
      bookingResponse.customerSummary,

  orchestrationMetadata:
      bookingResponse.orchestrationMetadata,
);

final followupAgent =
    FollowUpAgentService();

final followupResponse =
    await followupAgent.processRequest(
  followupRequest,
);


// ==============================
// FINAL SESSION UPDATE
// ==============================

await FirebaseFirestore.instance
    .collection('orchestration_sessions')
    .doc(sessionId)
    .set({
  'pipeline_status': 'completed',

  'completed_agents': {
    'PricingAgent': true,
    'BookingAgent': true,
    'NotificationAgent': true,
    'FollowUpAgent': true,
  },

  'last_updated': DateTime.now()
      .toUtc()
      .toIso8601String(),
}, SetOptions(merge: true));

print(
  "✅ Full orchestration completed successfully",
);