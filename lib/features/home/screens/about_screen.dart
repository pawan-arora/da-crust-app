import 'package:da_crust_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  final String aboutText;
  final String restaurantName;

  const AboutScreen({
    super.key,
    required this.aboutText,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    const Color allGold = Color(0xFFD4A373);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (same as Welcome screen)
          Image.asset(
            AppAssets.pizzaBackground,
            fit: BoxFit.cover,
          ),

          // Dark elegant overlay
          Container(
            color: const Color.fromRGBO(15, 23, 42, 0.88),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white,
                      ),
                      const Expanded(
                        child: Text(
                          "About Us",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balances the back button
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant Name
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: allGold,
                            height: 1.3,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Container(
                          width: 50,
                          height: 3,
                          decoration: BoxDecoration(
                            color: allGold.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // About Text
                        Text(
                          aboutText,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.7,
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ],
                    ),
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