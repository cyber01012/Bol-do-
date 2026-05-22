import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';

// Import local widgets
import 'widgets/sync_indicator.dart';
import 'widgets/debug_stat_card.dart';
import 'widgets/collection_status_card.dart';
import 'widgets/orchestration_stream_tile.dart';
import 'widgets/trace_preview_card.dart';
import '../booking/widgets/glass_card.dart';
import '../booking/trace_logs_screen.dart';

class CombinedStats {
  final int activeSessions;
  final int successBookings;
  final int failedBookings;
  final int pendingFollowups;
  final int activeDisputes;
  final int notificationsSent;
  final int tracesLogged;

  CombinedStats({
    required this.activeSessions,
    required this.successBookings,
    required this.failedBookings,
    required this.pendingFollowups,
    required this.activeDisputes,
    required this.notificationsSent,
    required this.tracesLogged,
  });
}

class FailureItem {
  final String id;
  final String type;
  final String description;
  final String timestamp;

  FailureItem({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
  });
}

class SupervisorDashboardScreen extends StatefulWidget {
  final bool isDarkMode;

  const SupervisorDashboardScreen({
    super.key,
    this.isDarkMode = true, // default to true since it might be opened from main_shell where we just call const SupervisorDashboardScreen()
  });

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> with SingleTickerProviderStateMixin {
  late bool _isDarkMode;
  late AnimationController _pulseController;
  bool _isClearing = false;

  // Cached Stream variables to optimize rebuild lifecycle
  late final Stream<CombinedStats> _statsStream;
  late final Stream<List<FailureItem>> _failuresStream;
  late final Stream<QuerySnapshot> _sessionsStream;
  late final Stream<QuerySnapshot> _tracesStream;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize all streams exactly once in initState
    _statsStream = _getCombinedStatsStream();
    _failuresStream = _getFailuresStream();
    _sessionsStream = FirebaseFirestore.instance
        .collection('orchestration_sessions')
        .orderBy('last_updated', descending: true)
        .limit(5)
        .snapshots();
    _tracesStream = FirebaseFirestore.instance
        .collection('agent_traces')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Combined real-time stats stream
  Stream<CombinedStats> _getCombinedStatsStream() {
    final controller = StreamController<CombinedStats>();
    
    StreamSubscription? subSessions;
    StreamSubscription? subBookings;
    StreamSubscription? subFollowups;
    StreamSubscription? subDisputes;
    StreamSubscription? subNotifs;
    StreamSubscription? subTraces;

    int activeSessions = 0;
    int successBookings = 0;
    int failedBookings = 0;
    int pendingFollowups = 0;
    int disputesCount = 0;
    int notificationsSent = 0;
    int tracesLogged = 0;

    void emitStats() {
      if (!controller.isClosed) {
        controller.add(CombinedStats(
          activeSessions: activeSessions,
          successBookings: successBookings,
          failedBookings: failedBookings,
          pendingFollowups: pendingFollowups,
          activeDisputes: disputesCount,
          notificationsSent: notificationsSent,
          tracesLogged: tracesLogged,
        ));
      }
    }

    subSessions = FirebaseFirestore.instance.collection('orchestration_sessions').snapshots().listen((snap) {
      activeSessions = snap.docs.where((doc) {
        final data = doc.data();
        final status = data['pipeline_status'] as String? ?? '';
        return status != 'completed' && status != 'failed' && status != 'completed_followup';
      }).length;
      emitStats();
    }, onError: (err) {
      // Stream error logging
    });

    subBookings = FirebaseFirestore.instance.collection('bookings').snapshots().listen((snap) {
      successBookings = snap.docs.where((doc) {
        final data = doc.data();
        final status = data['booking_status'] as String? ?? data['status'] as String? ?? '';
        return status == 'confirmed' || status == 'assigned' || status == 'completed';
      }).length;

      failedBookings = snap.docs.where((doc) {
        final data = doc.data();
        final status = data['booking_status'] as String? ?? data['status'] as String? ?? '';
        return status == 'failed' || status == 'rejected';
      }).length;

      emitStats();
    }, onError: (err) {
      // Stream error logging
    });

    subFollowups = FirebaseFirestore.instance.collection('followups').snapshots().listen((snap) {
      pendingFollowups = snap.docs.where((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        return status == 'pending' || status == 'scheduled';
      }).length;
      emitStats();
    }, onError: (err) {
      // Stream error logging
    });

    subDisputes = FirebaseFirestore.instance.collection('disputes').snapshots().listen((snap) {
      disputesCount = snap.docs.length;
      emitStats();
    }, onError: (err) {
      // Stream error logging
    });

    subNotifs = FirebaseFirestore.instance.collection('notifications').snapshots().listen((snap) {
      notificationsSent = snap.docs.length;
      emitStats();
    }, onError: (err) {
      // Stream error logging
    });

    subTraces = FirebaseFirestore.instance.collection('agent_traces').snapshots().listen((snap) {
      tracesLogged = snap.docs.length;
      emitStats();
    }, onError: (err) {
      // Stream error logging
    });

    controller.onCancel = () {
      subSessions?.cancel();
      subBookings?.cancel();
      subFollowups?.cancel();
      subDisputes?.cancel();
      subNotifs?.cancel();
      subTraces?.cancel();
    };

    return controller.stream;
  }

  // Combined failures stream
  Stream<List<FailureItem>> _getFailuresStream() {
    final controller = StreamController<List<FailureItem>>();
    
    StreamSubscription? subSessions;
    StreamSubscription? subBookings;
    StreamSubscription? subNotifs;
    StreamSubscription? subDisputes;

    List<FailureItem> sessionFailures = [];
    List<FailureItem> bookingFailures = [];
    List<FailureItem> notifFailures = [];
    List<FailureItem> disputeFailures = [];

    void emitFailures() {
      final merged = <FailureItem>[];
      merged.addAll(sessionFailures);
      merged.addAll(bookingFailures);
      merged.addAll(notifFailures);
      merged.addAll(disputeFailures);

      merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!controller.isClosed) {
        controller.add(merged);
      }
    }

    subSessions = FirebaseFirestore.instance
        .collection('orchestration_sessions')
        .snapshots()
        .listen((snap) {
      sessionFailures = snap.docs.where((doc) {
        final data = doc.data();
        final isFailed = data['pipeline_status'] == 'failed' || data['orchestration_status'] == 'failed';
        final isFallback = data['is_fallback'] == true || data['fallback_triggered'] == true || data['pipeline_status'] == 'fallback';
        return isFailed || isFallback;
      }).map((doc) {
        final data = doc.data();
        final isFailed = data['pipeline_status'] == 'failed' || data['orchestration_status'] == 'failed';
        return FailureItem(
          id: doc.id,
          type: isFailed ? 'Orchestration Session' : 'Degraded Fallback',
          description: isFailed 
              ? 'Orchestration pipeline terminated with failure.' 
              : 'Pipeline degraded. Agent fallback mechanism active.',
          timestamp: data['last_updated'] as String? ?? data['created_at'] as String? ?? '',
        );
      }).toList();
      emitFailures();
    });

    subBookings = FirebaseFirestore.instance
        .collection('bookings')
        .where('booking_status', isEqualTo: 'failed')
        .snapshots()
        .listen((snap) {
      bookingFailures = snap.docs.map((doc) {
        final data = doc.data();
        return FailureItem(
          id: doc.id,
          type: 'Booking Request',
          description: data['failure_reason'] as String? ?? 'Booking rejected or conflicted.',
          timestamp: data['requested_time'] as String? ?? '',
        );
      }).toList();
      emitFailures();
    });

    subNotifs = FirebaseFirestore.instance
        .collection('notifications')
        .where('status', isEqualTo: 'failed')
        .snapshots()
        .listen((snap) {
      notifFailures = snap.docs.map((doc) {
        final data = doc.data();
        return FailureItem(
          id: doc.id,
          type: 'Notification Alert',
          description: 'Failed to deliver SMS/Push notice to user.',
          timestamp: data['created_at'] as String? ?? '',
        );
      }).toList();
      emitFailures();
    });

    subDisputes = FirebaseFirestore.instance
        .collection('disputes')
        .snapshots()
        .listen((snap) {
      disputeFailures = snap.docs.where((doc) {
        final data = doc.data();
        final esc = data['escalation_metadata'] as Map? ?? {};
        final isEscalated = esc['is_escalated'] == true || data['status'] == 'escalated';
        return isEscalated;
      }).map((doc) {
        final data = doc.data();
        final dt = data['created_at'];
        String ts = '';
        if (dt is Timestamp) {
          ts = dt.toDate().toUtc().toIso8601String();
        } else if (dt is String) {
          ts = dt;
        }

        return FailureItem(
          id: doc.id,
          type: 'Dispute Escalation',
          description: 'Dispute escalated to Human Support due to high severity.',
          timestamp: ts,
        );
      }).toList();
      emitFailures();
    });

    controller.onCancel = () {
      subSessions?.cancel();
      subBookings?.cancel();
      subNotifs?.cancel();
      subDisputes?.cancel();
    };

    return controller.stream;
  }

  // Clear Firestore data for testing/demo resets
  Future<void> _clearTestData() async {
    setState(() {
      _isClearing = true;
    });
    HapticFeedback.vibrate();

    final collections = [
      'orchestration_sessions',
      'bookings',
      'notifications',
      'followups',
      'disputes',
      'agent_traces',
    ];

    try {
      for (final col in collections) {
        final snap = await FirebaseFirestore.instance.collection(col).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All test databases reset successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting data: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  // Export the latest active session metadata as JSON
  Future<void> _exportLatestSession() async {
    HapticFeedback.mediumImpact();
    
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orchestration_sessions')
          .orderBy('last_updated', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Error'),
              content: const Text('No orchestration sessions available to export. Run a pipeline first.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final doc = snap.docs.first;
      final sessionData = doc.data();
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'session_id': doc.id,
        ...sessionData,
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF16161C) : Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.share_rounded, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text('Export Session JSON'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latest Session ID payload:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C0C0E) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        jsonString,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonString));
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session payload copied to clipboard!'),
                        backgroundColor: Color(0xFF8B5CF6),
                      ),
                    );
                  },
                  child: const Text('Copy to Clipboard', style: TextStyle(color: Color(0xFF8B5CF6))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Export error logger
    }
  }

  Widget _buildHeader(Color themePrimaryText, Color themeSecondaryText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Realtime Orchestration Monitor",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: themePrimaryText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Live Firestore synchronization across all agents",
                style: TextStyle(
                  fontSize: 11,
                  color: themeSecondaryText,
                ),
              ),
            ],
          ),
        ),
        const SyncIndicator(isSyncing: true),
      ],
    );
  }

  Widget _buildSystemHealth(Color themeSecondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SYSTEM HEALTH OVERVIEW',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: themeSecondaryText,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<CombinedStats>(
          stream: _statsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    DebugStatCard(
                      title: 'Active Sessions',
                      value: 0,
                      icon: Icons.lan_outlined,
                      color: Color(0xFF3B82F6),
                      isLoading: true,
                    ),
                    DebugStatCard(
                      title: 'Bookings Successful',
                      value: 0,
                      icon: Icons.check_circle_outline_rounded,
                      color: Color(0xFF10B981),
                      isLoading: true,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Text(
                  'Error loading health metrics: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              );
            }

            final stats = snapshot.data;

            if (stats == null) {
              return const SizedBox();
            }

            return SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  DebugStatCard(
                    title: 'Active Sessions',
                    value: stats.activeSessions,
                    icon: Icons.lan_outlined,
                    color: const Color(0xFF3B82F6),
                    isLoading: false,
                  ),
                  DebugStatCard(
                    title: 'Bookings Successful',
                    value: stats.successBookings,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF10B981),
                    isLoading: false,
                  ),
                  DebugStatCard(
                    title: 'Bookings Failed',
                    value: stats.failedBookings,
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFEF4444),
                    isLoading: false,
                  ),
                  DebugStatCard(
                    title: 'Followups Pending',
                    value: stats.pendingFollowups,
                    icon: Icons.repeat_rounded,
                    color: Colors.amber,
                    isLoading: false,
                  ),
                  DebugStatCard(
                    title: 'Disputes Count',
                    value: stats.activeDisputes,
                    icon: Icons.gavel_rounded,
                    color: const Color(0xFFEF4444),
                    isLoading: false,
                  ),
                  DebugStatCard(
                    title: 'Notifications Sent',
                    value: stats.notificationsSent,
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFEC4899),
                    isLoading: false,
                  ),
                  DebugStatCard(
                    title: 'Traces Logged',
                    value: stats.tracesLogged,
                    icon: Icons.history_rounded,
                    color: const Color(0xFF8B5CF6),
                    isLoading: false,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFailureDetector(Color themePrimaryText, Color themeSecondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAILURE & EXCEPTION DETECTOR',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: themeSecondaryText,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<FailureItem>>(
          stream: _failuresStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6))),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Text(
                  'Error in detector logic: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              );
            }

            final failures = snapshot.data ?? [];

            if (failures.isEmpty) {
              return GlassCard(
                padding: 14.0,
                radius: 18.0,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Systems Nominal',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: themePrimaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Zero pipeline degraded states or runtime failures detected.',
                            style: TextStyle(fontSize: 10, color: themeSecondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: failures.map((fail) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.6 + (_pulseController.value * 0.4),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${fail.type} Failure',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: themePrimaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  fail.description,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: themePrimaryText.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${fail.id} • ${fail.timestamp}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontFamily: 'monospace',
                                    color: themeSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPipelines(Color themeSecondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REALTIME ORCHESTRATION PIPELINES',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: themeSecondaryText,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _sessionsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6))));
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('Error loading sessions stream: ${snapshot.error}', style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No active orchestration sessions in Firestore.',
                    style: TextStyle(color: themeSecondaryText, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                return OrchestrationStreamTile(
                  sessionData: doc.data() as Map<String, dynamic>,
                  sessionId: doc.id,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTraces(Color themePrimaryText, Color themeSecondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI AGENT DECISION TRACES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: themeSecondaryText,
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: () {
                FirebaseFirestore.instance
                    .collection('orchestration_sessions')
                    .orderBy('last_updated', descending: true)
                    .limit(1)
                    .get()
                    .then((snap) {
                  final sessId = snap.docs.isNotEmpty ? snap.docs.first.id : 'sess_001';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TraceLogsScreen(
                        sessionId: sessId,
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                  );
                });
              },
              child: const Row(
                children: [
                  Text('View Logs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                  Icon(Icons.arrow_right_rounded, size: 16, color: Color(0xFF8B5CF6)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _tracesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6))));
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('Error loading trace stream: ${snapshot.error}', style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No agent traces captured yet.',
                    style: TextStyle(color: themeSecondaryText, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                return TracePreviewCard(
                  traceData: doc.data() as Map<String, dynamic>,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCollectionStatus(Color themeSecondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE COLLECTION OBSERVERS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: themeSecondaryText,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        const CollectionStatusCard(
          displayName: 'Orchestration Sessions',
          collectionName: 'orchestration_sessions',
          icon: Icons.lan_outlined,
        ),
        const CollectionStatusCard(
          displayName: 'Bookings Database',
          collectionName: 'bookings',
          icon: Icons.calendar_today_rounded,
        ),
        const CollectionStatusCard(
          displayName: 'Notification Logs',
          collectionName: 'notifications',
          icon: Icons.notifications_active_rounded,
        ),
        const CollectionStatusCard(
          displayName: 'Followups Automation',
          collectionName: 'followups',
          icon: Icons.repeat_rounded,
        ),
        const CollectionStatusCard(
          displayName: 'Dispute Cases',
          collectionName: 'disputes',
          icon: Icons.gavel_rounded,
        ),
        const CollectionStatusCard(
          displayName: 'Agent Trace History',
          collectionName: 'agent_traces',
          icon: Icons.history_rounded,
        ),
        const CollectionStatusCard(
          displayName: 'Service Providers',
          collectionName: 'providers',
          icon: Icons.people_outline_rounded,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _isDarkMode = isDarkMode;
    final themeBg = Theme.of(context).scaffoldBackgroundColor;
    final themePrimaryText = Theme.of(context).textTheme.bodyLarge?.color ?? (isDarkMode ? Colors.white : const Color(0xFF1E2025));
    final themeSecondaryText = Theme.of(context).textTheme.bodyMedium?.color ?? (isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280));

    final contentWidget = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: themePrimaryText),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          children: [
            Text(
              'Firestore Observability',
              style: TextStyle(
                color: themePrimaryText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Orchestration Console v1.0',
              style: TextStyle(
                color: themeSecondaryText,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
            ),
            child: IconButton(
              onPressed: () {
                themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                HapticFeedback.selectionClick();
              },
              icon: Icon(
                _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                color: _isDarkMode ? Colors.amber : const Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient glows
          if (_isDarkMode) ...[
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.04),
                      blurRadius: 90,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.04),
                      blurRadius: 90,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 20, right: 10, top: 10, bottom: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(themePrimaryText, themeSecondaryText),
                            const SizedBox(height: 20),
                            _buildSystemHealth(themeSecondaryText),
                            const SizedBox(height: 24),
                            _buildPipelines(themeSecondaryText),
                            const SizedBox(height: 24),
                            _buildCollectionStatus(themeSecondaryText),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 10, right: 20, top: 10, bottom: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 48), // spacer to align with header
                            _buildFailureDetector(themePrimaryText, themeSecondaryText),
                            const SizedBox(height: 24),
                            _buildTraces(themePrimaryText, themeSecondaryText),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Mobile View (Single Column)
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(themePrimaryText, themeSecondaryText),
                    const SizedBox(height: 20),
                    _buildSystemHealth(themeSecondaryText),
                    const SizedBox(height: 24),
                    _buildFailureDetector(themePrimaryText, themeSecondaryText),
                    const SizedBox(height: 24),
                    _buildPipelines(themeSecondaryText),
                    const SizedBox(height: 24),
                    _buildTraces(themePrimaryText, themeSecondaryText),
                    const SizedBox(height: 24),
                    _buildCollectionStatus(themeSecondaryText),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),

          // BOTTOM STICKY ACTIONS BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xEC16161C) : Colors.white.withOpacity(0.85),
                    border: Border(
                      top: BorderSide(
                        color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Action 1: Refresh
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isDarkMode ? Colors.white24 : Colors.black12,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Icon(Icons.refresh_rounded, color: themePrimaryText, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action 2: Export Session
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _exportLatestSession,
                          icon: const Icon(Icons.ios_share_rounded, size: 16, color: Colors.white),
                          label: const Text('Export JSON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDarkMode ? const Color(0xFF2E2E3E) : const Color(0xFF4B5563),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action 3: Clear/Reset
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isClearing
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Clear Test Data'),
                                        content: const Text('Are you sure you want to delete all database entries across all orchestration logs? This action is destructive and cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _clearTestData();
                                            },
                                            child: const Text('Wipe Data', style: TextStyle(color: Color(0xFFEF4444))),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            icon: _isClearing
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Clear DB',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF060608), const Color(0xFF110C1B)]
              : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: contentWidget,
      ),
    );
  }
}
