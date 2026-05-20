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
          .where('serviceType', isEqualTo: dbService)
          .get();

      List<Provider> results = snapshot.docs
          .map((doc) => Provider.fromJson(doc.data(), doc.id))
          .where((p) {
            if (!p.availability) return false;
            if (intent.location.isNotEmpty && intent.location.toLowerCase() != 'unknown') {
              // Simulating "location CONTAINS {location}"
              return p.location.toLowerCase().contains(intent.location.toLowerCase()) || 
                     intent.location.toLowerCase().contains(p.location.toLowerCase());
            }
            return true;
          }).toList();

      if (results.isEmpty) {
        final allOfThisService = snapshot.docs
            .map((doc) => Provider.fromJson(doc.data(), doc.id))
            .toList();
        
        final otherLocations = allOfThisService
            .where((p) => p.availability)
            .map((p) => p.location)
            .toSet()
            .join(', ');

        String reasoningMsg = 'No available $dbService providers are registered in "${intent.location}".';
        if (otherLocations.isNotEmpty) {
          reasoningMsg += ' Active $dbService providers were found in other areas ($otherLocations), but these do not match the requested nearby location filter.';
        } else {
          reasoningMsg += ' There are no active $dbService providers currently online in any area.';
        }

        await LoggingService.log(LogEntry(
          agent: 'Discovery Agent',
          workflowStage: 'provider-discovery',
          decision: 'No matching providers found in "${intent.location}"',
          reasoning: reasoningMsg,
          actionTaken: 'filter_by_location_failed',
          severity: 'warning',
          timestamp: DateTime.now(),
          finalOutcomes: 'Returned 0 matching nearby providers.',
        ));
      } else {
        final providerPrices = results.map((p) => '${p.name} (Rs ${p.basePrice})').join(', ');
        await LoggingService.log(LogEntry(
          agent: 'Discovery Agent',
          workflowStage: 'provider-discovery',
          decision: 'Found ${results.length} active providers: $providerPrices',
          reasoning: 'Providers successfully matched $dbService in ${intent.location} with pricing mentioned.',
          actionTaken: 'return_providers',
          severity: 'info',
          timestamp: DateTime.now(),
          finalOutcomes: 'Discovered: ' + results.map((p) => '${p.name} - Price: Rs ${p.basePrice}').join(' | '),
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
