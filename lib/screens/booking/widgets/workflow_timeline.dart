import 'package:flutter/material.dart';
import 'glass_card.dart';

class WorkflowTimeline extends StatelessWidget {
  final bool isDarkMode;
  final int activeStep;
  final String timeIntent;
  final String timeRanked;
  final String timePricing;
  final String timeBooking;
  final String timeNotification;
  final String timeFollowup;
  final VoidCallback? onFollowUpTap;

  const WorkflowTimeline({
    super.key,
    required this.isDarkMode,
    required this.activeStep,
    required this.timeIntent,
    required this.timeRanked,
    required this.timePricing,
    required this.timeBooking,
    required this.timeNotification,
    required this.timeFollowup,
    this.onFollowUpTap,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUTOMATED DISPATCH TRAIL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: themeSecondaryText,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Timeline steps
          _buildTimelineStep(
            'Intent Decoded',
            'Categorized task: Sparky electrical repair.',
            timeIntent,
            activeStep >= 1,
            activeStep == 0,
            Icons.psychology_outlined,
            'Success',
            const Color(0xFF8B5CF6),
            themePrimaryText,
            themeSecondaryText,
          ),
          _buildTimelineDivider(activeStep >= 2),
          _buildTimelineStep(
            'Expert Matched',
            'Matched with top rated specialist nearby.',
            timeRanked,
            activeStep >= 2,
            activeStep == 1,
            Icons.done_all_rounded,
            'Matched',
            const Color(0xFF3B82F6),
            themePrimaryText,
            themeSecondaryText,
          ),
          _buildTimelineDivider(activeStep >= 3),
          _buildTimelineStep(
            'Pricing Calibrated',
            'Optimized distance and priority surcharges.',
            timePricing,
            activeStep >= 3,
            activeStep == 2,
            Icons.speed_rounded,
            'Calibrated',
            const Color(0xFF10B981),
            themePrimaryText,
            themeSecondaryText,
          ),
          _buildTimelineDivider(activeStep >= 4),
          _buildTimelineStep(
            'Secure Booking Locked',
            'Booking schedule successfully registered.',
            timeBooking,
            activeStep >= 4,
            activeStep == 3,
            Icons.lock_outline_rounded,
            'Secured',
            const Color(0xFFEC4899),
            themePrimaryText,
            themeSecondaryText,
          ),
          _buildTimelineDivider(activeStep >= 5),
          _buildTimelineStep(
            'User Dispatched',
            'Tracking alerts sent to your mobile.',
            timeNotification,
            activeStep >= 5,
            activeStep == 4,
            Icons.chat_bubble_outline_rounded,
            'Notified',
            const Color(0xFF06B6D4),
            themePrimaryText,
            themeSecondaryText,
          ),
          _buildTimelineDivider(activeStep >= 6),
          GestureDetector(
            onTap: onFollowUpTap,
            child: _buildTimelineStep(
              'Satisfaction Armed ↗',
              'Scheduled follow-up request to audit job quality.',
              timeFollowup,
              activeStep >= 6,
              activeStep == 5,
              Icons.favorite_border_rounded,
              'Armed',
              Colors.amber,
              themePrimaryText,
              themeSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider(bool active) {
    return Container(
      width: 1.5,
      height: 20,
      margin: const EdgeInsets.only(left: 17),
      color: active
          ? const Color(0xFF10B981)
          : (isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    String time,
    bool isCompleted,
    bool isPending,
    IconData icon,
    String chipLabel,
    Color stepColor,
    Color primary,
    Color secondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981).withOpacity(0.08)
                : isPending
                    ? stepColor.withOpacity(0.08)
                    : (isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981).withOpacity(0.4)
                  : isPending
                      ? stepColor.withOpacity(0.4)
                      : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isPending
                      ? stepColor
                      : secondary.withOpacity(0.4),
            ),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? primary : primary.withOpacity(0.65),
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: secondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: secondary,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stepColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: stepColor.withOpacity(0.12)),
                      ),
                      child: Text(
                        chipLabel,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: stepColor,
                        ),
                      ),
                    )
                  else if (isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withOpacity(0.12)),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
