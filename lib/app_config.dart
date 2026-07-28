//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Singleton Setup
  static final AppConfig instance = AppConfig._internal();
  AppConfig._internal();

  double cardSurchargeRate = 0.02; // Default 2%
  double taxRate = 0.15;           // Default 15% GST
  //bool isStoreOpen = true;         // Default Open

  /// Fetches the latest settings from Firestore
  Future<void> init() async {
    try {
      // final docSnapshot = await FirebaseFirestore.instance
      //     .collection('config')
      //     .doc('app_settings')
      //     .get()
      //     .timeout(const Duration(seconds: 5));

      // if (docSnapshot.exists && docSnapshot.data() != null) {
      //   final data = docSnapshot.data()!;
        
      //   // Safely parse the numbers (Firestore sometimes returns ints as doubles and vice versa)
      //   cardSurchargeRate = (data['cardSurchargeRate'] ?? 0.02).toDouble();
      //   taxRate = (data['taxRate'] ?? 0.15).toDouble();
      //   //isStoreOpen = data['isStoreOpen'] ?? true;
        
      //   debugPrint("✅ AppConfig Loaded: Surcharge is ${cardSurchargeRate * 100}%");
      // }
    } catch (e) {
      // If fetching fails, it silently falls back to the safe defaults above
      debugPrint("⚠️ Failed to load AppConfig, using defaults. Error: $e");
    }
  }
}