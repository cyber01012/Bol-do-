import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intent_output.dart';
import '../models/provider.dart';
import '../models/log_entry.dart';
import '../services/logging_service.dart';

class DiscoveryAgent {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Provider>> discoverProviders(IntentOutput intent) async {
    String dbService = intent.serviceType;
    switch (intent.serviceType.toLowerCase()) {
      case 'plumber':
        dbService = 'Plumbing';
        break;
      case 'electrician':
        dbService = 'Electrical';
        break;
      case 'painter':
        dbService = 'Painting';
        break;
      case 'carpenter':
        dbService = 'Carpentry';
        break;
      case 'cleaner':
        dbService = 'Cleaning';
        break;
      case 'ac_technician':
      case 'appliance_repair':
        dbService = 'AC Repair';
        break;
    }

    await LoggingService.log(LogEntry(
      agent: 'Discovery Agent',
      workflowStage: 'provider-discovery',
      decision: 'Searching for providers',
      reasoning: 'Looking for $dbService in ${intent.location}',
      actionTaken: 'firestore_query',
      severity: 'info',
      timestamp: DateTime.now(),
    ));

    try {
      final snapshot = await _firestore
          .collection('providers')
          .where('service', isEqualTo: dbService)
          .get();

      List<Provider> results = snapshot.docs
          .map((doc) => Provider.fromJson(doc.data(), doc.id))
          .where((p) {
            if (!p.availability) return false;
            if (intent.location.isNotEmpty && intent.location.toLowerCase() != 'unknown') {
              // Simulating "location_area CONTAINS {location}"
              return p.locationArea.toLowerCase().contains(intent.location.toLowerCase()) || 
                     intent.location.toLowerCase().contains(p.locationArea.toLowerCase());
            }
            return true;
          }).toList();

      if (results.isEmpty) {
        await LoggingService.log(LogEntry(
          agent: 'Discovery Agent',
          workflowStage: 'provider-discovery',
          decision: 'No providers found',
          reasoning: 'Firestore returned 0 matching providers for $dbService',
          actionTaken: 'suggest_nearby_locations',
          severity: 'warning',
          timestamp: DateTime.now(),
          finalOutcomes: 'Zero results',
        ));
      } else {
        await LoggingService.log(LogEntry(
          agent: 'Discovery Agent',
          workflowStage: 'provider-discovery',
          decision: 'Found ${results.length} providers',
          reasoning: 'Providers successfully matched criteria',
          actionTaken: 'return_providers',
          severity: 'info',
          timestamp: DateTime.now(),
        ));
      }

      return results;
    } catch (e) {
      await LoggingService.log(LogEntry(
        agent: 'Discovery Agent',
        workflowStage: 'provider-discovery',
        decision: 'Error querying providers',
        reasoning: e.toString(),
        actionTaken: 'error_handling',
        severity: 'critical',
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }
}
