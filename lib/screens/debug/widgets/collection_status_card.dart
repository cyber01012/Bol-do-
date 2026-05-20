import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../booking/widgets/glass_card.dart';

class CollectionStatusCard extends StatefulWidget {
  final String collectionName;
  final String displayName;
  final IconData icon;

  const CollectionStatusCard({
    super.key,
    required this.collectionName,
    required this.displayName,
    required this.icon,
  });

  @override
  State<CollectionStatusCard> createState() => _CollectionStatusCardState();
}

class _CollectionStatusCardState extends State<CollectionStatusCard> {
  bool _isExpanded = false;
  late final Stream<QuerySnapshot> _collectionStream;

  @override
  void initState() {
    super.initState();
    // Cache the stream to avoid re-subscribing on rebuilds
    _collectionStream = FirebaseFirestore.instance.collection(widget.collectionName).snapshots();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '--:--:--';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate().toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
    if (timestamp is String) {
      try {
        final dt = DateTime.parse(timestamp).toLocal();
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    return '--:--:--';
  }

  dynamic _findLatestTimestamp(List<QueryDocumentSnapshot> docs) {
    dynamic latest;
    DateTime? latestDt;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final fields = ['created_at', 'timestamp', 'updated_at', 'requested_time', 'scheduled_time', 'last_updated'];
      for (final f in fields) {
        if (data.containsKey(f) && data[f] != null) {
          final val = data[f];
          DateTime? dt;
          if (val is Timestamp) {
            dt = val.toDate();
          } else if (val is String) {
            dt = DateTime.tryParse(val);
          }
          if (dt != null) {
            if (latestDt == null || dt.isAfter(latestDt)) {
              latestDt = dt;
              latest = val;
            }
          }
        }
      }
    }
    return latest;
  }

  String _extractOrchestrationStatus(Map<String, dynamic> data) {
    // Common keys for statuses in BolDo AI
    final statusKeys = [
      'pipeline_status',
      'booking_status',
      'status',
      'orchestration_status'
    ];
    for (final key in statusKeys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key].toString();
      }
    }
    return 'unknown';
  }

  bool _checkFailureState(Map<String, dynamic> data) {
    // Check if the document state represents a failure or escalation
    final status = _extractOrchestrationStatus(data).toLowerCase();
    if (status.contains('failed') || status.contains('reject') || status.contains('escalat') || status.contains('error')) {
      return true;
    }
    
    // Check escalation metadata
    if (data.containsKey('escalation_metadata')) {
      final esc = data['escalation_metadata'] as Map? ?? {};
      if (esc['is_escalated'] == true) return true;
    }
    if (data.containsKey('is_fallback')) {
      if (data['is_fallback'] == true) return true;
    }
    if (data.containsKey('fallback_triggered')) {
      if (data['fallback_triggered'] == true) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePrimaryText = isDark ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = isDark ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return StreamBuilder<QuerySnapshot>(
      stream: _collectionStream,
      builder: (context, snapshot) {
        // 1. Error State
        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: 16.0,
              radius: 20.0,
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: const Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themePrimaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 2. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: 16.0,
              radius: 20.0,
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themePrimaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connecting to Firestore collection...',
                          style: TextStyle(fontSize: 10, color: themeSecondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final docCount = docs.length;

        // 3. Empty State
        if (docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: 16.0,
              radius: 20.0,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 18, color: themeSecondaryText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.displayName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themePrimaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Collection empty (0 documents)',
                          style: TextStyle(fontSize: 10, color: themeSecondaryText, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Find latest update time and document details
        final latestTimeObj = _findLatestTimestamp(docs);
        final formattedTime = _formatTimestamp(latestTimeObj);

        // Sort docs for preview to show latest first
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          final aTime = _findLatestTimestamp([a]);
          final bTime = _findLatestTimestamp([b]);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          DateTime? aDt = aTime is Timestamp ? aTime.toDate() : DateTime.tryParse(aTime.toString());
          DateTime? bDt = bTime is Timestamp ? bTime.toDate() : DateTime.tryParse(bTime.toString());
          if (aDt == null || bDt == null) return 0;
          return bDt.compareTo(aDt); // Descending order
        });

        final latestDoc = sortedDocs.first;
        final latestData = latestDoc.data() as Map<String, dynamic>? ?? {};
        final orchestrationStatus = _extractOrchestrationStatus(latestData);
        
        // Check if any document in the entire collection has a failure state
        bool collectionHasFailure = false;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>? ?? {};
          if (_checkFailureState(d)) {
            collectionHasFailure = true;
            break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: 16.0,
            radius: 20.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: collectionHasFailure 
                              ? const Color(0xFFEF4444)
                              : (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF6366F1)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: themePrimaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Status: ',
                                  style: TextStyle(fontSize: 9, color: themeSecondaryText),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: collectionHasFailure
                                        ? const Color(0xFFEF4444).withOpacity(0.1)
                                        : const Color(0xFF8B5CF6).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    orchestrationStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: collectionHasFailure ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: collectionHasFailure
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                collectionHasFailure ? 'ALERT' : 'NOMINAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: collectionHasFailure
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$docCount docs • Update: $formattedTime',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: themeSecondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: themeSecondaryText,
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  const Divider(height: 24, color: Colors.white24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDocs.length > 3 ? 3 : sortedDocs.length,
                    itemBuilder: (context, idx) {
                      final doc = sortedDocs[idx];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final dataString = const JsonEncoder.withIndent('  ').convert(data);
                      final isDocFailed = _checkFailureState(data);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDocFailed
                                ? const Color(0xFFEF4444).withOpacity(0.3)
                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'ID: ${doc.id}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDocFailed
                                          ? const Color(0xFFEF4444)
                                          : (isDark ? const Color(0xFFEC4899) : const Color(0xFFDB2777)),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${idx + 1} of $docCount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: themeSecondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0C0C0E) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dataString,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
