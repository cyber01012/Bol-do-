import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/notification_tile.dart';
import 'models/notification_ui_model.dart';
import 'trace_logs_screen.dart';

class NotificationScreen extends StatefulWidget {
  final bool isDarkMode;
  final String sessionId;
  final String? bookingId;

  const NotificationScreen({
    super.key,
    required this.isDarkMode,
    required this.sessionId,
    this.bookingId,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  late bool _isDarkMode;
  String _selectedTab = 'All';
  bool _isRefreshing = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  PageRouteBuilder _createSmoothPageRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildAnalyticsSection(int totalCount, int failedCount, int successPercent, int providerCount, int customerCount) {
    final ratioText = customerCount > 0 
        ? '${(providerCount / (providerCount + customerCount) * 100).toStringAsFixed(0)}% Provider / ${(customerCount / (providerCount + customerCount) * 100).toStringAsFixed(0)}% Customer'
        : 'No dynamic data';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E28).withOpacity(0.4) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NOTIFICATION ANALYTICS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280),
                  letterSpacing: 1.0,
                ),
              ),
              const SpinningAiIndicator(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticsItem('Total Sent', '$totalCount', Icons.send_rounded, const Color(0xFF8B5CF6)),
              _buildAnalyticsItem('Failed', '$failedCount', Icons.error_outline_rounded, const Color(0xFFEF4444)),
              _buildAnalyticsItem('Success Rate', '$successPercent%', Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ratio (Provider : Customer)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9EA3B0)),
              ),
              Text(
                ratioText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _isDarkMode ? Colors.white70 : const Color(0xFF1E2025),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: Row(
                children: [
                  if (providerCount == 0 && customerCount == 0)
                    Expanded(
                      child: Container(color: Colors.grey.withOpacity(0.2)),
                    )
                  else ...[
                    if (providerCount > 0)
                      Expanded(
                        flex: providerCount,
                        child: Container(color: const Color(0xFF3B82F6)),
                      ),
                    if (customerCount > 0)
                      Expanded(
                        flex: customerCount,
                        child: Container(color: const Color(0xFFEC4899)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9EA3B0)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineWidget(bool isBooking, bool isNotif, bool isFollowup) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E28).withOpacity(0.4) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORCHESTRATION PIPELINE TIMELINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF9EA3B0),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimelineNode('Booking', isBooking, Icons.calendar_today_rounded),
              _buildTimelineConnector(isNotif),
              _buildTimelineNode('Notification', isNotif, Icons.notifications_active_rounded),
              _buildTimelineConnector(isFollowup),
              _buildTimelineNode('Follow-up', isFollowup, Icons.repeat_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(String label, bool isDone, IconData icon) {
    final activeColor = const Color(0xFF8B5CF6);
    final inactiveColor = _isDarkMode ? Colors.white24 : Colors.black12;
    
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDone ? activeColor.withOpacity(0.1) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? activeColor : inactiveColor,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDone ? activeColor : (_isDarkMode ? Colors.white30 : Colors.black38),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDone ? (_isDarkMode ? Colors.white : const Color(0xFF1E2025)) : const Color(0xFF9EA3B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(bool isDone) {
    return Container(
      width: 24,
      height: 2,
      color: isDone ? const Color(0xFF8B5CF6) : (_isDarkMode ? Colors.white12 : Colors.black12),
    );
  }

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Combined real-time stream of notifications and followups from Firestore
  Stream<List<NotificationUiModel>> _getCombinedNotificationsStream() {
    final controller = StreamController<List<NotificationUiModel>>();
    StreamSubscription? subNotif;
    StreamSubscription? subFollow;

    List<NotificationUiModel> notificationsList = [];
    List<NotificationUiModel> followupsList = [];

    void emitMerged() {
      final merged = <NotificationUiModel>[];
      merged.addAll(notificationsList);
      merged.addAll(followupsList);

      // Sort by created_at descending (latest first)
      merged.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      if (!controller.isClosed) {
        controller.add(merged);
      }
    }

    subNotif = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen(
      (snapshot) {
        notificationsList = snapshot.docs.map((doc) {
          return NotificationUiModel.fromFirestore(doc.data(), doc.id, 'notifications');
        }).toList();
        emitMerged();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    subFollow = FirebaseFirestore.instance
        .collection('followups')
        .snapshots()
        .listen(
      (snapshot) {
        followupsList = snapshot.docs
            .map((doc) {
              return NotificationUiModel.fromFirestore(doc.data(), doc.id, 'followups');
            })
            .where((item) => item.notificationType == 'followup')
            .toList();
        emitMerged();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    controller.onCancel = () {
      subNotif?.cancel();
      subFollow?.cancel();
    };

    return controller.stream;
  }

  // Delete notification/followup from Firestore
  Future<void> _deleteNotification(NotificationUiModel item) async {
    try {
      await FirebaseFirestore.instance.collection(item.sourceCollection).doc(item.notificationId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification cleared successfully.'),
            backgroundColor: const Color(0xFF8B5CF6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Update status of notification/followup in Firestore
  Future<void> _updateNotificationStatus(NotificationUiModel item, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection(item.sourceCollection)
          .doc(item.notificationId)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Trigger simulated notification generation to give interactive demo data
  Future<void> _simulateNotificationTrigger() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final testSessionId = 'sess_sim_${DateTime.now().millisecondsSinceEpoch}';
      final timestamp = DateTime.now().toUtc().toIso8601String();

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('notif_sim_user_$testSessionId')
          .set({
        'notification_id': 'notif_sim_user_$testSessionId',
        'session_id': widget.sessionId.isNotEmpty ? widget.sessionId : testSessionId,
        'booking_id': 'book_sim_${DateTime.now().millisecondsSinceEpoch}',
        'recipient_id': 'user_customer_999',
        'recipient_type': 'user',
        'channel': 'sms',
        'message': 'Simulated: Booking confirmation sent to customer Ali Ahmed.',
        'status': 'delivered',
        'notification_type': 'simulation notifications',
        'created_at': timestamp,
      });

      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      print('Simulation Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = _isDarkMode ? const Color(0xFF0C0C0E) : const Color(0xFFF4F6F9);
    final themePrimaryText = _isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final appTheme = _isDarkMode
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          )
        : ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
          );

    return Theme(
      data: appTheme,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [const Color(0xFF060608), const Color(0xFF110C1B)]
                : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(themePrimaryText),
            body: StreamBuilder<List<NotificationUiModel>>(
              stream: _getCombinedNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final rawList = snapshot.data ?? [];
                
                final totalCount = rawList.length;
                final successCount = rawList
                    .where((item) => item.status == 'delivered' || item.status == 'sent')
                    .length;
                final successPercent = totalCount > 0 ? (successCount / totalCount * 100).toInt() : 100;
                final latestSession = rawList.isNotEmpty ? rawList.first.sessionId : 'N/A';
                
                final filteredList = rawList.where((item) {
                  final isFollowup = item.notificationType == 'followup';
                  final type = item.recipientType;
                  final status = item.status;

                  if (_selectedTab == 'Customer') {
                    return !isFollowup && (type == 'user' || type == 'customer');
                  } else if (_selectedTab == 'Provider') {
                    return !isFollowup && type == 'provider';
                  } else if (_selectedTab == 'Follow-up') {
                    return isFollowup;
                  } else if (_selectedTab == 'Failed') {
                    return status == 'failed';
                  }
                  return true;
                }).toList();

                final customerCount = rawList.where((item) {
                  final isFollow = item.notificationType == 'followup';
                  final type = item.recipientType;
                  return !isFollow && (type == 'user' || type == 'customer');
                }).length;
                
                final providerCount = rawList.where((item) {
                  final isFollow = item.notificationType == 'followup';
                  final type = item.recipientType;
                  return !isFollow && type == 'provider';
                }).length;
                
                final followCount = rawList.where((item) => item.notificationType == 'followup').length;
                final failedCount = rawList.where((item) => item.status == 'failed').length;

                final contentWidget = Stack(
                  children: [
                    if (_isDarkMode) ...[
                      Positioned(
                        top: -50,
                        left: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withOpacity(0.04),
                                blurRadius: 80,
                                spreadRadius: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        await Future.delayed(const Duration(milliseconds: 500));
                        setState(() {});
                      },
                      color: const Color(0xFF8B5CF6),
                      backgroundColor: _isDarkMode ? const Color(0xFF16161C) : Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 10,
                          bottom: 100,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroCard(totalCount, successPercent, latestSession),
                            _buildAnalyticsSection(totalCount, failedCount, successPercent, providerCount, customerCount),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('orchestration_sessions')
                                  .doc(widget.sessionId.isNotEmpty ? widget.sessionId : latestSession)
                                  .snapshots(),
                              builder: (context, sessionSnapshot) {
                                final data = sessionSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                                final completedMap = Map<String, bool>.from(data['completed_agents'] as Map? ?? {});
                                final pipelineStatus = data['pipeline_status'] as String? ?? 'pending';

                                final isBookingDone = completedMap['BookingAgent'] == true || 
                                    pipelineStatus == 'completed' || 
                                    totalCount > 0;
                                final isNotificationDone = completedMap['NotificationAgent'] == true || 
                                    pipelineStatus == 'completed' || 
                                    totalCount > 0;
                                final isFollowupDone = completedMap['FollowUpAgent'] == true || 
                                    pipelineStatus == 'completed' || 
                                    rawList.any((item) => item.notificationType == 'followup');

                                return _buildTimelineWidget(isBookingDone, isNotificationDone, isFollowupDone);
                              },
                            ),
                            const SizedBox(height: 24),

                            _buildFilterTabs(
                              totalCount,
                              customerCount,
                              providerCount,
                              followCount,
                              failedCount,
                              themePrimaryText,
                              themeSecondaryText,
                            ),
                            const SizedBox(height: 18),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'LIVE FEED (${filteredList.length} items)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: themeSecondaryText,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (filteredList.isNotEmpty)
                                    Text(
                                      'Swipe to clear • Press to edit',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: themeSecondaryText.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (filteredList.isEmpty)
                              _buildEmptyState(themeSecondaryText)
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  return StaggeredEntranceWidget(
                                    index: index,
                                    child: NotificationTile(
                                      item: item,
                                      isDarkMode: _isDarkMode,
                                      onLongPress: () {
                                        HapticFeedback.heavyImpact();
                                        _showItemDetailsSheet(item);
                                      },
                                      onDismissed: (direction) {
                                        _deleteNotification(item);
                                      },
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildFloatingIndicator(),
                      ),
                    ),

                    _buildBottomBar(latestSession, themeBg),
                  ],
                );

                if (isDesktop) {
                  return Center(
                    child: Container(
                      width: 480,
                      height: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: themeBg,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(_isDarkMode ? 0.5 : 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: contentWidget,
                    ),
                  );
                }

                return contentWidget;
              },
            ),
          ),
        ),
      ),
    );
  }

  // Floating indicator
  Widget _buildFloatingIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.85 + (_pulseController.value * 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xDC16161C) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3 + (_pulseController.value * 0.2)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1 + (_pulseController.value * 0.1)),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: _pulseController.value * 2,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Notification Pipeline Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B5CF6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Color themePrimaryText) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: themePrimaryText, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              color: themePrimaryText,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(_pulseController.value * 0.6 + 0.4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: _pulseController.value * 3,
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
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
    );
  }

  Widget _buildHeroCard(int totalCount, int successPercent, String latestSession) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1C132E), const Color(0xFF0F101E)]
              : [Colors.white, const Color(0xFFEBEFF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF38295C).withOpacity(0.5) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(_isDarkMode ? 0.08 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI ORCHESTRATION FEEDBACK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8B5CF6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_tethering_rounded, size: 8, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalCount',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Alerts Dispatched',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9EA3B0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 40,
                      color: _isDarkMode ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$successPercent%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10B981),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Delivery Success',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9EA3B0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE ORCHESTRATION SESSION',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: _isDarkMode ? Colors.white38 : Colors.black45,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latestSession,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isDarkMode ? Colors.white70 : const Color(0xFF4A4B50),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, size: 12, color: Color(0xFFEC4899)),
                          const SizedBox(width: 4),
                          Text(
                            'Synced',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _isDarkMode ? Colors.white70 : const Color(0xFF4A4B50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    int totalCount,
    int customerCount,
    int providerCount,
    int followCount,
    int failedCount,
    Color primaryText,
    Color secondaryText,
  ) {
    final tabs = [
      {'label': 'All', 'count': totalCount},
      {'label': 'Customer', 'count': customerCount},
      {'label': 'Provider', 'count': providerCount},
      {'label': 'Follow-up', 'count': followCount},
      {'label': 'Failed', 'count': failedCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final label = tab['label'] as String;
          final count = tab['count'] as int;
          final isSelected = _selectedTab == label;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = label;
              });
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : (_isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : (_isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : primaryText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white24
                          : (_isDarkMode ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showItemDetailsSheet(NotificationUiModel item) {
    IconData typeIcon;
    Color typeColor;
    String cleanRecipientName;

    if (item.recipientType == 'followup') {
      typeIcon = Icons.event_repeat_rounded;
      typeColor = Colors.amber;
      cleanRecipientName = 'System (Follow-up Agent)';
    } else if (item.recipientType == 'provider') {
      typeIcon = Icons.handyman_rounded;
      typeColor = const Color(0xFF3B82F6);
      cleanRecipientName = item.recipientId == 'provider_001' ? 'Ali Electric Works (Provider)' : 'Provider (${item.recipientId})';
    } else {
      typeIcon = Icons.person_outline_rounded;
      typeColor = const Color(0xFFEC4899);
      cleanRecipientName = item.recipientId == 'user_customer_999' ? 'Ali Ahmed (Customer)' : 'Customer (${item.recipientId})';
    }

    final formattedTime = item.createdAt != null
        ? '${item.createdAt!.day}/${item.createdAt!.month} ${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')}'
        : 'Just now';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xEC16161C) : Colors.white.withOpacity(0.92),
                border: Border(
                  top: BorderSide(
                    color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
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
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(typeIcon, size: 20, color: typeColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cleanRecipientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
                              ),
                            ),
                            Text(
                              'Channel: ${item.channel.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9EA3B0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDarkMode ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _isDarkMode ? const Color(0xFFF7F7F7) : const Color(0xFF23252E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailLabel('BOOKING ID', item.bookingId),
                      _buildDetailLabel('SESSION ID', item.sessionId),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailLabel('CREATED AT', formattedTime),
                      _buildDetailLabel('STATUS CODE', item.status.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'UPDATE STATUS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9EA3B0), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['pending', 'sent', 'delivered', 'failed'].map((st) {
                      final isCurrent = item.status == st;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _updateNotificationStatus(item, st);
                            Navigator.pop(context);
                            HapticFeedback.mediumImpact();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF8B5CF6)
                                  : (_isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFF8B5CF6)
                                    : (_isDarkMode ? Colors.white10 : Colors.black12),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              st.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                      _showPremiumSnackBar('Opening AI Decisions Log...');
                      Navigator.push(
                        context,
                        _createSmoothPageRoute(
                          TraceLogsScreen(
                            sessionId: item.sessionId,
                            bookingId: item.bookingId,
                            isDarkMode: _isDarkMode,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('View AI Decisions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.message));
                            Navigator.pop(context);
                            _showPremiumSnackBar('Copied message to clipboard.');
                            HapticFeedback.lightImpact();
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Text'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B5CF6),
                            side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteNotification(item);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Dismiss Alert'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailLabel(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9EA3B0),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.white70 : const Color(0xFF4A4B50),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerOpacity = _shimmerController.value * 0.4 + 0.2;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Opacity(
              opacity: shimmerOpacity,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 24, height: 24, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24)),
                            const SizedBox(width: 8),
                            Container(width: 100, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white24)),
                          ],
                        ),
                        Container(width: 60, height: 16, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(width: double.infinity, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white24)),
                    const SizedBox(height: 8),
                    Container(width: 180, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white24)),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.white12),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 80, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white12)),
                        Container(width: 60, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 14),
            const Text(
              'Connection Error',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications generated yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orchestrate a new booking repair to trigger real-time AI alert dispatches.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String latestSession, Color themeBg) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _simulateNotificationTrigger,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6))),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _showPremiumSnackBar('Opening AI Decisions Log...');
                        Navigator.push(
                          context,
                          _createSmoothPageRoute(
                            TraceLogsScreen(
                              sessionId: latestSession != 'N/A' ? latestSession : widget.sessionId,
                              bookingId: widget.bookingId,
                              isDarkMode: _isDarkMode,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'View AI Decisions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StaggeredEntranceWidget extends StatelessWidget {
  final Widget child;
  final int index;

  const StaggeredEntranceWidget({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class SpinningAiIndicator extends StatefulWidget {
  const SpinningAiIndicator({super.key});

  @override
  State<SpinningAiIndicator> createState() => _SpinningAiIndicatorState();
}

class _SpinningAiIndicatorState extends State<SpinningAiIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF8B5CF6)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C1C24) : Colors.white,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }
}
