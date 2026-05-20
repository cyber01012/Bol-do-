import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class TraceSheet extends StatelessWidget {
  final bool isDarkMode;

  const TraceSheet({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 30),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xEC16161C) : const Color(0xF2FFFFFF),
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Orchestrator Decisions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: themePrimaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTraceLogItem('Intent Decoding', 'Understands your natural language request, extracts core task parameters, and evaluates urgency constraints.', '100% confidence'),
                      _buildTraceLogItem('Provider Matching', 'Analyzes real-time calendar slots, distance metrics, and past customer ratings to select the absolute best matching provider.', '95% match score'),
                      _buildTraceLogItem('Pricing Calibration', 'Calculates transparent pricing including distance calculations and priority surcharges automatically.', 'Fair rate verified'),
                      _buildTraceLogItem('Booking Guarantee', 'Registers schedule blocks securely and utilizes unique idempotency tokens to ensure no schedule overlapping occurs.', 'Lock success'),
                      _buildTraceLogItem('Alert Dispatcher', 'Prepares custom SMS and push alert templates to provide tracking details directly.', 'Queue: SENT'),
                      _buildTraceLogItem('Satisfaction Audit', 'Arms an automatic audit trigger to check on service quality shortly after completion.', 'Armed'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraceLogItem(String agent, String log, String result) {
    final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                agent,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log,
            style: TextStyle(
              fontSize: 12,
              color: themeSecondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
