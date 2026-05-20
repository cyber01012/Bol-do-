import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/provider.dart';
import '../theme.dart';
import 'provider_detail_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/boldo_app_bar.dart';
import '../widgets/boldo_bottom_bar.dart';
import '../../main.dart';
import '../../models/ranking_output.dart';

class ProviderListingScreen extends StatefulWidget {
  final String requestedService;
  final String? initialTopChoiceId;
  final Future<RankingOutput?>? rankingFuture;

  const ProviderListingScreen({
    super.key,
    required this.requestedService,
    this.initialTopChoiceId,
    this.rankingFuture,
  });

  @override
  State<ProviderListingScreen> createState() => _ProviderListingScreenState();
}

class _ProviderListingScreenState extends State<ProviderListingScreen> {
  bool _isRanking = false;
  String? _topChoiceId;

  @override
  void initState() {
    super.initState();
    _topChoiceId = widget.initialTopChoiceId;

    if (widget.rankingFuture != null) {
      _isRanking = true;
      widget.rankingFuture!.then((output) async {
        if (!mounted) return;
        setState(() {
          _isRanking = false;
        });

        if (output != null && output.topChoice != null) {
          final topId = output.topChoice!.providerId;
          setState(() {
            _topChoiceId = topId;
          });
          
          // Fetch full provider details and navigate
          final doc = await FirebaseFirestore.instance
              .collection('providers')
              .doc(topId)
              .get();
              
          if (doc.exists && mounted) {
            final fullProvider = Provider.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderDetailScreen(
                  provider: fullProvider,
                  isTopChoice: true,
                ),
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalizing requestedService to match seeder collection value
    // Let's determine correct Firestore field value based on common terms
    String normalizedService = 'Plumbing';
    final lowerInput = widget.requestedService.toLowerCase();
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
      extendBody: true,
      appBar: const BolDoAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .where('serviceType', isEqualTo: normalizedService)
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
            if (a.providerId == _topChoiceId) return -1;
            if (b.providerId == _topChoiceId) return 1;
            return b.rating.compareTo(a.rating);
          });

          return Column(
            children: [
              if (_isRanking)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Antigravity is ranking providers...',
                        style: TextStyle(
                          color: BolDoTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.0, _isRanking ? 0 : 16.0, 16.0, 100.0),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    final isTopChoice = provider.providerId == _topChoiceId;

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
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BolDoBottomBar(isHome: false),
    );
  }
}
