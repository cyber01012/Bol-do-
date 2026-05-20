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
        // Fallback: Get all available providers of this service type regardless of location
        List<Provider> allAvailable = snapshot.docs
            .map((doc) => Provider.fromJson(doc.data(), doc.id))
            .where((p) => p.availability)
            .toList();

        if (allAvailable.isNotEmpty) {
          results = allAvailable;
          final providerPrices = results.map((p) => '${p.name} (Rs ${p.basePrice} in ${p.location})').join(', ');
          await LoggingService.log(LogEntry(
            agent: 'Discovery Agent',
            workflowStage: 'provider-discovery',
            decision: 'Fell back to other locations: $providerPrices',
            reasoning: 'No providers found in exact location "${intent.location}". Suggested available alternatives in other areas.',
            actionTaken: 'suggest_nearby_locations',
            severity: 'info',
            timestamp: DateTime.now(),
            finalOutcomes: 'Suggested fallback providers from nearby locations.',
          ));
        } else {
          await LoggingService.log(LogEntry(
            agent: 'Discovery Agent',
            workflowStage: 'provider-discovery',
            decision: 'No providers found',
            reasoning: 'Firestore returned 0 matching providers for $dbService anywhere',
            actionTaken: 'suggest_nearby_locations',
            severity: 'warning',
            timestamp: DateTime.now(),
            finalOutcomes: 'Zero results',
          ));
        }
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
