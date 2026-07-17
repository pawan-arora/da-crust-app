import 'package:da_crust_app/core/constants/app_assets.dart';
import 'package:da_crust_app/core/widgets/pill_button.dart';
import 'package:da_crust_app/core/widgets/rounded_network_image.dart';
import 'package:da_crust_app/features/home/screens/about_screen.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:da_crust_app/features/home/screens/home_screen.dart';

bool hasWelcomeScreenInitialized = false;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.78).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    if (!hasWelcomeScreenInitialized) {
      _startSequence();
    } else {
      restaurantData = RestaurantService.instance.cachedData;
      isDataLoading = false;
      showContent = true;
      _fadeController.value = 0.78;
    }
  }

  Future<void> _startSequence() async {
    final dataFuture = RestaurantService.instance.fetchRestaurantData();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await _fadeController.forward();

    final data = await dataFuture;

    if (mounted) {
      setState(() {
        restaurantData = data;
        isDataLoading = false;
        showContent = true;
        hasWelcomeScreenInitialized = true;
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
    final welcomeImage = restaurantData?['welcomeImage'] as String?;
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
          Image.asset(AppAssets.pizzaBackground, fit: BoxFit.cover),

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
                const SizedBox(height: 20),

                // ========== TOP SECTION: Logo + Name + Address ==========
                if (showContent) ...[
                  // Logo
                  if (logo != null && logo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: amberShade.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: RoundedNetworkImage(
                        imageUrl: logo,
                        width: 68,
                        height: 68,
                        borderRadius: 50, // makes it perfectly circular
                        loaderStrokeWidth: 2,
                        errorWidget: const Icon(
                          Icons.storefront,
                          size: 30,
                          color: Colors.white54,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Restaurant Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade50,
                        letterSpacing: 0.2,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Address with icon
                  if (fullAddress.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: accentGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          fullAddress,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.amber.shade50.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 22),

                // ========== RESTAURANT IMAGE ==========
                Expanded(
                  child: AnimatedOpacity(
                    opacity: showContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth:
                              920, // higher limit, looks good on desktop
                        ),
                        child: RoundedNetworkImage(
                          imageUrl: welcomeImage,
                          borderRadius: 20,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: const Icon(
                            Icons.storefront,
                            size: 70,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                // ========== BUTTONS ==========
                if (showContent)
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;

                      // 38% of screen width, but never smaller than 130 or larger than 170
                      final buttonWidth = (screenWidth * 0.38).clamp(
                        130.0,
                        170.0,
                      );

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // About Us
                            SizedBox(
                              width: buttonWidth,
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

                            // Order Now
                            SizedBox(
                              width: buttonWidth,
                              child: PillButton(
                                text: "ORDER NOW",
                                isPrimary: true,
                                onTap: () {
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
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
