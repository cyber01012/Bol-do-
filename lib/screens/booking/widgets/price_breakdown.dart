import 'package:flutter/material.dart';
import 'glass_card.dart';

class PriceBreakdown extends StatelessWidget {
  final double totalPrice;
  final double confidence;
  final Map<String, dynamic> breakdown;
  final bool isDarkMode;

  const PriceBreakdown({
    super.key,
    required this.totalPrice,
    required this.confidence,
    required this.breakdown,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: themePrimaryText,
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                ),
                child: Text(
                  '${(confidence * 100).toStringAsFixed(0)}% match confidence',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildBreakdownRow(e.key, 'Rs.${e.value}', themePrimaryText, themeSecondaryText),
            );
          }),
          const Divider(height: 14, thickness: 0.7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Final Price',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: themePrimaryText,
                ),
              ),
              Text(
                'Rs.${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String val, Color primary, Color secondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: secondary),
        ),
        Text(
          val,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
        ),
      ],
    );
  }
}
