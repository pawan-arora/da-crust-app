import 'package:da_crust_app/core/constants/app_assets.dart';
import 'package:da_crust_app/core/widgets/pill_button.dart';
import 'package:da_crust_app/core/widgets/rounded_network_image.dart';
import 'package:da_crust_app/features/home/screens/about_screen.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:da_crust_app/features/home/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

bool hasHomeScreenInitialized = false;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? restaurantData;
  bool isDataLoading = true;
  bool showContent = false;

  final Color accentGreen = const Color(0xFF10B981);
  //final Color allGold = const Color(0xFFD4A373);
  final Color amberShade = Colors.amber.shade50;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (!hasHomeScreenInitialized) {
      _startSequence();
    } else {
      // Already initialized before → skip animation
      restaurantData = RestaurantService.instance.cachedData;
      isDataLoading = false;
      showContent = true;
    }
  }

  Future<void> _startSequence() async {
    final dataFuture = RestaurantService.instance.fetchRestaurantData();

    // Let background show first
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Start fade animation
    await _fadeController.forward();

    final data = await dataFuture;

    if (mounted) {
      setState(() {
        restaurantData = data;
        isDataLoading = false;
        showContent = true;
        _fadeController.value = 0.78;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getFullAddress() {
    final address = restaurantData?['address'] as Map<String, dynamic>?;
    if (address == null) return "";

    final street = address['street'] ?? "";
    final city = address['city'] ?? "";
    final postalCode = address['postalCode'] ?? "";

    return "$street, $city $postalCode".trim();
  }

  @override
  Widget build(BuildContext context) {
    if (hasHomeScreenInitialized) {
      return const HomeScreen();
    }

    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.50).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    //final welcomeImage = restaurantData?['welcomeImage'] as String?;
    final logo = restaurantData?['logo'] as String?;
    final name = restaurantData?['name'] ?? "Da Crust";
    final aboutText = restaurantData?['about'] as String? ?? "";
    final fullAddress = _getFullAddress();
    //final screenWidth = MediaQuery.of(context).size.width;
    //final buttonWidth = (screenWidth) / 1.5; // Adjusted for better spacing on smaller screens

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(AppAssets.welcomeBackground_2, fit: BoxFit.cover),

          // Dark overlay
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: Color.fromRGBO(15, 23, 42, _fadeAnimation.value),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(
                  flex: 2,
                ), // pushes content down a bit like the image
                // ========== LOGO ==========
                if (showContent && logo != null && logo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF5E6C8).withValues(alpha: 0.85),
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

                // ========== TITLE (matches the screenshot font + size) ==========
                if (showContent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      // Force the exact two-line look from the image
                      "Da Crust Pizzeria &\nIndian Restaurant",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 34, // large like the image
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF5E6C8), // creamy gold
                        height: 1.15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // ========== ADDRESS ==========
                if (showContent && fullAddress.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 15,
                        color: const Color(0xFF10B981), // same green
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fullAddress,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: const Color(
                            0xFFF5E6C8,
                          ).withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                const Spacer(
                  flex: 6,
                ), // big space so buttons sit near the bottom like the image
                // ========== BUTTONS ==========
                if (showContent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // About Us
                        SizedBox(
                          width: 140,
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
                        const SizedBox(width: 14),
                        // ORDER NOW
                        SizedBox(
                          width: 140,
                          child: PillButton(
                            text: "ORDER NOW",
                            isPrimary: true,
                            onTap: () {
                              hasHomeScreenInitialized = true;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
