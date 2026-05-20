import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/provider.dart';
import '../theme.dart';
import 'provider_detail_screen.dart';
import '../widgets/glass_card.dart';

class ProviderListingScreen extends StatelessWidget {
  final String requestedService;
  final String initialTopChoiceId;

  const ProviderListingScreen({
    super.key,
    required this.requestedService,
    required this.initialTopChoiceId,
  });

  @override
  Widget build(BuildContext context) {
    // Normalizing requestedService to match seeder collection value
    // Let's determine correct Firestore field value based on common terms
    String normalizedService = 'Plumbing';
    final lowerInput = requestedService.toLowerCase();
    if (lowerInput.contains('electrician') || lowerInput.contains('bijli')) {
      normalizedService = 'Electrical';
    } else if (lowerInput.contains('ac') || lowerInput.contains('technician')) {
      normalizedService = 'AC Repair';
    } else if (lowerInput.contains('cleaner') || lowerInput.contains('safai')) {
      normalizedService = 'Cleaning';
    } else if (lowerInput.contains('paint') || lowerInput.contains('painter')) {
      normalizedService = 'Painting';
    } else if (lowerInput.contains('carpenter') || lowerInput.contains('wood')) {
      normalizedService = 'Carpentry';
    } else if (lowerInput.contains('handyman')) {
      normalizedService = 'General';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$normalizedService Providers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .where('service', isEqualTo: normalizedService)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No matching providers found in your location.',
                style: TextStyle(color: BolDoTheme.textSecondary),
              ),
            );
          }

          final providers = snapshot.data!.docs.map((doc) {
            return Provider.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          // Sort so the top choice is first
          providers.sort((a, b) {
            if (a.providerId == initialTopChoiceId) return -1;
            if (b.providerId == initialTopChoiceId) return 1;
            return b.rating.compareTo(a.rating);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final isTopChoice = provider.providerId == initialTopChoiceId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderDetailScreen(
                          provider: provider,
                          isTopChoice: isTopChoice,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isTopChoice
                          ? [
                              const BoxShadow(
                                color: BolDoTheme.primary,
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar / Icon
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: isTopChoice
                                  ? BolDoTheme.primary.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTopChoice ? Icons.star : Icons.person,
                              color: isTopChoice ? BolDoTheme.primary : Colors.white70,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      provider.name,
                                      style: const TextStyle(
                                        color: BolDoTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isTopChoice) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: BolDoTheme.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'AI TOP CHOICE',
                                          style: TextStyle(
                                            color: BolDoTheme.background,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Area: ${provider.locationArea}',
                                  style: const TextStyle(
                                    color: BolDoTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${provider.rating}',
                                      style: const TextStyle(
                                        color: BolDoTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.verified, color: BolDoTheme.secondary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reliability: ${provider.reliabilityScore}%',
                                      style: const TextStyle(
                                        color: BolDoTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white30),
                        ],
                      ),
                    ),
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
