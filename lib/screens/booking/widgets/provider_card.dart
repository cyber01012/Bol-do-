import 'package:flutter/material.dart';
import 'glass_card.dart';

class ProviderCard extends StatelessWidget {
  final String providerName;
  final String serviceType;
  final double rating;
  final bool isDarkMode;

  const ProviderCard({
    super.key,
    required this.providerName,
    required this.serviceType,
    required this.rating,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);
    final themeAccentColor = isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF6366F1);

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              // Beautiful Glowing Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [themeAccentColor.withOpacity(0.2), const Color(0xFFEC4899).withOpacity(0.2)],
                  ),
                  border: Border.all(color: themeAccentColor.withOpacity(0.25), width: 1.5),
                ),
                child: Icon(Icons.engineering_rounded, color: themeAccentColor, size: 26),
              ),
              const SizedBox(width: 14),

              // Provider Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: themePrimaryText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          serviceType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: themeSecondaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeSecondaryText.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: BOOK_2026_001',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: themeAccentColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: themePrimaryText,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          
          const Divider(height: 24, thickness: 0.7),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ETA & Status
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: themeAccentColor),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arriving in 15 mins',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: themePrimaryText,
                        ),
                      ),
                      Text(
                        'Status: Confirmed',
                        style: TextStyle(
                          fontSize: 10,
                          color: themeSecondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Glass Quick Action Icons
              Row(
                children: [
                  _buildQuickAction(Icons.call_rounded, const Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  _buildQuickAction(Icons.chat_bubble_outline_rounded, const Color(0xFF8B5CF6)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
