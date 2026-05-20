import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/glass_card.dart';

class TraceLogsScreen extends StatefulWidget {
  final String sessionId;
  final String? bookingId;
  final bool isDarkMode;

  const TraceLogsScreen({
    super.key,
    required this.sessionId,
    this.bookingId,
    required this.isDarkMode,
  });

  @override
  State<TraceLogsScreen> createState() => _TraceLogsScreenState();
}

class _TraceLogsScreenState extends State<TraceLogsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeBg = widget.isDarkMode ? const Color(0xFF0C0C0E) : const Color(0xFFF4F6F9);
    final themePrimaryText = widget.isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = widget.isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final contentWidget = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: themePrimaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agent Action Logs',
              style: TextStyle(
                color: themePrimaryText,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            if (widget.bookingId != null && widget.bookingId!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Booking ID: ${widget.bookingId}',
                style: TextStyle(
                  color: themeSecondaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agent_traces')
            .where('session_id', isEqualTo: widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading logs: ${snapshot.error}",
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          
          // Sort docs in memory by timestamp if they are not indexed or to avoid query failures
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as String? ?? '';
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as String? ?? '';
            return aTime.compareTo(bTime);
          });

          if (sortedDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 48,
                    color: themeSecondaryText.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No logs available yet for this session",
                    style: TextStyle(color: themeSecondaryText, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final agent = data['current_agent'] as String? ?? data['agent'] as String? ?? 'Agent';
              final decision = data['decision'] as String? ?? 'No decision logged';
              final confidence = (data['confidence'] as num?)?.toDouble() ?? 1.0;
              final timestampStr = data['timestamp'] as String? ?? '';
              
              String formattedTime = '';
              try {
                if (timestampStr.isNotEmpty) {
                  final dt = DateTime.parse(timestampStr).toLocal();
                  final h = dt.hour.toString().padLeft(2, '0');
                  final m = dt.minute.toString().padLeft(2, '0');
                  final s = dt.second.toString().padLeft(2, '0');
                  formattedTime = '$h:$m:$s';
                }
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: themePrimaryText,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${(confidence * 100).toStringAsFixed(0)}% confidence",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.white24),
                      Text(
                        decision,
                        style: TextStyle(
                          fontSize: 13,
                          color: themePrimaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "TIMESTAMP",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: themeSecondaryText,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: themeSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDarkMode
              ? [const Color(0xFF060608), const Color(0xFF110C1B)]
              : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: isDesktop
            ? Center(
                child: Container(
                  width: 480,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: themeBg,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(widget.isDarkMode ? 0.5 : 0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: contentWidget,
                ),
              )
            : contentWidget,
      ),
    );
  }
}
