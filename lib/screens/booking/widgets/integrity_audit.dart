import 'package:flutter/material.dart';
import 'glass_card.dart';

class IntegrityAudit extends StatelessWidget {
  final bool isDarkMode;
  final bool syncComplete;

  const IntegrityAudit({
    super.key,
    required this.isDarkMode,
    required this.syncComplete,
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
                'SERVICE INTEGRITY AUDIT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: themeSecondaryText,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: syncComplete
                      ? const Color(0xFF10B981).withOpacity(0.08)
                      : const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: syncComplete ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF3B82F6).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      syncComplete ? Icons.security_rounded : Icons.sync_rounded,
                      size: 11,
                      color: syncComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      syncComplete ? 'Protected State' : 'Verifying state...',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: syncComplete ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          
          Text(
            'This booking is automated by BolDo\'s orchestrator system. Core parameters are locked, encrypted, and synced with secure databases to prevent modification.',
            style: TextStyle(
              fontSize: 12,
              color: themePrimaryText.withOpacity(0.85),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildIntegrityBadge('Cloud Secured', Icons.cloud_done_rounded, const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _buildIntegrityBadge('Audit Trail Armed', Icons.shield_outlined, const Color(0xFF8B5CF6)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIntegrityBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
