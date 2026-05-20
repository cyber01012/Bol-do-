import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DisputeSheet extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onSubmit;

  const DisputeSheet({
    super.key,
    required this.isDarkMode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final themeSecondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            top: 20,
            left: 24,
            right: 24,
          ),
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
                    'Raise Dispute',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E2025),
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
              const SizedBox(height: 12),
              Text(
                'This locks the session and requests an automated safety audit by the Dispute Agent.',
                style: TextStyle(
                  fontSize: 12,
                  color: themeSecondaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter reason for dispute...',
                  hintStyle: TextStyle(color: themeSecondaryText.withOpacity(0.6), fontSize: 13),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSubmit();
                    HapticFeedback.heavyImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Dispute Audit',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
