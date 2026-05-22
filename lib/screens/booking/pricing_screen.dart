import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/provider.dart' as app_models;
import '../../agents/pricing_agent/pricing_model.dart';
import '../../agents/supervisor_agent/supervisor_agent_service.dart';
import '../../ui/theme.dart';
import 'widgets/provider_card.dart';
import 'widgets/price_breakdown.dart';
import 'booking_screen.dart';
import '../../ui/widgets/app_gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';

class PricingScreen extends StatefulWidget {
  final app_models.Provider provider;
  final String sessionId;
  final String requestId;
  final String userId;
  final String serviceType;
  final bool isDarkMode;

  const PricingScreen({
    super.key,
    required this.provider,
    required this.sessionId,
    required this.requestId,
    required this.userId,
    required this.serviceType,
    required this.isDarkMode,
  });

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isCalculating = true;
  bool _hasError = false;
  bool _isNavigating = false;
  String? _errorMessage;
  PricingResponse? _pricingResponse;

  @override
  void initState() {
    super.initState();
    _calculatePricing();
  }

  Future<void> _calculatePricing() async {
    try {
      final supervisor = SupervisorAgentService();
      final response = await supervisor.calculatePricing(
        sessionId: widget.sessionId,
        requestId: widget.requestId,
        userId: widget.userId,
        serviceType: widget.serviceType,
        providerId: widget.provider.providerId,
        providerName: widget.provider.name,
        distanceKm: widget.provider.distanceKm,
        // Optional metadata from provider
        providerMetadata: {
          'rating': widget.provider.rating,
          'reliability': widget.provider.reliabilityScore,
        },
      );

      if (mounted) {
        setState(() {
          _pricingResponse = response;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isCalculating = false;
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
        HapticFeedback.vibrate();
      }
    }
  }

  void _scheduleAppointment() {
    if (_pricingResponse == null || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    HapticFeedback.heavyImpact();

    print("Navigating to Booking Screen");
    print(widget.sessionId);
    print(widget.provider.name);
    print(_pricingResponse!.pricingData.totalPricePkr);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            sessionId: widget.sessionId,
            userId: widget.userId,
            serviceType: widget.serviceType,
            pricingResponse: _pricingResponse!,
            provider: widget.provider,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = widget.isDarkMode ? const Color(0xFF0F0F13) : const Color(0xFFF9FAFB);
    final themePrimaryText = widget.isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final themeSecondaryText = widget.isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themePrimaryText),
        title: Text(
          'Review Pricing',
          style: GoogleFonts.poppins(color: themePrimaryText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isCalculating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: BolDoTheme.primary),
                  SizedBox(height: 16),
                  Text('PricingAgent is calculating dynamic pricing...', style: TextStyle(color: BolDoTheme.textSecondary)),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 16),
                        Text('Pricing Calculation Failed', style: TextStyle(fontSize: 20, color: themePrimaryText, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_errorMessage ?? 'Unknown error', style: TextStyle(color: themeSecondaryText), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProviderCard(
                        providerName: widget.provider.name,
                        serviceType: widget.serviceType,
                        rating: widget.provider.rating,
                        isDarkMode: widget.isDarkMode,
                      ),
                      const SizedBox(height: 24),
                      if (_pricingResponse != null)
                        PriceBreakdown(
                          totalPrice: _pricingResponse!.pricingData.totalPricePkr,
                          confidence: _pricingResponse!.pricingData.confidenceScore,
                          breakdown: _pricingResponse!.pricingData.breakdown,
                          isDarkMode: widget.isDarkMode,
                        ),
                      const SizedBox(height: 40),
                      AppGradientButton(
                        text: 'CONTINUE BOOKING',
                        isLoading: _isNavigating,
                        onPressed: _scheduleAppointment,
                      ),
                    ],
                  ),
                ),
    );
  }
}
