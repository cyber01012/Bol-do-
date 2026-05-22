import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../../main.dart';
import '../../screens/booking/notification_screen.dart';

class BolDoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BolDoAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDarkMode = currentMode == ThemeMode.dark;
        final themePrimaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);

        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 12.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.12),
              radius: 18,
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 16),
            ),
          ),
          leadingWidth: 56,
          title: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              'BolDo AI',
              style: GoogleFonts.poppins(
                color: themePrimaryText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.6,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: IconButton(
                icon: const Icon(Icons.history_rounded, color: BolDoTheme.textSecondary, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Follow-up logs coming soon.')),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: BolDoTheme.textSecondary, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => NotificationScreen(
                            isDarkMode: isDarkMode,
                            sessionId: 'sess_global_001',
                            bookingId: 'global_notifs',
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEC4899),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 12.0),
              child: IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded,
                  color: isDarkMode ? Colors.amber : const Color(0xFF8B5CF6),
                  size: 20,
                ),
                onPressed: () {
                  themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
