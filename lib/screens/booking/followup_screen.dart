import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/glass_card.dart';
import 'trace_logs_screen.dart';
import 'dispute_screen.dart';
import 'models/followup_ui_model.dart';

class FollowUpScreen extends StatefulWidget {
  final String sessionId;
  final String? bookingId;
  final bool isDarkMode;

  const FollowUpScreen({
    super.key,
    required this.sessionId,
    this.bookingId,
    required this.isDarkMode,
  });

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> with TickerProviderStateMixin {
  late bool _isDarkMode;
  bool _isSimulating = false;
  String? _selectedGroupKey;
  String _selectedFilter = 'All';
  bool _showAdvancedKpis = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rotationController;

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

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // Smooth route transition
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

  // Show premium snackbar
  void _showPremiumSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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

  // Delete individual followup from Firestore
  Future<void> _deleteFollowUp(String id) async {
    try {
      await FirebaseFirestore.instance.collection('followups').doc(id).delete();
      _showPremiumSnackBar('Automation event cleared from record.');
    } catch (e) {
      _showPremiumSnackBar('Error clearing follow-up: $e', isError: true);
    }
  }

  // Simulate follow-up feedback response to trigger sentiment analysis & re-engagement / dispute
  Future<void> _simulateFeedbackOrchestration(String actualSessionId, double rating, String feedback) async {
    if (_isSimulating) return;
    setState(() {
      _isSimulating = true;
    });
    HapticFeedback.mediumImpact();

    try {
      // Find the main session document or update follow-up values
      final mainDocId = 'followup_$actualSessionId';
      final timestamp = DateTime.now().toUtc().toIso8601String();

      // Trigger standard model service behaviour locally for simulation
      // Under Completed status, FollowUpAgent processes sentiment and creates re-engagement or dispute suggestions.
      // We will perform a miniature write representation matching the logic of FollowUpAgentService.
      String sentiment = 'neutral';
      final fText = feedback.toLowerCase();
      final negativeKeywords = ['bad', 'worst', 'poor', 'slow', 'unprofessional', 'fraud', 'broken', 'disappointed', 'terrible', 'waste'];
      bool hasNegativeWord = false;
      for (final kw in negativeKeywords) {
        if (fText.contains(kw)) {
          hasNegativeWord = true;
          break;
        }
      }

      if (rating >= 4.0 && !hasNegativeWord) {
        sentiment = 'positive';
      } else if (rating <= 2.0 || hasNegativeWord) {
        sentiment = 'negative';
      }

      final Map<String, dynamic> updateData = {
        'rating': rating,
        'feedback': feedback,
        'sentiment': sentiment,
        'updated_at': timestamp,
      };

      if (sentiment == 'negative') {
        updateData['status'] = 'disputed';
        updateData['dispute_triggered'] = true;
        updateData['re_engagement_triggered'] = false;

        // Create individual dispute suggestion alert
        final disputeDocId = 'followup_dispute_$actualSessionId';
        final disputeMsg = 'Assalam-o-Alaikum! We are sorry to hear that you had a poor experience. A dispute support agent has been notified and will contact you shortly to resolve this.';
        await FirebaseFirestore.instance.collection('followups').doc(disputeDocId).set({
          'followup_id': disputeDocId,
          'session_id': actualSessionId,
          'booking_id': widget.bookingId ?? 'book_$actualSessionId',
          'recipient_id': 'user_customer_999',
          'followup_type': 'dispute_suggestion',
          'message': disputeMsg,
          'status': 'sent',
          'created_at': timestamp,
          'scheduled_at': timestamp,
        });

      } else {
        updateData['status'] = 're_engaged';
        updateData['re_engagement_triggered'] = true;
        updateData['dispute_triggered'] = false;

        // Create individual re-engagement flow alert
        final reEngageDocId = 'followup_re_engagement_$actualSessionId';
        final reEngageMsg = 'Assalam-o-Alaikum! Thank you for the wonderful ${rating.toInt()}-star rating! Share BolDo with your friends and get 10% off your next booking.';
        await FirebaseFirestore.instance.collection('followups').doc(reEngageDocId).set({
          'followup_id': reEngageDocId,
          'session_id': actualSessionId,
          'booking_id': widget.bookingId ?? 'book_$actualSessionId',
          'recipient_id': 'user_customer_999',
          'followup_type': 're_engagement_flow',
          'message': reEngageMsg,
          'status': 'delivered',
          'created_at': timestamp,
          'scheduled_at': timestamp,
        });
      }

      await FirebaseFirestore.instance.collection('followups').doc(mainDocId).update(updateData);
      _showPremiumSnackBar('Simulated sentiment orchestration computed successfully!');
    } catch (e) {
      _showPremiumSnackBar('Simulation error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSimulating = false;
        });
      }
    }
  }

  String _formatReadableTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    
    final now = DateTime.now();
    final localTime = dateTime.toLocal();
    final difference = now.difference(localTime);

    if (difference.inSeconds < 15) {
      return 'Just now';
    } else if (difference.inMinutes < 60 && difference.inMinutes >= 0) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (localTime.year == now.year && localTime.month == now.month && localTime.day == now.day) {
      final hour = localTime.hour == 0 ? 12 : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
      final amPm = localTime.hour >= 12 ? 'PM' : 'AM';
      final minuteStr = localTime.minute.toString().padLeft(2, '0');
      return 'Today • $hour:$minuteStr $amPm';
    } else {
      final dayStr = localTime.day.toString().padLeft(2, '0');
      final monthStr = localTime.month.toString().padLeft(2, '0');
      final hour = localTime.hour == 0 ? 12 : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
      final amPm = localTime.hour >= 12 ? 'PM' : 'AM';
      final minuteStr = localTime.minute.toString().padLeft(2, '0');
      return '$dayStr/$monthStr • $hour:$minuteStr $amPm';
    }
  }

  bool _matchesFilter(FollowUpUiModel action, String filter) {
    if (filter == 'All') return true;
    final type = action.followupType.toLowerCase();
    if (filter == 'Reminders') return type.contains('reminder');
    if (filter == 'Completion Checks') return type.contains('completion');
    if (filter == 'Rating Requests') return type.contains('rating');
    if (filter == 'Re-engagement') return type.contains('re_engagement');
    if (filter == 'Disputes') return type.contains('dispute');
    return true;
  }

  Widget _buildFilterPills(Color secondaryText) {
    final filters = ['All', 'Reminders', 'Completion Checks', 'Rating Requests', 'Re-engagement', 'Disputes'];
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = f == _selectedFilter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedFilter = f;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : (_isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (_isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : secondaryText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupSelector(List<OrchestrationGroup> groups, String selectedKey) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final group = groups[index];
          final key = '${group.bookingId}_${group.sessionId}';
          final isSelected = key == selectedKey;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedGroupKey = key;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                    : null,
                color: isSelected
                    ? null
                    : (_isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (_isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 14,
                    color: isSelected ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${group.bookingId.replaceAll('book_', '#')} (${group.sessionId.substring(0, group.sessionId.length > 4 ? 4 : group.sessionId.length)})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Stream data from Firestore and process in memory
  Stream<OrchestrationStreamData> _getOrchestrationStream() {
    final controller = StreamController<OrchestrationStreamData>();
    StreamSubscription? sub;

    sub = FirebaseFirestore.instance.collection('followups').snapshots().listen(
      (snapshot) {
        final docs = snapshot.docs;
        final Map<String, OrchestrationGroup> groupsMap = {};

        for (final doc in docs) {
          final data = doc.data();
          final bId = data['booking_id'] as String? ?? '';
          final sId = data['session_id'] as String? ?? '';
          if (bId.isEmpty && sId.isEmpty) continue;

          final key = '${bId}_${sId}';
          if (!groupsMap.containsKey(key)) {
            groupsMap[key] = OrchestrationGroup(
              bookingId: bId,
              sessionId: sId,
              actions: [],
            );
          }

          final group = groupsMap[key]!;
          final hasType = data.containsKey('followup_type') && data['followup_type'] != null && (data['followup_type'] as String).isNotEmpty;

          if (hasType) {
            group.actions.add(FollowUpUiModel.fromFirestore(data, doc.id));
          } else {
            groupsMap[key] = OrchestrationGroup(
              bookingId: bId,
              sessionId: sId,
              mainSessionDoc: data,
              actions: group.actions,
            );
          }
        }

        for (final group in groupsMap.values) {
          group.actions.sort((a, b) {
            final aTime = a.createdAt ?? a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? b.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
        }

        final sortedGroups = groupsMap.values.toList();
        sortedGroups.sort((a, b) {
          DateTime getLatestTime(OrchestrationGroup g) {
            DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
            if (g.mainSessionDoc != null) {
              final rawCreated = g.mainSessionDoc!['created_at'];
              if (rawCreated != null) {
                final parsed = DateTime.tryParse(rawCreated.toString());
                if (parsed != null && parsed.isAfter(latest)) latest = parsed;
              }
            }
            for (final act in g.actions) {
              final t = act.createdAt ?? act.scheduledAt;
              if (t != null && t.isAfter(latest)) latest = t;
            }
            return latest;
          }
          return getLatestTime(b).compareTo(getLatestTime(a));
        });

        if (!controller.isClosed) {
          controller.add(OrchestrationStreamData(
            groups: sortedGroups,
            hasData: sortedGroups.isNotEmpty,
          ));
        }
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    controller.onCancel = () {
      sub?.cancel();
    };

    return controller.stream;
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
            body: StreamBuilder<OrchestrationStreamData>(
              stream: _getOrchestrationStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final streamData = snapshot.data;
                if (streamData == null || !streamData.hasData || streamData.groups.isEmpty) {
                  return _buildEmptyState(themeSecondaryText);
                }

                final groups = streamData.groups;

                // Match/Select active group
                String selectedKey = _selectedGroupKey ?? '';
                if (selectedKey.isEmpty || !groups.any((g) => '${g.bookingId}_${g.sessionId}' == selectedKey)) {
                  // Find a group matching widget.sessionId first
                  final matchingGroup = groups.firstWhere(
                    (g) => g.sessionId == widget.sessionId,
                    orElse: () => groups.first,
                  );
                  selectedKey = '${matchingGroup.bookingId}_${matchingGroup.sessionId}';
                  // Keep it in state without triggering rebuild during layout
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedGroupKey = selectedKey;
                      });
                    }
                  });
                }

                final activeGroup = groups.firstWhere(
                  (g) => '${g.bookingId}_${g.sessionId}' == selectedKey,
                  orElse: () => groups.first,
                );

                final String activeSessionId = activeGroup.sessionId;
                final Map<String, dynamic> mainSession = activeGroup.mainSessionDoc ?? {
                  'booking_id': activeGroup.bookingId,
                  'session_id': activeGroup.sessionId,
                  'status': 'confirmed_followups_scheduled',
                  're_engagement_triggered': false,
                  'dispute_triggered': false,
                };

                // Filter actions based on selected filter pill
                final List<FollowUpUiModel> allActions = activeGroup.actions;
                final List<FollowUpUiModel> filteredActions = allActions.where((a) => _matchesFilter(a, _selectedFilter)).toList();

                // Calculate metrics based on ALL actions in active group
                final totalFollowUps = allActions.length;
                final completedAutomations = allActions.where((a) {
                  final status = a.status.toLowerCase();
                  return status == 'completed' || status == 'sent' || status == 'delivered';
                }).length;
                final pendingReminders = allActions.where((a) {
                  final status = a.status.toLowerCase();
                  return status == 'pending' || status == 'scheduled';
                }).length;

                final hasFailed = allActions.any((a) => a.status.toLowerCase() == 'failed');
                final healthStatus = hasFailed ? 'Degraded (90%)' : 'Optimal (100%)';

                final contentWidget = Stack(
                  children: [
                    // Ambient Glow in dark mode
                    if (_isDarkMode) ...[
                      Positioned(
                        top: -80,
                        left: -80,
                        child: Container(
                          width: 250,
                          height: 250,
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
                        right: -80,
                        child: Container(
                          width: 250,
                          height: 250,
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
                          bottom: 110,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 0. PIPELINE GROUP SELECTOR (Only shown if more than 1 pipeline is available)
                            if (groups.length > 1) ...[
                              _buildGroupSelector(groups, selectedKey),
                              const SizedBox(height: 8),
                            ],

                            // 1. LIVE ORCHESTRATION BADGES
                            _buildLiveBadges(mainSession, allActions),
                            const SizedBox(height: 8),

                            // 2. HERO GLASS CARD
                            _buildHeroCard(
                              totalFollowUps,
                              completedAutomations,
                              pendingReminders,
                              healthStatus,
                              activeSessionId,
                              mainSession,
                            ),
                            const SizedBox(height: 24),

                            // 3. AI ORCHESTRATION JOURNEY MAP
                            _buildJourneyMap(mainSession, allActions),
                            const SizedBox(height: 24),

                            // 4. AUTOMATED AI TIMELINE
                            _buildTimelineWidget(mainSession, allActions, themePrimaryText, themeSecondaryText),
                            const SizedBox(height: 24),

                            // 5. SENTIMENT ANALYSIS SECTION
                            _buildSentimentSection(mainSession, activeSessionId, themePrimaryText, themeSecondaryText),
                            const SizedBox(height: 24),

                            // 6. AGENT TRACE MINI PREVIEW
                            _buildAgentTracePreview(mainSession),
                            const SizedBox(height: 24),

                            // 4. FOLLOW-UP CARDS LIVE FEED
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'AUTOMATED ALERTS FEED (${filteredActions.length})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: themeSecondaryText,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (filteredActions.isNotEmpty)
                                    Text(
                                      'Swipe to dismiss • Press to audit',
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

                            // 4b. FILTER PILLS
                            _buildFilterPills(themeSecondaryText),
                            const SizedBox(height: 8),

                            if (filteredActions.isEmpty)
                              _buildEmptyFeedState(themeSecondaryText)
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredActions.length,
                                itemBuilder: (context, index) {
                                  final item = filteredActions[index];
                                  return _buildFollowUpTile(item, index);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Floating active orchestration indicator
                    Positioned(
                      bottom: 96,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SpinningAiIndicator(),
                            const SizedBox(width: 8),
                            Text(
                              'Follow-up orchestration active',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 9. STICKY BOTTOM CTA
                    _buildBottomBar(activeSessionId, mainSession, themeBg),
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

  // 1. APP BAR
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Follow-up Automation',
                style: TextStyle(
                  color: themePrimaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'AI lifecycle orchestration',
                style: TextStyle(
                  color: _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 7,
                height: 7,
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
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // 2. HERO GLASS CARD WITH SPINNING GRADIENT BORDER
  Widget _buildHeroCard(
    int total,
    int completed,
    int pending,
    String health,
    String activeSessionId,
    Map<String, dynamic> mainSession,
  ) {
    final sentiment = mainSession['sentiment'] as String? ?? '';
    final status = (mainSession['status'] as String? ?? '').toLowerCase();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(_isDarkMode ? 0.08 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          // Border glow emulation
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const SweepGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              gradient: LinearGradient(
                colors: _isDarkMode
                    ? [const Color(0xFF1C132E), const Color(0xFF0F101E)]
                    : [Colors.white, const Color(0xFFEBEFF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  top: -15,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.1),
                          blurRadius: 30,
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
                          Row(
                            children: [
                              Text(
                                _showAdvancedKpis ? 'AI PERFORMANCE CORE' : 'AI ORCHESTRATION INSIGHTS',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8B5CF6),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _showAdvancedKpis ? 'KPI' : 'SUM',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Toggle Button for KPIs vs Summary
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showAdvancedKpis = !_showAdvancedKpis;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Icon(
                                    _showAdvancedKpis ? Icons.dashboard_rounded : Icons.analytics_rounded,
                                    size: 14,
                                    color: const Color(0xFFEC4899),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                      'ACTIVE',
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      AnimatedCrossFade(
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$total',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Total Events',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9EA3B0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildDivider(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$completed',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF10B981),
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9EA3B0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildDivider(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$pending',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.amber,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Pending',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9EA3B0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Colors.white10),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ORCHESTRATION HEALTH',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: _isDarkMode ? Colors.white38 : Colors.black45,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: health.toLowerCase().contains('degraded') ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            health,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _isDarkMode ? Colors.white70 : const Color(0xFF4A4B50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hub_outlined, size: 12, color: Color(0xFFEC4899)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Session: ${activeSessionId.length > 10 ? activeSessionId.substring(0, 10) : activeSessionId}',
                                        style: TextStyle(
                                          fontSize: 9,
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
                        secondChild: _buildAdvancedKpis(sentiment, status),
                        crossFadeState: _showAdvancedKpis ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 350),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.5,
      height: 35,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: _isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1),
    );
  }

  // 3. AUTOMATED AI TIMELINE
  Widget _buildTimelineWidget(
    Map<String, dynamic> mainSession,
    List<FollowUpUiModel> actions,
    Color primaryText,
    Color secondaryText,
  ) {
    // Check which timeline nodes are active/completed based on document status
    final sessionStatus = (mainSession['status'] as String? ?? '').toLowerCase();
    
    final bool isConfirmed = true; // Booking is already confirmed
    
    // Reminders are scheduled or sent
    final bool hasReminder = actions.any((a) => a.followupType.contains('reminder'));
    final bool isReminderDone = actions.any((a) {
      final t = a.followupType.toLowerCase();
      final s = a.status.toLowerCase();
      return t.contains('reminder') && (s == 'sent' || s == 'delivered' || s == 'completed');
    });

    // Completion checks are scheduled or completed
    final bool hasCompletion = actions.any((a) => a.followupType.contains('completion'));
    final bool isCompletionDone = actions.any((a) {
      final t = a.followupType.toLowerCase();
      final s = a.status.toLowerCase();
      return t.contains('completion') && (s == 'sent' || s == 'delivered' || s == 'completed');
    });

    // Rating requests
    final bool hasRatingRequest = actions.any((a) => a.followupType.contains('rating'));
    final bool isRatingDone = mainSession.containsKey('rating') && mainSession['rating'] != null;

    // Sentiment Analysis
    final bool isSentimentDone = mainSession.containsKey('sentiment') && mainSession['sentiment'] != null;
    final String sentiment = mainSession['sentiment'] as String? ?? '';

    // Re-engagement OR Dispute triggered
    final bool isReEngagement = mainSession['re_engagement_triggered'] == true || sessionStatus == 're_engaged';
    final bool isDispute = mainSession['dispute_triggered'] == true || sessionStatus == 'disputed';
    final bool isEndWorkflowDone = isReEngagement || isDispute;

    // Relative timestamps calculation
    final createdTime = mainSession['created_at'] != null ? DateTime.tryParse(mainSession['created_at']) : DateTime.now();
    final String formattedStart = createdTime != null 
        ? '${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}' 
        : '00:00';

    return GlassCard(
      radius: 20,
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI LIFECYCLE TIMELINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: secondaryText,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Progressive Flow',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B5CF6).withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Step 1: Booking Confirmed
          _buildTimelineStep(
            'Booking Confirmed',
            'Service confirmation received. Scheduling auto checks.',
            formattedStart,
            isConfirmed,
            false,
            Icons.check_circle_outline_rounded,
            'Confirmed',
            const Color(0xFF10B981),
            primaryText,
            secondaryText,
            index: 0,
          ),
          _buildTimelineDivider(hasReminder),

          // Step 2: Reminder Scheduled
          _buildTimelineStep(
            'Reminder Dispatched',
            hasReminder 
                ? 'AI scheduled automated sms alert 1hr prior.'
                : 'Awaiting scheduling trigger.',
            isReminderDone ? 'Sent' : (hasReminder ? '+1 Hour' : '--:--'),
            isReminderDone,
            hasReminder && !isReminderDone,
            Icons.alarm_on_rounded,
            isReminderDone ? 'Sent' : 'Scheduled',
            const Color(0xFF3B82F6),
            primaryText,
            secondaryText,
            index: 1,
          ),
          _buildTimelineDivider(hasCompletion),

          // Step 3: Completion Check
          _buildTimelineStep(
            'Completion Check',
            hasCompletion 
                ? 'AI automated check to verify service completion.'
                : 'Awaiting dispatch confirmation.',
            isCompletionDone ? 'Done' : (hasCompletion ? '+2 Hours' : '--:--'),
            isCompletionDone,
            hasCompletion && !isCompletionDone,
            Icons.verified_outlined,
            isCompletionDone ? 'Verified' : 'Scheduled',
            const Color(0xFFEC4899),
            primaryText,
            secondaryText,
            index: 2,
          ),
          _buildTimelineDivider(hasRatingRequest),

          // Step 4: Rating Request
          _buildTimelineStep(
            'Rating Request',
            hasRatingRequest 
                ? 'Feedback prompt issued to customer.'
                : 'Awaiting completion check.',
            isRatingDone ? 'Received' : (hasRatingRequest ? 'Sent' : '--:--'),
            isRatingDone,
            hasRatingRequest && !isRatingDone,
            Icons.star_half_rounded,
            isRatingDone ? 'Rated' : 'Pending',
            Colors.amber,
            primaryText,
            secondaryText,
            index: 3,
          ),
          _buildTimelineDivider(isSentimentDone),

          // Step 5: Sentiment Analysis
          _buildTimelineStep(
            'Sentiment Analysis',
            isSentimentDone 
                ? 'AI audit: Detected ${sentiment.toUpperCase()} customer feedback.'
                : 'Awaiting user rating response.',
            isSentimentDone ? 'Processed' : '--:--',
            isSentimentDone,
            isRatingDone && !isSentimentDone,
            Icons.psychology_outlined,
            isSentimentDone ? sentiment.toUpperCase() : 'Waiting',
            isSentimentDone 
                ? (sentiment == 'positive' ? const Color(0xFF10B981) : (sentiment == 'negative' ? const Color(0xFFEF4444) : Colors.amber))
                : const Color(0xFF8B5CF6),
            primaryText,
            secondaryText,
            index: 4,
          ),
          _buildTimelineDivider(isEndWorkflowDone),

          // Step 6: Re-engagement OR Dispute Escalation
          _buildTimelineStep(
            isDispute ? 'Dispute Escalated' : 'Re-engagement Workflow',
            isDispute 
                ? 'Escalated to dispute workflow due to negative feedback.'
                : (isReEngagement 
                    ? 'Referral coupon and re-engagement code generated.'
                    : 'Workflow resolution decision path.'),
            isEndWorkflowDone ? 'Armed' : '--:--',
            isEndWorkflowDone,
            isSentimentDone && !isEndWorkflowDone,
            isDispute ? Icons.gavel_rounded : Icons.loyalty_rounded,
            isDispute ? 'DISPUTED' : (isReEngagement ? 'PROMOTED' : 'Pending'),
            isDispute ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
            primaryText,
            secondaryText,
            index: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider(bool active) {
    return Container(
      width: 1.5,
      height: 18,
      margin: const EdgeInsets.only(left: 17),
      color: active
          ? const Color(0xFF10B981)
          : (_isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
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
    Color secondary, {
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1.0 - value)),
            child: Row(
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
                            : (_isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
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
                          const SizedBox(width: 8),
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
                                  fontWeight: FontWeight.w900,
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
                                'Pending',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
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
            ),
          ),
        );
      },
    );
  }

  // 5. SENTIMENT ANALYSIS INSIGHT CARD
  Widget _buildSentimentSection(
    Map<String, dynamic> mainSession,
    String activeSessionId,
    Color primaryText,
    Color secondaryText,
  ) {
    final bool isSentimentComputed = mainSession.containsKey('sentiment') && mainSession['sentiment'] != null;
    final double? rating = mainSession['rating'] != null ? (mainSession['rating'] as num).toDouble() : null;
    final String feedback = mainSession['feedback'] as String? ?? '';
    final String sentiment = mainSession['sentiment'] as String? ?? 'neutral';

    Color sentimentColor = Colors.grey;
    String outcomeMessage = 'Monitoring Mode - Awaiting satisfaction rating from client.';

    if (isSentimentComputed) {
      if (sentiment == 'positive') {
        sentimentColor = const Color(0xFF10B981);
        outcomeMessage = 'Satisfaction Detected: POSITIVE → Re-engagement flow triggered (promo code dispatched).';
      } else if (sentiment == 'negative') {
        sentimentColor = const Color(0xFFEF4444);
        outcomeMessage = 'Satisfaction Detected: NEGATIVE → Dispute workflow triggered (admin alert dispatched).';
      } else {
        sentimentColor = Colors.amber;
        outcomeMessage = 'Satisfaction Detected: NEUTRAL → Ambient customer monitoring active.';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E28).withOpacity(0.4) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI SENTIMENT AUDITING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: secondaryText,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SpinningAiIndicator(),
                  ],
                ),
                const SizedBox(height: 14),

                if (!isSentimentComputed) ...[
                  // Simulator buttons if sentiment not yet computed
                  Text(
                    'No sentiment analysed yet. Choose a simulator preset below to experience real-time decision orchestration:',
                    style: TextStyle(fontSize: 12, color: secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSimulating 
                              ? null 
                              : () => _simulateFeedbackOrchestration(activeSessionId, 5.0, 'Excellent service! Ali arrived on time and fixed my wiring instantly. Highly professional.'),
                          icon: const Icon(Icons.thumb_up_alt_rounded, size: 14),
                          label: const Text('Simulate Positive'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSimulating 
                              ? null 
                              : () => _simulateFeedbackOrchestration(activeSessionId, 1.5, 'Terrible job! The provider charged me double, arrived 2 hours late and was very rude. I want a refund.'),
                          icon: const Icon(Icons.thumb_down_alt_rounded, size: 14),
                          label: const Text('Simulate Negative'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Interactive Scaling Capsule Row
                  _buildSentimentCapsules(sentiment),
                  const SizedBox(height: 16),
                  
                  // Text Feedback Quote
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'CLIENT FEEDBACK EVALUATION',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: secondaryText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 10,
                                  color: const Color(0xFFFBBF24),
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$feedback"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: _isDarkMode ? Colors.white.withOpacity(0.8) : const Color(0xFF1E2025).withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Action recommendation banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sentimentColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sentimentColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insights_rounded, size: 14, color: sentimentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            outcomeMessage,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: sentimentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Button to clear simulated response to test again
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('followups').doc('followup_$activeSessionId').update({
                            'rating': FieldValue.delete(),
                            'feedback': FieldValue.delete(),
                            'sentiment': FieldValue.delete(),
                            're_engagement_triggered': false,
                            'dispute_triggered': false,
                            'status': 'confirmed_followups_scheduled',
                          });

                          // Also delete corresponding actions
                          await FirebaseFirestore.instance.collection('followups').doc('followup_dispute_$activeSessionId').delete();
                          await FirebaseFirestore.instance.collection('followups').doc('followup_re_engagement_$activeSessionId').delete();
                          
                          _showPremiumSnackBar('Simulation reset! Feel free to choose another preset.');
                        } catch (e) {
                          _showPremiumSnackBar('Error resetting: $e', isError: true);
                        }
                      },
                      icon: const Icon(Icons.restore_rounded, size: 12, color: Color(0xFF8B5CF6)),
                      label: const Text(
                        'Reset Simulation',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. FOLLOW-UP TIMELINE TILES
  Widget _buildFollowUpTile(FollowUpUiModel item, int index) {
    final status = item.status.toLowerCase();
    final type = item.followupType.toLowerCase();
    final message = item.message;
    final followupId = item.followupId;

    // Aesthetic bindings
    Color typeColor = const Color(0xFF8B5CF6);
    IconData typeIcon = Icons.sms_rounded;
    String label = 'SMS ALERT';
    String decOutcome = 'Orchestrating scheduled check...';

    if (type.contains('reminder')) {
      typeColor = const Color(0xFF3B82F6);
      typeIcon = Icons.notifications_active_rounded;
      label = 'SERVICE REMINDER';
      decOutcome = 'Notify user about slot reservation 1hr in advance.';
    } else if (type.contains('completion')) {
      typeColor = const Color(0xFFEC4899);
      typeIcon = Icons.done_all_rounded;
      label = 'COMPLETION AUDIT';
      decOutcome = 'Request verification that provider completed job.';
    } else if (type.contains('rating')) {
      typeColor = Colors.amber;
      typeIcon = Icons.star_half_rounded;
      label = 'RATING ENQUIRY';
      decOutcome = 'Request satisfaction score (1-5) from customer.';
    } else if (type.contains('re_engagement')) {
      typeColor = const Color(0xFF10B981);
      typeIcon = Icons.local_activity_rounded;
      label = 'RE-ENGAGEMENT DISPATCH';
      decOutcome = 'Positive score detected. Distribute referral discount.';
    } else if (type.contains('dispute')) {
      typeColor = const Color(0xFFEF4444);
      typeIcon = Icons.warning_amber_rounded;
      label = 'DISPUTE TRIGGER';
      decOutcome = 'Negative sentiment captured. Initiate dispute ticket.';
    }

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_bottom_rounded;

    if (status == 'scheduled') {
      statusColor = const Color(0xFF8B5CF6);
      statusIcon = Icons.watch_later_rounded;
    } else if (status == 'sent') {
      statusColor = const Color(0xFF3B82F6);
      statusIcon = Icons.send_rounded;
    } else if (status == 'completed' || status == 'delivered') {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'pending') {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.hourglass_bottom_rounded;
    } else if (status == 'failed') {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error_rounded;
    }

    final timeStr = _formatReadableTimestamp(item.createdAt ?? item.scheduledAt);

    return TweenAnimationBuilder<double>(
      key: ValueKey(followupId),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(followupId),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          HapticFeedback.mediumImpact();
          _deleteFollowUp(followupId);
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Clearing record...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Clearing record...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_forever_rounded, color: Colors.white),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showCardDetailSheet(item, label, typeColor, typeIcon, decOutcome);
            },
            child: GlassCard(
              radius: 20,
              padding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(typeIcon, size: 14, color: typeColor),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 8, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white.withOpacity(0.9) : const Color(0xFF1E2025).withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, size: 10, color: Color(0xFFEC4899)),
                          const SizedBox(width: 4),
                          Text(
                            decOutcome,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: (_isDarkMode ? Colors.white38 : Colors.black45).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Card detailed modal sheet
  void _showCardDetailSheet(
    FollowUpUiModel item,
    String label,
    Color typeColor,
    IconData typeIcon,
    String decision,
  ) {
    final status = item.status.toUpperCase();
    final message = item.message;
    final bookingId = item.bookingId;
    final scheduledAt = item.scheduledAt;

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
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
                              ),
                            ),
                            Text(
                              'Recipient: Ali Ahmed (Customer)',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280),
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
                      message,
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
                      _buildDetailLabel('BOOKING ID', bookingId),
                      _buildDetailLabel('STATUS', status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailLabel('SCHEDULED FOR', scheduledAt != null ? _formatReadableTimestamp(scheduledAt) : 'Immediate'),
                      _buildDetailLabel('DELIVERY CHANNEL', 'SMS'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 16),
                  Text(
                    'ORCHESTRATION DECISION LOG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    decision,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: _isDarkMode ? Colors.white70 : const Color(0xFF4A4B50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message));
                            Navigator.pop(context);
                            _showPremiumSnackBar('Copied prompt message.');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Prompt'),
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
                            _deleteFollowUp(item.followupId);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Dismiss Event'),
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

  // 9. STICKY BOTTOM CTA
  Widget _buildBottomBar(String latestSession, Map<String, dynamic> mainSession, Color themeBg) {
    final bookingId = widget.bookingId ?? mainSession['booking_id'] ?? 'book_$latestSession';
    
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
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.push(
                          context,
                          _createSmoothPageRoute(
                            DisputeScreen(
                              sessionId: latestSession,
                              bookingId: bookingId,
                              customerId: 'user_customer_999',
                              providerId: 'provider_001',
                              bookingStatus: 'confirmed',
                              isDarkMode: _isDarkMode,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text('Open Dispute'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
                        Navigator.push(
                          context,
                          _createSmoothPageRoute(
                            TraceLogsScreen(
                              sessionId: latestSession,
                              bookingId: bookingId,
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
                            'Open Trace Logs',
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

  // 8. LOADING SHIMMER STATE
  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerOpacity = _shimmerController.value * 0.4 + 0.2;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Opacity(
              opacity: shimmerOpacity,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: shimmerOpacity,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: shimmerOpacity,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ERROR STATE
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

  // 7. EMPTY STATE
  Widget _buildEmptyState(Color secondaryText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
              Icons.repeat_rounded,
              size: 48,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No follow-up automation generated yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete booking repairs or trigger simulated AI dispatches to activate follow-up orchestrations.',
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

  Widget _buildAdvancedKpis(String sentiment, String status) {
    double successRate = 98.0;
    double completionRate = 85.0;
    double disputeRate = 5.0;
    double reEngageRate = 15.0;
    double positiveWeight = 0.60;
    double neutralWeight = 0.30;
    double negativeWeight = 0.10;

    if (sentiment == 'positive') {
      successRate = 99.5;
      completionRate = 100.0;
      disputeRate = 0.0;
      reEngageRate = 100.0;
      positiveWeight = 0.90;
      neutralWeight = 0.10;
      negativeWeight = 0.0;
    } else if (sentiment == 'negative') {
      successRate = 91.8;
      completionRate = 100.0;
      disputeRate = 100.0;
      reEngageRate = 0.0;
      positiveWeight = 0.0;
      neutralWeight = 0.10;
      negativeWeight = 0.90;
    } else if (sentiment == 'neutral') {
      successRate = 97.5;
      completionRate = 100.0;
      disputeRate = 0.0;
      reEngageRate = 0.0;
      positiveWeight = 0.10;
      neutralWeight = 0.80;
      negativeWeight = 0.10;
    }

    Widget kpiBar(String label, String value, double percent, Color color) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF9EA3B0)),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4,
              width: double.infinity,
              color: _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              child: Row(
                children: [
                  Expanded(
                    flex: (percent * 100).toInt(),
                    child: Container(color: color),
                  ),
                  Expanded(
                    flex: (100 - percent * 100).toInt(),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: kpiBar('AUTOMATION SUCCESS', '${successRate.toStringAsFixed(1)}%', successRate / 100, const Color(0xFF10B981))),
            const SizedBox(width: 20),
            Expanded(child: kpiBar('COMPLETION RATE', '${completionRate.toStringAsFixed(0)}%', completionRate / 100, const Color(0xFF8B5CF6))),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: kpiBar('DISPUTE TRIGGER', '${disputeRate.toStringAsFixed(1)}%', disputeRate / 100, const Color(0xFFEF4444))),
            const SizedBox(width: 20),
            Expanded(child: kpiBar('RE-ENGAGEMENT CONV.', '${reEngageRate.toStringAsFixed(1)}%', reEngageRate / 100, const Color(0xFF06B6D4))),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Colors.white10),
        const SizedBox(height: 12),
        
        // Sentiment Distribution Bar
        const Text(
          'SENTIMENT DISTRIBUTION',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF9EA3B0), letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            width: double.infinity,
            color: Colors.transparent,
            child: Row(
              children: [
                if (positiveWeight > 0)
                  Expanded(
                    flex: (positiveWeight * 100).toInt(),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                if (neutralWeight > 0)
                  Expanded(
                    flex: (neutralWeight * 100).toInt(),
                    child: Container(color: Colors.amber),
                  ),
                if (negativeWeight > 0)
                  Expanded(
                    flex: (negativeWeight * 100).toInt(),
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Positive ${(positiveWeight * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            Text('Neutral ${(neutralWeight * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.amber)),
            Text('Negative ${(negativeWeight * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
          ],
        ),
      ],
    );
  }

  Widget _buildSentimentCapsules(String activeSentiment) {
    Widget capsule(String type, IconData icon, String label, Color color, Gradient gradient) {
      final bool isActive = type == activeSentiment;

      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isActive ? gradient : null,
            color: isActive 
                ? null 
                : (_isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive 
                  ? color 
                  : (_isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
              width: isActive ? 2 : 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? Colors.white : color.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isActive) ...[
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(_pulseController.value * 0.6 + 0.4),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isActive ? Colors.white : color.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        capsule(
          'positive',
          Icons.sentiment_satisfied_alt_rounded,
          'POSITIVE',
          const Color(0xFF10B981),
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        ),
        const SizedBox(width: 10),
        capsule(
          'neutral',
          Icons.sentiment_neutral_rounded,
          'NEUTRAL',
          Colors.amber,
          const LinearGradient(colors: [Colors.amber, Color(0xFFD97706)]),
        ),
        const SizedBox(width: 10),
        capsule(
          'negative',
          Icons.sentiment_very_dissatisfied_rounded,
          'NEGATIVE',
          const Color(0xFFEF4444),
          const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        ),
      ],
    );
  }

  Widget _buildLiveBadges(Map<String, dynamic> mainSession, List<FollowUpUiModel> actions) {
    final status = (mainSession['status'] as String? ?? '').toLowerCase();
    final hasRating = mainSession.containsKey('rating') && mainSession['rating'] != null;
    final isDispute = mainSession['dispute_triggered'] == true || status == 'disputed';
    final isResolved = mainSession['re_engagement_triggered'] == true || status == 're_engaged';
    
    final bool aiActive = !isResolved && !isDispute; 
    final bool synced = true; 
    final bool waiting = !hasRating && !isDispute && !isResolved;
    final bool escalated = isDispute;
    final bool resolved = isResolved;

    Widget badge(String label, bool isActive, Color activeColor) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? activeColor.withOpacity(0.12) 
              : (_isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? activeColor.withOpacity(0.3) 
                : (_isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withOpacity(_pulseController.value * 0.6 + 0.4),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: _pulseController.value * 2,
                        )
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDarkMode ? Colors.white30 : Colors.black.withOpacity(0.3),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isActive 
                    ? (_isDarkMode ? Colors.white : const Color(0xFF1E2025))
                    : (_isDarkMode ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          badge('AI Active', aiActive, const Color(0xFF10B981)),
          const SizedBox(width: 8),
          badge('Synced', synced, const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          badge('Waiting', waiting, Colors.amber),
          const SizedBox(width: 8),
          badge('Escalated', escalated, const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          badge('Resolved', resolved, const Color(0xFF06B6D4)),
        ],
      ),
    );
  }

  Widget _buildJourneyMap(Map<String, dynamic> mainSession, List<FollowUpUiModel> actions) {
    final status = (mainSession['status'] as String? ?? '').toLowerCase();
    
    final bool stepBooking = true;
    final bool stepReminder = actions.any((a) => a.followupType.contains('reminder') && 
        (a.status == 'sent' || a.status == 'completed' || a.status == 'delivered'));
    final bool stepCompletion = actions.any((a) => a.followupType.contains('completion') && 
        (a.status == 'sent' || a.status == 'completed' || a.status == 'delivered'));
    final bool stepRating = mainSession.containsKey('rating') && mainSession['rating'] != null;
    final bool stepSentiment = mainSession.containsKey('sentiment') && mainSession['sentiment'] != null;
    final bool stepResolution = mainSession['re_engagement_triggered'] == true || 
        mainSession['dispute_triggered'] == true || status == 're_engaged' || status == 'disputed';

    int activeIndex = 0;
    if (stepResolution) {
      activeIndex = 5;
    } else if (stepSentiment) {
      activeIndex = 5;
    } else if (stepRating) {
      activeIndex = 4;
    } else if (stepCompletion) {
      activeIndex = 3;
    } else if (stepReminder) {
      activeIndex = 2;
    } else {
      activeIndex = 1;
    }

    final steps = [
      {'title': 'Booking', 'icon': Icons.receipt_long_rounded, 'done': stepBooking},
      {'title': 'Reminder', 'icon': Icons.alarm_on_rounded, 'done': stepReminder},
      {'title': 'Completion', 'icon': Icons.done_all_rounded, 'done': stepCompletion},
      {'title': 'Rating', 'icon': Icons.star_half_rounded, 'done': stepRating},
      {'title': 'Sentiment', 'icon': Icons.insights_rounded, 'done': stepSentiment},
      {'title': 'Resolution', 'icon': Icons.gavel_rounded, 'done': stepResolution},
    ];

    return GlassCard(
      radius: 20,
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI ORCHESTRATION JOURNEY MAP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9EA3B0),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP ${activeIndex + 1}/6',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final bool isCompleted = step['done'] as bool;
                final bool isActive = index == activeIndex;
                final IconData icon = step['icon'] as IconData;
                final String title = step['title'] as String;

                return Row(
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isCompleted
                                ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                                : (isActive 
                                    ? const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFFBBF24)])
                                    : null),
                            color: (!isCompleted && !isActive) 
                                ? (_isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
                                : null,
                            border: Border.all(
                              color: isCompleted
                                  ? Colors.transparent
                                  : (isActive ? const Color(0xFFEC4899) : (_isDarkMode ? Colors.white10 : Colors.black12)),
                              width: 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEC4899).withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : (isCompleted 
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : []),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              size: 15,
                              color: (isCompleted || isActive) 
                                  ? Colors.white 
                                  : (_isDarkMode ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: (isActive || isCompleted) ? FontWeight.bold : FontWeight.w600,
                            color: isActive
                                ? const Color(0xFFEC4899)
                                : (isCompleted 
                                    ? (_isDarkMode ? Colors.white70 : const Color(0xFF4A4B50)) 
                                    : (_isDarkMode ? Colors.white30 : Colors.black.withOpacity(0.3))),
                          ),
                        ),
                      ],
                    ),
                    
                    if (index < steps.length - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 15, left: 4, right: 4),
                        decoration: BoxDecoration(
                          gradient: isCompleted && (steps[index + 1]['done'] as bool)
                              ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                              : null,
                          color: !(isCompleted && (steps[index + 1]['done'] as bool))
                              ? (_isDarkMode ? Colors.white10 : Colors.black12)
                              : null,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentTracePreview(Map<String, dynamic> mainSession) {
    final bool isSentimentComputed = mainSession.containsKey('sentiment') && mainSession['sentiment'] != null;
    final String sentiment = mainSession['sentiment'] as String? ?? '';
    
    String decision = 'AWAITING_INPUT';
    String confidence = '0.0%';
    String reasoning = 'Orchestration pipeline active. Awaiting completion audit verification, satisfaction rating, and customer feedback events to trigger FollowUpAgent resolution rules.';
    List<String> actions = [];
    Color consoleColor = Colors.grey;

    if (isSentimentComputed) {
      if (sentiment == 'positive') {
        decision = 'LOYALTY_RE_ENGAGEMENT';
        confidence = '99.4%';
        reasoning = 'NLP analyzer classified feedback ("${mainSession['feedback']}") as POSITIVE (score: ${mainSession['rating'] ?? 5.0}/5.0). Auto-triggered re-engagement loyalty dispatch protocol.';
        actions = ['dispatch_promo_coupon', 'send_push_notification', 'log_agent_metrics'];
        consoleColor = const Color(0xFF10B981);
      } else if (sentiment == 'negative') {
        decision = 'DISPUTE_ESCALATION';
        confidence = '98.8%';
        reasoning = 'NLP analyzer classified feedback ("${mainSession['feedback']}") as NEGATIVE (score: ${mainSession['rating'] ?? 1.0}/5.0). Detected risk of user churn. Auto-triggered support ticket creation and customer support callback scheduling.';
        actions = ['open_dispute_ticket', 'alert_support_agents', 'dispatch_sms_apology'];
        consoleColor = const Color(0xFFEF4444);
      } else {
        decision = 'AMBIENT_MONITORING';
        confidence = '92.5%';
        reasoning = 'NLP analyzer classified feedback ("${mainSession['feedback']}") as NEUTRAL. No critical action trigger thresholds met. Logging metrics for database auditing.';
        actions = ['update_trace_db'];
        consoleColor = Colors.amber;
      }
    }

    return GlassCard(
      radius: 20,
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 14, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'FOLLOWUP_AGENT TRACE PREVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9EA3B0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (isSentimentComputed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: consoleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    confidence,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: consoleColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1015).withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
                    children: [
                      const TextSpan(text: '> DECISION: ', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold)),
                      TextSpan(text: decision, style: TextStyle(color: isSentimentComputed ? consoleColor : Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, height: 1.4),
                    children: [
                      const TextSpan(text: '> REASONING: ', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                      TextSpan(text: reasoning, style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '> ACTIONS:   ',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: actions.isEmpty
                            ? [
                                const Text(
                                  '[]',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white30),
                                )
                              ]
                            : actions.map((act) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                                  ),
                                  child: Text(
                                    act,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9,
                                      color: Color(0xFF06B6D4),
                                    ),
                                  ),
                                )).toList(),
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

  Widget _buildEmptyFeedState(Color secondaryText) {
    IconData icon = Icons.history_toggle_off_rounded;
    String title = 'No active alert items';
    String subtitle = 'Clear notifications or await scheduling intervals.';
    Color accentColor = const Color(0xFF8B5CF6);

    if (_selectedFilter == 'Disputes') {
      icon = Icons.verified_user_rounded;
      title = 'No active disputes';
      subtitle = 'Customer satisfaction audit shows zero unresolved service escalations.';
      accentColor = const Color(0xFF10B981);
    } else if (_selectedFilter == 'Reminders') {
      icon = Icons.notifications_off_rounded;
      title = 'No scheduled reminders';
      subtitle = 'All customer alerts have been successfully dispatched or cleared.';
      accentColor = const Color(0xFF3B82F6);
    } else if (_selectedFilter == 'Completion Checks') {
      icon = Icons.check_circle_outline_rounded;
      title = 'No completion checks pending';
      subtitle = 'Job execution audits are either completed or waiting to be scheduled.';
      accentColor = const Color(0xFFEC4899);
    } else if (_selectedFilter == 'Rating Requests') {
      icon = Icons.star_outline_rounded;
      title = 'No rating inquiries pending';
      subtitle = 'All feedback inquiries are resolved or waiting on completion triggers.';
      accentColor = Colors.amber;
    } else if (_selectedFilter == 'Re-engagement') {
      icon = Icons.local_activity_rounded;
      title = 'No loyalty actions queued';
      subtitle = 'Promotional codes and discounts will display here upon positive feedback scoring.';
      accentColor = const Color(0xFF06B6D4);
    }

    return GlassCard(
      radius: 20,
      padding: 24,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: accentColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _isDarkMode ? Colors.white : const Color(0xFF1E2025),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: secondaryText.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color primaryFocusColor() {
    return _isDarkMode ? Colors.white70 : const Color(0xFF4A4B50);
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
