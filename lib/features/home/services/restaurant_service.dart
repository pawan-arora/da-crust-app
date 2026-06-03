import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantService {
  static final RestaurantService instance = RestaurantService._internal();
  RestaurantService._internal();

  // 🌟 NEW: The cache! This holds the data in memory so we don't spam Firebase.
  Map<String, dynamic>? _cachedData;

  /// Fetches the entire restaurant document (uses cache if available)
  Future<Map<String, dynamic>?> fetchRestaurantData() async {
    // If we already downloaded this during the session, return it instantly!
    if (_cachedData != null) return _cachedData;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('restaurant').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        _cachedData = snapshot.docs.first.data();
        return _cachedData;
      }
    } catch (e) {
      debugPrint("Error fetching restaurant data: ${e.toString()}");
    }
    return null;
  }

  /// Helper for widgets that only specifically need the opening hours
  Future<Map<String, dynamic>?> fetchOpeningHours() async {
    final data = await fetchRestaurantData();
    return data?['openingHourse'] as Map<String, dynamic>?;
  }
}