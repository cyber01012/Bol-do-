import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../booking/widgets/glass_card.dart';

class OrchestrationStreamTile extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final String sessionId;

  const OrchestrationStreamTile({
    super.key,
    required this.sessionData,
    required this.sessionId,
  });

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '--:--:--';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate().toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
    if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp).toLocal();
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    return '--:--:--';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePrimaryText = isDark ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDark ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    final pipelineStatus = sessionData['pipeline_status'] as String? ?? 'pending';
    final completedMap = Map<String, dynamic>.from(sessionData['completed_agents'] as Map? ?? {});
    final createdAt = sessionData['created_at'];
    final orchestrationStatus = sessionData['orchestration_status'] as String? ?? 'running';

    // Map pipeline steps to status
    // Steps: Intent, Ranking, Pricing, Booking, Notification, Follow-up, Dispute
    final steps = [
      _PipelineStep('Intent', _getStepStatus('Intent', pipelineStatus, completedMap)),
      _PipelineStep('Ranking', _getStepStatus('Ranking', pipelineStatus, completedMap)),
      _PipelineStep('Pricing', _getStepStatus('Pricing', pipelineStatus, completedMap)),
      _PipelineStep('Booking', _getStepStatus('Booking', pipelineStatus, completedMap)),
      _PipelineStep('Notification', _getStepStatus('Notification', pipelineStatus, completedMap)),
      _PipelineStep('Follow-up', _getStepStatus('FollowUp', pipelineStatus, completedMap)),
      _PipelineStep('Dispute', _getStepStatus('Dispute', pipelineStatus, completedMap)),
    ];

    Color statusColor = const Color(0xFF8B5CF6); // Purple
    if (pipelineStatus.contains('failed') || orchestrationStatus == 'failed') {
      statusColor = const Color(0xFFEF4444);
    } else if (pipelineStatus == 'completed' || completedMap['FollowUpAgent'] == true) {
      statusColor = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: 16,
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.lan_outlined,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sessionId,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: themePrimaryText,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    pipelineStatus.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatTime(createdAt)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: themeSecondaryText,
                  ),
                ),
                Text(
                  'Orchestration: $orchestrationStatus',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: themeSecondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 12),
            Text(
              'ORCHESTRATION PIPELINE STAGES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: themeSecondaryText.withOpacity(0.7),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: steps.map((step) => _buildStepChip(context, step)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  _StepState _getStepStatus(String step, String pipelineStatus, Map<String, dynamic> completedMap) {
    // Intent / Ranking are matched on start
    if (step == 'Intent' || step == 'Ranking') {
      return _StepState.completed;
    }

    if (step == 'Pricing') {
      if (completedMap['PricingAgent'] == true) return _StepState.completed;
      if (pipelineStatus == 'pricing' || pipelineStatus == 'running_pricing') return _StepState.active;
      if (completedMap.isNotEmpty) return _StepState.completed; // If other agents finished, Pricing is done
      return _StepState.pending;
    }

    if (step == 'Booking') {
      if (completedMap['BookingAgent'] == true) return _StepState.completed;
      if (pipelineStatus == 'booking' || pipelineStatus == 'running_booking') return _StepState.active;
      if (completedMap['NotificationAgent'] == true || completedMap['FollowUpAgent'] == true) return _StepState.completed;
      return _StepState.pending;
    }

    if (step == 'Notification') {
      if (completedMap['NotificationAgent'] == true) return _StepState.completed;
      if (pipelineStatus == 'notification' || pipelineStatus == 'running_notification') return _StepState.active;
      if (completedMap['FollowUpAgent'] == true) return _StepState.completed;
      return _StepState.pending;
    }

    if (step == 'Follow-up') {
      if (completedMap['FollowUpAgent'] == true) return _StepState.completed;
      if (pipelineStatus == 'followup' || pipelineStatus == 'running_followup') return _StepState.active;
      return _StepState.pending;
    }

    if (step == 'Dispute') {
      // Checked if pipeline_status is dispute or session has dispute
      if (pipelineStatus == 'dispute' || pipelineStatus == 'escalated') return _StepState.active;
      if (pipelineStatus == 'resolved_dispute') return _StepState.completed;
      return _StepState.pending;
    }

    return _StepState.pending;
  }

  Widget _buildStepChip(BuildContext context, _PipelineStep step) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color chipColor;
    Color textColor;
    IconData icon;
    bool isPulse = false;

    switch (step.state) {
      case _StepState.completed:
        chipColor = isDark ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFD1FAE5);
        textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
        icon = Icons.check_circle_outline_rounded;
        break;
      case _StepState.active:
        chipColor = isDark ? const Color(0xFF8B5CF6).withOpacity(0.15) : const Color(0xFFEDE9FE);
        textColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF5B21B6);
        icon = Icons.sync_rounded;
        isPulse = true;
        break;
      case _StepState.pending:
      default:
        chipColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
        textColor = isDark ? Colors.white38 : Colors.black38;
        icon = Icons.circle_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.state == _StepState.active
              ? const Color(0xFF8B5CF6).withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPulse)
            _PulsingIcon(icon: icon, color: textColor)
          else
            Icon(
              icon,
              size: 10,
              color: textColor,
            ),
          const SizedBox(width: 4),
          Text(
            step.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { completed, active, pending }

class _PipelineStep {
  final String name;
  final _StepState state;

  _PipelineStep(this.name, this.state);
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        widget.icon,
        size: 10,
        color: widget.color,
      ),
    );
  }
}
