import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../booking/widgets/glass_card.dart';

class TracePreviewCard extends StatelessWidget {
  final Map<String, dynamic> traceData;

  const TracePreviewCard({
    super.key,
    required this.traceData,
  });

  String _formatTime(String timestampStr) {
    if (timestampStr.isEmpty) return '--:--:--';
    try {
      final dt = DateTime.parse(timestampStr).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {}
    return '--:--:--';
  }

  void _showFullTraceSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePrimaryText = isDark ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDark ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    final traceId = traceData['trace_id'] as String? ?? 'N/A';
    final agent = traceData['agent'] as String? ?? traceData['current_agent'] as String? ?? 'Agent';
    final decision = traceData['decision'] as String? ?? 'No decision logged';
    final confidence = (traceData['confidence'] as num?)?.toDouble() ?? 1.0;
    final timestamp = traceData['timestamp'] as String? ?? '';
    final sessionId = traceData['session_id'] as String? ?? 'N/A';
    final inputs = traceData['inputs'] as Map? ?? {};
    final breakdown = traceData['reasoning_breakdown'];

    String formattedBreakdown = '';
    if (breakdown is Map) {
      formattedBreakdown = const JsonEncoder.withIndent('  ').convert(breakdown);
    } else if (breakdown is List) {
      formattedBreakdown = breakdown.join('\n');
    } else if (breakdown != null) {
      formattedBreakdown = breakdown.toString();
    } else {
      formattedBreakdown = 'No detailed reasoning logged.';
    }

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 34),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xEC16161C) : const Color(0xF2FFFFFF),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
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
                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: themePrimaryText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Trace ID: $traceId',
                            style: TextStyle(
                              fontSize: 10,
                              color: themeSecondaryText,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Confidence Gauge / Progress
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ORCHESTRATOR CONFIDENCE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: themeSecondaryText,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${(confidence * 100).toStringAsFixed(0)}% Certainty Score',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: confidence,
                                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                        strokeWidth: 4.5,
                                      ),
                                      Text(
                                        '${(confidence * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: themePrimaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Session and Timestamp
                          Row(
                            children: [
                              _buildMetaDataChip(context, Icons.fingerprint_rounded, 'Session: $sessionId'),
                              const SizedBox(width: 8),
                              _buildMetaDataChip(context, Icons.access_time_rounded, _formatTime(timestamp)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Decision
                          Text(
                            'DECISION LOGGED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: themeSecondaryText,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1D1432).withOpacity(0.4), const Color(0xFF131A35).withOpacity(0.4)]
                                    : [const Color(0xFFF3E8FF), const Color(0xFFDBEAFE)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF8B5CF6).withOpacity(0.15) : const Color(0xFF8B5CF6).withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              decision,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: themePrimaryText,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Inputs
                          if (inputs.isNotEmpty) ...[
                            Text(
                              'INPUT PARAMETERS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: themeSecondaryText,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: inputs.entries.map((e) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${e.key}: ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: themeSecondaryText,
                                        ),
                                      ),
                                      Text(
                                        '${e.value}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: themePrimaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Reasoning Breakdown
                          Text(
                            'REASONING BREAKDOWN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: themeSecondaryText,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                              ),
                            ),
                            child: Text(
                              formattedBreakdown,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaDataChip(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeSecondaryText = isDark ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: themeSecondaryText),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: themeSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePrimaryText = isDark ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDark ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    final agent = traceData['agent'] as String? ?? traceData['current_agent'] as String? ?? 'Agent';
    final decision = traceData['decision'] as String? ?? 'No decision logged';
    final confidence = (traceData['confidence'] as num?)?.toDouble() ?? 1.0;
    final timestamp = traceData['timestamp'] as String? ?? '';
    final reasoning = traceData['reasoning_breakdown'];

    String reasoningPreview = 'No detailed breakdown.';
    if (reasoning is Map) {
      reasoningPreview = reasoning.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else if (reasoning is List) {
      reasoningPreview = reasoning.join(', ');
    } else if (reasoning != null) {
      reasoningPreview = reasoning.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: 16.0,
        radius: 20.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      agent,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: themePrimaryText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${(confidence * 100).toStringAsFixed(0)}% confidence",
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.white10),
            Text(
              decision,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: themePrimaryText,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              reasoningPreview,
              style: TextStyle(
                fontSize: 10,
                color: themeSecondaryText,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: themeSecondaryText,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFullTraceSheet(context),
                  child: const Row(
                    children: [
                      Text(
                        'View Full Trace',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
