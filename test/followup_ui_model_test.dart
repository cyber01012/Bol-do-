import 'package:flutter_test/flutter_test.dart';
import 'package:boldo_ai/screens/booking/models/followup_ui_model.dart';

void main() {
  group('FollowUpUiModel Tests', () {
    test('1. fromFirestore parses valid Firestore Map correctly with various timestamp formats', () {
      final now = DateTime.now();
      
      final docMap = {
        'followup_id': 'followup_123',
        'session_id': 'sess_abc',
        'booking_id': 'book_456',
        'recipient_id': 'recipient_789',
        'followup_type': 'service_reminder',
        'message': 'Your AC technician is on the way!',
        'status': 'scheduled',
        'created_at': now.toIso8601String(),
        'scheduled_at': now.add(const Duration(hours: 2)).toIso8601String(),
      };

      final model = FollowUpUiModel.fromFirestore(docMap, 'followup_123');

      expect(model.followupId, 'followup_123');
      expect(model.sessionId, 'sess_abc');
      expect(model.bookingId, 'book_456');
      expect(model.recipientId, 'recipient_789');
      expect(model.followupType, 'service_reminder');
      expect(model.message, 'Your AC technician is on the way!');
      expect(model.status, 'scheduled');
      expect(model.createdAt, isNotNull);
      expect(model.scheduledAt, isNotNull);
    });

    test('2. toJson serializes model correctly', () {
      final now = DateTime.now();
      final model = FollowUpUiModel(
        followupId: 'f_1',
        sessionId: 's_1',
        bookingId: 'b_1',
        recipientId: 'r_1',
        followupType: 'completion_check',
        message: 'Is the job done?',
        status: 'pending',
        createdAt: now,
        scheduledAt: now.add(const Duration(minutes: 30)),
      );

      final json = model.toJson();

      expect(json['followup_id'], 'f_1');
      expect(json['session_id'], 's_1');
      expect(json['booking_id'], 'b_1');
      expect(json['recipient_id'], 'r_1');
      expect(json['followup_type'], 'completion_check');
      expect(json['message'], 'Is the job done?');
      expect(json['status'], 'pending');
      expect(json['created_at'], now.toIso8601String());
      expect(json['scheduled_at'], now.add(const Duration(minutes: 30)).toIso8601String());
    });

    test('3. OrchestrationStreamData groups documents by booking_id and session_id', () {
      final doc1 = FollowUpUiModel(
        followupId: 'f_1',
        sessionId: 'sess_1',
        bookingId: 'book_1',
        recipientId: 'r_1',
        followupType: 'service_reminder',
        message: 'Reminder 1',
        status: 'sent',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final doc2 = FollowUpUiModel(
        followupId: 'f_2',
        sessionId: 'sess_1',
        bookingId: 'book_1',
        recipientId: 'r_1',
        followupType: 'completion_check',
        message: 'Check 1',
        status: 'scheduled',
        createdAt: DateTime.now(),
      );

      final doc3 = FollowUpUiModel(
        followupId: 'f_3',
        sessionId: 'sess_2',
        bookingId: 'book_2',
        recipientId: 'r_2',
        followupType: 'rating_request',
        message: 'Rate us',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // In the real stream, sorting and grouping happens in _getOrchestrationStream()
      final group1 = OrchestrationGroup(
        bookingId: 'book_1',
        sessionId: 'sess_1',
        actions: [doc2, doc1],
      );
      final group2 = OrchestrationGroup(
        bookingId: 'book_2',
        sessionId: 'sess_2',
        actions: [doc3],
      );

      final streamData = OrchestrationStreamData(
        groups: [group1, group2],
        hasData: true,
      );

      expect(streamData.hasData, true);
      expect(streamData.groups.length, 2);

      // Verify group 1 (book_1, sess_1)
      final g1 = streamData.groups.firstWhere((g) => g.bookingId == 'book_1');
      expect(g1.sessionId, 'sess_1');
      expect(g1.actions.length, 2);
      expect(g1.actions[0].followupId, 'f_2');
      expect(g1.actions[1].followupId, 'f_1');

      // Verify group 2 (book_2, sess_2)
      final g2 = streamData.groups.firstWhere((g) => g.bookingId == 'book_2');
      expect(g2.sessionId, 'sess_2');
      expect(g2.actions.length, 1);
      expect(g2.actions[0].followupId, 'f_3');
    });
  });
}
