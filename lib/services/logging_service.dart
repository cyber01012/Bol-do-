import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log_entry.dart';

class LoggingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> log(LogEntry entry) async {
    try {
      await _firestore.collection('workflow_logs').add(entry.toJson());
      print('[LoggingService] Log saved: ${entry.actionTaken}');
    } catch (e) {
      print('[LoggingService] Failed to save log: $e');
    }
  }
}
