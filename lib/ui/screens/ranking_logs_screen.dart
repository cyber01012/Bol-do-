import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class RankingLogsScreen extends StatelessWidget {
  const RankingLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agent Logs Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workflow_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No logs stored in Firestore yet.',
                style: TextStyle(color: BolDoTheme.textSecondary),
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final logData = logs[index].data() as Map<String, dynamic>;
              final agent = logData['agent'] ?? 'System';
              final stage = logData['workflow_stage'] ?? 'unknown';
              final decision = logData['decision'] ?? '';
              final reasoning = logData['reasoning'] ?? '';
              final action = logData['action_taken'] ?? '';
              final severity = logData['severity'] ?? 'info';
              final finalOutcomes = logData['final_outcomes'] ?? '';
              
              DateTime? timestamp;
              if (logData['timestamp'] != null) {
                if (logData['timestamp'] is Timestamp) {
                  timestamp = (logData['timestamp'] as Timestamp).toDate();
                } else if (logData['timestamp'] is String) {
                  timestamp = DateTime.tryParse(logData['timestamp']);
                }
              }

              String formattedTime = '';
              if (timestamp != null) {
                formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
              }

              Color severityColor = Colors.white30;
              Color badgeColor = Colors.grey;
              if (severity == 'warning') {
                severityColor = Colors.orangeAccent.withOpacity(0.2);
                badgeColor = Colors.orangeAccent;
              } else if (severity == 'critical') {
                severityColor = Colors.redAccent.withOpacity(0.2);
                badgeColor = Colors.redAccent;
              } else if (severity == 'info') {
                severityColor = BolDoTheme.primary.withOpacity(0.1);
                badgeColor = BolDoTheme.primary;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Log Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$agent - $stage',
                              style: const TextStyle(
                                color: BolDoTheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Metadata / Time
                      if (formattedTime.isNotEmpty) ...[
                        Text(
                          'Logged at: $formattedTime',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Main Decision / Text
                      Text(
                        decision,
                        style: const TextStyle(
                          color: BolDoTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Reasoning Block
                      if (reasoning.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Text(
                            'Reasoning: $reasoning',
                            style: const TextStyle(
                              color: BolDoTheme.textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Outcomes Block
                      if (finalOutcomes.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.outbox, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Outcome: $finalOutcomes',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Action Taken
                      Row(
                        children: [
                          const Icon(Icons.settings, color: Colors.white30, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Action Taken: $action',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
