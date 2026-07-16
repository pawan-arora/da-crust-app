import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RestaurantService {
  static final RestaurantService instance = RestaurantService._internal();
  RestaurantService._internal();

  Map<String, dynamic>? _cachedData;

  Future<Map<String, dynamic>?> fetchRestaurantData() async {
    if (_cachedData != null) return _cachedData;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurant')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _cachedData = snapshot.docs.first.data();
        return _cachedData;
      }
    } catch (e) {
      debugPrint("Error fetching restaurant data: $e");
    }
    return null;
  }

  // ========== CLEAN GETTERS ==========

  String get name {
    return _cachedData?['name'] as String? ?? "Da Crust";
  }

  String get about {
    return _cachedData?['about'] as String? ?? "";
  }

  String? get welcomeImage {
    return _cachedData?['welcomeImage'] as String?;
  }

  String? get logo {
    return _cachedData?['logo'] as String?;
  }

  String? get facebookUrl {
    return _cachedData?['facebookUrl'] as String?;
  }

  String get fullAddress {
    final address = _cachedData?['address'] as Map<String, dynamic>?;
    if (address == null) return "";

    final street = address['street'] ?? "";
    final city = address['city'] ?? "";
    final postalCode = address['postalCode'] ?? "";

    return "$street, $city $postalCode".trim();
  }

  String get phone {
    final contact = _cachedData?['contact'] as Map<String, dynamic>?;
    return contact?['phone'] as String? ?? "";
  }

  String get email {
    final contact = _cachedData?['contact'] as Map<String, dynamic>?;
    return contact?['email'] as String? ?? "";
  }

  Map<String, dynamic>? get openingHours {
    return _cachedData?['openingHourse'] as Map<String, dynamic>?;
  }

  Map<String, dynamic>? get cachedData => _cachedData;

  /// Call this once at app start (optional but recommended)
  Future<void> init() async {
    await fetchRestaurantData();
  }

  Future<Map<String, dynamic>?> fetchOpeningHours() async {
  final data = await fetchRestaurantData();
  return data?['openingHourse'] as Map<String, dynamic>?;
}
}

