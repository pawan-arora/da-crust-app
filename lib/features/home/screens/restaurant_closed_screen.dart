import 'dart:async';

import 'package:da_crust_app/core/constants/app_assets.dart';
import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:da_crust_app/core/widgets/pill_button.dart';
import 'package:da_crust_app/core/widgets/rounded_network_image.dart';
import 'package:da_crust_app/features/home/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;

const _gold = Color(0xFFF5E6C8);
const _accentGreen = Color(0xFF10B981);
const _accentTerracotta = Color(0xFFE76F51);

/// Shown at the '/' entry point instead of [WelcomeScreen] whenever the
/// restaurant has been manually marked closed in Firestore.
class RestaurantClosedScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  final tz.TZDateTime? nextOpeningDate;

  const RestaurantClosedScreen({
    super.key,
    required this.restaurantData,
    required this.nextOpeningDate,
  });

  @override
  State<RestaurantClosedScreen> createState() => _RestaurantClosedScreenState();
}

class _RestaurantClosedScreenState extends State<RestaurantClosedScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.nextOpeningDate != null) {
      _updateRemaining();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _updateRemaining();
      });
    }
  }

  void _updateRemaining() {
    final diff = widget.nextOpeningDate!.difference(DateTimeUtils.getNzTime());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _getFullAddress() {
    final address = widget.restaurantData?['address'] as Map<String, dynamic>?;
    if (address == null) return "";

    final street = address['street'] ?? "";
    final city = address['city'] ?? "";
    final postalCode = address['postalCode'] ?? "";

    return "$street, $city $postalCode".trim();
  }

  @override
  Widget build(BuildContext context) {
    final logo = widget.restaurantData?['logo'] as String?;
    final name = widget.restaurantData?['name'] ?? "Da Crust";
    final aboutText = widget.restaurantData?['about'] as String? ?? "";
    final closedMessage =
        widget.restaurantData?['closedMessage'] as String? ??
        "We're closed for a short period. We're genuinely sorry for the "
            "inconvenience — online ordering is paused until we reopen. "
            "Thank you for your patience and support; we can't wait to "
            "serve you again.";
    final fullAddress = _getFullAddress();
    final isMobile = MediaQuery.sizeOf(context).shortestSide < 600;
    final nextOpeningDate = widget.nextOpeningDate;
    final reopenChipText = nextOpeningDate != null
        ? "Reopening ${DateTimeUtils.formatOpeningDateChip(nextOpeningDate)}"
        : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            isMobile
                ? AppAssets.welcomeBackgroundMobile
                : AppAssets.welcomeBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),

          // Dark overlay
          Container(color: const Color.fromRGBO(15, 23, 42, 0.72)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      48,
                ),
                // 🌟 Spacer/Expanded need bounded constraints, which a
                // SingleChildScrollView never gives its child (that's what
                // makes it scrollable) — using them here throws "RenderBox
                // was not laid out". Center + a min-height constraint gets
                // the same "fill the screen, but scroll if content is
                // taller" behavior without them.
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),

                      // ========== LOGO ==========
                      if (logo != null && logo.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                          ),
                          child: RoundedNetworkImage(
                            imageUrl: logo,
                            width: 64,
                            height: 64,
                            borderRadius: 50,
                            loaderStrokeWidth: 2,
                            errorWidget: const Icon(
                              Icons.storefront,
                              size: 28,
                              color: Colors.white54,
                            ),
                          ),
                        ),

                      const SizedBox(height: 18),

                      // ========== TITLE ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: _gold,
                            height: 1.15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ========== ADDRESS ==========
                      if (fullAddress.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 15,
                              color: _accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                fullAddress,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: _gold.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // ========== TEMPORARILY CLOSED BADGE ==========
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentTerracotta.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _accentTerracotta.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "TEMPORARILY CLOSED",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _accentTerracotta,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ========== CLOSED HEADING ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "We've stepped away for a little while",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: _gold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ========== CLOSED MESSAGE ==========
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          closedMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: _gold.withValues(alpha: 0.82),
                          ),
                        ),
                      ),

                      // ========== LIVE COUNTDOWN ==========
                      if (nextOpeningDate != null) ...[
                        const SizedBox(height: 24),
                        _CountdownRow(remaining: _remaining),
                      ],

                      // ========== NEXT OPENING DATE CHIP ==========
                      if (reopenChipText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _accentGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _accentGreen.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 15,
                                  color: _accentGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reopenChipText,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: _accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // ========== BUTTON ==========
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: SizedBox(
                          width: 160,
                          child: PillButton(
                            text: "About Us",
                            isPrimary: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AboutScreen(
                                    aboutText: aboutText,
                                    restaurantName: name,
                                  ),
                                ),
                              );
                            },
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
  }
}

class _CountdownRow extends StatelessWidget {
  final Duration remaining;

  const _CountdownRow({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CountdownBox(value: days, label: "DAYS"),
        const SizedBox(width: 10),
        _CountdownBox(value: hours, label: "HOURS"),
        const SizedBox(width: 10),
        _CountdownBox(value: minutes, label: "MINS"),
        const SizedBox(width: 10),
        _CountdownBox(value: seconds, label: "SECS"),
      ],
    );
  }
}

class _CountdownBox extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: _gold.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
