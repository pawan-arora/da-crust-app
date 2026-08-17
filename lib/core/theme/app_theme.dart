import 'package:flutter/material.dart';

class AppTheme {
  // ----------------------------------------
  // ☀️ LIGHT THEME (Emerald & Terracotta)
  // ----------------------------------------
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    
    // A slightly warmer off-white background (Cream/Alabaster) instead of sterile grey
    scaffoldBackgroundColor: const Color(0xFFFCFBF8), 
    
    // The Modern Green (Deep Emerald)
    primaryColor: const Color(0xFF059669), 
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF059669),     // Deep Emerald (Main brand color)
      secondary: Color(0xFFE76F51),   // Terracotta/Coral (Warm accent for badges/offers)
      surface: Colors.white,
      onSurface: Color(0xFF1F2937),   // Soft charcoal for readable text
      surfaceContainerHighest: Color(0xFFF3F4F6), // subtle grey for disabled states
    ),

    // 🧾 Cards: Clean white with a very delicate shadow
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white, 
      elevation: 2, 
      shadowColor: Colors.black.withValues(alpha: 0.06), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),

    // 🔘 Buttons: Deep green borders with clean white interiors
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF059669),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
          side: const BorderSide(color: Color(0xFF059669), width: 1.5),
        ),
      ),
    ),

    // ⌨️ Search Bar & Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade200), // Very subtle resting border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5), // Pops green when typing
      ),
    ),

    // 🔝 AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: false,
    ),

    // 🔤 Typography
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
    ),
  );

  // ----------------------------------------
  // 🌙 DARK THEME (Cleaned up!)
  // ----------------------------------------
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    
    // A rich, dark slate background (better than pure black)
    scaffoldBackgroundColor: const Color(0xFF121212), 
    primaryColor: const Color(0xFF10B981), // Brighter mint-green for dark mode visibility

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981),
      secondary: Color(0xFFF4A261), // Soft peach accent for dark mode
      surface: Color(0xFF1E1E1E), // Slightly elevated card color
      onSurface: Color(0xFFE5E7EB), // Off-white text
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2D2D2D), width: 1),
      ),
    ),
  );
}