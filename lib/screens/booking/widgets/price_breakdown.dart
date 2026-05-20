import 'package:flutter/material.dart';
import 'glass_card.dart';

class PriceBreakdown extends StatelessWidget {
  final bool isDarkMode;

  const PriceBreakdown({
    super.key,
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
                child: const Text(
                  '95% match confidence',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow('Base Service Rate', 'Rs.500', themePrimaryText, themeSecondaryText),
          const SizedBox(height: 10),
          _buildBreakdownRow('Distance Fee', 'Rs.100', themePrimaryText, themeSecondaryText),
          const SizedBox(height: 10),
          _buildBreakdownRow('Urgency Calibration', 'Rs.150', themePrimaryText, themeSecondaryText),
          const Divider(height: 24, thickness: 0.7),
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
              const Text(
                'Rs.750',
                style: TextStyle(
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
