import 'package:flutter/material.dart';
import '../../models/provider.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class ProviderDetailScreen extends StatelessWidget {
  final Provider provider;
  final bool isTopChoice;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
    required this.isTopChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card with Avatar
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: isTopChoice
                          ? BolDoTheme.primary.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTopChoice ? Icons.star : Icons.person,
                      color: isTopChoice ? BolDoTheme.primary : Colors.white70,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BolDoTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.serviceType,
                    style: const TextStyle(
                      fontSize: 16,
                      color: BolDoTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.rating}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BolDoTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        provider.locationArea,
                        style: const TextStyle(
                          fontSize: 16,
                          color: BolDoTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance & Reliability Factors
            const Text(
              'PERFORMANCE FACTORS',
              style: TextStyle(
                color: BolDoTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFactorRow(
                    icon: Icons.verified_user,
                    title: 'Reliability Index',
                    value: '${provider.reliabilityScore}%',
                    progress: provider.reliabilityScore / 100.0,
                    color: Colors.greenAccent,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFactorRow(
                    icon: Icons.cancel_outlined,
                    title: 'Cancellation Rate',
                    value: '${provider.cancellationRate}%',
                    progress: provider.cancellationRate / 100.0,
                    color: Colors.redAccent,
                    inverseProgress: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Specialization Matches
            const Text(
              'SPECIALIZATIONS',
              style: TextStyle(
                color: BolDoTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.specializations.isEmpty
                    ? [
                        Chip(
                          label: const Text('Standard Service'),
                          backgroundColor: Colors.white.withOpacity(0.05),
                        )
                      ]
                    : provider.specializations.map((spec) {
                        return Chip(
                          label: Text(spec),
                          backgroundColor: BolDoTheme.primary.withOpacity(0.1),
                          side: const BorderSide(color: Colors.white10),
                          labelStyle: const TextStyle(color: BolDoTheme.primary),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Booking Action Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking request initiated for ${provider.name}!'),
                    backgroundColor: BolDoTheme.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BolDoTheme.primary,
                foregroundColor: BolDoTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: BolDoTheme.primary.withOpacity(0.4),
              ),
              child: const Text(
                'BOOK SERVICE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorRow({
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
    bool inverseProgress = false,
  }) {
    final progressVal = inverseProgress ? (1.0 - progress) : progress;
    return Row(
      children: [
        Icon(icon, color: BolDoTheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: BolDoTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressVal.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
