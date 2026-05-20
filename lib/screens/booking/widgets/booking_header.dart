import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingHeader extends StatelessWidget {
  final bool isDarkMode;
  final bool isBookingComplete;
  final bool isOrchestrating;
  final Animation<double> pulseAnimation;
  final VoidCallback onThemeToggle;
  final VoidCallback onRetriggerPipeline;
  final VoidCallback onNotificationTap;
  final VoidCallback onFollowUpTap;
  final VoidCallback onDebugTap;

  const BookingHeader({
    super.key,
    required this.isDarkMode,
    required this.isBookingComplete,
    required this.isOrchestrating,
    required this.pulseAnimation,
    required this.onThemeToggle,
    required this.onRetriggerPipeline,
    required this.onNotificationTap,
    required this.onFollowUpTap,
    required this.onDebugTap,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, Customer! 👋',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: themeSecondaryText,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your booking is secure ✨',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: themePrimaryText,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
            
            Row(
              children: [
                // Notification Bell
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      onNotificationTap();
                      HapticFeedback.selectionClick();
                    },
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: isDarkMode ? Colors.white : const Color(0xFF1E2025),
                          size: 20,
                        ),
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Follow-up screen button
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      onFollowUpTap();
                      HapticFeedback.selectionClick();
                    },
                    tooltip: 'Follow-up Automation',
                    icon: Icon(
                      Icons.repeat_rounded,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E2025),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Debug Observability screen button
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      onDebugTap();
                      HapticFeedback.selectionClick();
                    },
                    tooltip: 'Orchestration Observability',
                    icon: Icon(
                      Icons.analytics_outlined,
                      color: isDarkMode ? const Color(0xFFA78BFA) : const Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Theme toggler
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      onThemeToggle();
                      HapticFeedback.selectionClick();
                    },
                    icon: Icon(
                      isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                      color: isDarkMode ? Colors.amber : const Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Live Status Chip
        Row(
          children: [
            GestureDetector(
              onTap: onRetriggerPipeline,
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  final double borderOpacity = pulseAnimation.value * 0.4 + 0.2;
                  
                  Color statusColor;
                  String statusText;
                  
                  if (isBookingComplete) {
                    statusColor = const Color(0xFF10B981);
                    statusText = 'AI BOOKING FULLY HANDLED';
                  } else if (isOrchestrating) {
                    statusColor = const Color(0xFF8B5CF6);
                    statusText = 'RUNNING AUTOMATED DISPATCH...';
                  } else {
                    statusColor = Colors.amber;
                    statusText = 'TOUCH TO RETRIGGER AI PIPELINE';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withOpacity(borderOpacity),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}
