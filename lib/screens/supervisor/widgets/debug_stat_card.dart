import 'package:flutter/material.dart';
import '../../booking/widgets/glass_card.dart';

class DebugStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const DebugStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 140,
      child: GlassCard(
        padding: 14.0,
        radius: 20.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isDark)
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),

                  if (isLoading)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  isLoading
                      ? Text(
                          '...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E2025),
                          ),
                        )
                      : TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: value.toDouble(),
                          ),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) {
                            return Text(
                              val.toInt().toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E2025),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      height: 1.3,
                      color: isDark
                          ? const Color(0xFF9EA3B0)
                          : const Color(0xFF6B7280),
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