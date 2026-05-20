import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/glass_card.dart';
import '../../agents/dispute_agent/dispute_agent_service.dart';
import '../../agents/dispute_agent/dispute_model.dart';

class DisputeScreen extends StatefulWidget {
  final String sessionId;
  final String bookingId;
  final String customerId;
  final String providerId;
  final String bookingStatus;
  final bool isDarkMode;

  const DisputeScreen({
    super.key,
    required this.sessionId,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.bookingStatus,
    required this.isDarkMode,
  });

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _feedbackController = TextEditingController();
  double _rating = 1.0;
  bool _isLoading = false;
  DisputeResponse? _disputeResult;
  String? _error;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (_feedbackController.text.trim().isEmpty) {
      setState(() {
        _error = "Please describe the issue before submitting.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _disputeResult = null;
    });

    try {
      final request = DisputeRequest(
        requestId: 'req_disp_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: widget.sessionId,
        bookingId: widget.bookingId,
        customerId: widget.customerId,
        providerId: widget.providerId,
        rating: _rating,
        feedback: _feedbackController.text.trim(),
        bookingStatus: widget.bookingStatus,
        createdAt: DateTime.now(),
      );

      final service = DisputeAgentService();
      final response = await service.processRequest(request);

      if (mounted) {
        setState(() {
          _disputeResult = response;
          _isLoading = false;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Dispute failed: ${e.toString()}";
          _isLoading = false;
        });
        HapticFeedback.vibrate();
      }
    }
  }

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
        title: Text(
          'Dispute Center',
          style: TextStyle(
            color: themePrimaryText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Raise a Transaction Dispute",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: themePrimaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Our automated Dispute Agent will audit the feedback, calculate appropriate provider penalty scores, and process refunds immediately.",
              style: TextStyle(
                fontSize: 13,
                color: themeSecondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service Quality Rating",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: themePrimaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          _rating >= starValue
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 38,
                          color: _rating >= starValue
                              ? const Color(0xFFFBBF24)
                              : themeSecondaryText.withOpacity(0.5),
                        ),
                        onPressed: _disputeResult != null
                            ? null
                            : () {
                                setState(() {
                                  _rating = starValue;
                                });
                                HapticFeedback.selectionClick();
                              },
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      "Rating selected: ${_rating.toStringAsFixed(0)} / 5",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Describe What Happened",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: themePrimaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    enabled: _disputeResult == null && !_isLoading,
                    style: TextStyle(color: themePrimaryText, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Enter details (e.g. overcharging, rude behavior, poor service quality)...",
                      hintStyle: TextStyle(color: themeSecondaryText.withOpacity(0.6)),
                      filled: true,
                      fillColor: widget.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              )
            else if (_disputeResult != null)
              _buildDisputeResultCard()
            else
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _submitDispute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Submit Dispute Audit",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
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

  Widget _buildDisputeResultCard() {
    final res = _disputeResult!;
    final themePrimaryText = widget.isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = widget.isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 10),
              Text(
                "Audit Report Generated",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: themePrimaryText,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          _buildResultItem("Dispute ID", res.disputeCase.disputeId),
          _buildResultItem("Severity Detect", res.disputeCase.severity.toUpperCase()),
          _buildResultItem("Dispute Category", res.disputeCase.category.toUpperCase()),
          _buildResultItem("Status Code", res.orchestrationStatus.toUpperCase()),
          _buildResultItem("Refund Percentage", "${res.resolutionRecommendation.refundPercentage.toStringAsFixed(0)}%"),
          _buildResultItem("Provider Penalty Score", "${res.resolutionRecommendation.providerPenalty.toStringAsFixed(1)} Strike"),
          _buildResultItem("Escalation Risk", res.escalationMetadata.isEscalated ? "ESCALATED TO HUMAN SUPPORT" : "AUTO-RESOLVED"),
          const SizedBox(height: 16),
          Text(
            "Recommended Action:",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: themeSecondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            res.resolutionRecommendation.recommendedAction.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Return to Booking Screen",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    final themePrimaryText = widget.isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = widget.isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: themeSecondaryText),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themePrimaryText),
          ),
        ],
      ),
    );
  }
}
