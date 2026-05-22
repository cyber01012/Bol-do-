import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/ranking_logs_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../main.dart';

class BolDoBottomBar extends StatelessWidget {
  final bool isHome;
  
  const BolDoBottomBar({super.key, required this.isHome});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDarkMode = currentMode == ThemeMode.dark;
        final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);
        final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? const Color(0xE6121216) 
                    : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (!isHome)
                      _buildBottomTab(
                        context: context,
                        icon: Icons.home_rounded,
                        label: "Home",
                        color: const Color(0xFF8B5CF6),
                        themeSecondaryText: themeSecondaryText,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                    _buildBottomTab(
                      context: context,
                      icon: Icons.support_agent_rounded,
                      label: "Supervisor",
                      color: const Color(0xFFEC4899),
                      themeSecondaryText: themeSecondaryText,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RankingLogsScreen()),
                        );
                      },
                    ),
                    _buildBottomTab(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      label: "Profile",
                      color: const Color(0xFF3B82F6),
                      themeSecondaryText: themeSecondaryText,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color themeSecondaryText,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: themeSecondaryText,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: themeSecondaryText.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
