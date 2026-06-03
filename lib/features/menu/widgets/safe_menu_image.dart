import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SafeMenuImage extends StatelessWidget {
  final String imagePath; // This now expects the full https:// URL from Firestore
  final double height;
  final double width;
  const SafeMenuImage({
    super.key,
    required this.imagePath,
    this.height = 140,
    this.width = double.infinity
  });

  @override
  Widget build(BuildContext context) {
    // Safety check: Make sure we actually have a valid HTTP URL
    if (imagePath.isEmpty || !imagePath.startsWith('http')) {
      return _fallback(
        reason: "Invalid or empty URL", 
        error: null, 
        url: imagePath,
      );
    }

    return CachedNetworkImage(
      imageUrl: imagePath,
      height: height,
      width: width,
      fit: BoxFit.cover,
      
      placeholder: (_, _) => _loading(),
      
      errorWidget: (_, _, error) => _fallback(
        reason: "CachedNetworkImage error",
        error: error,
        url: imagePath,
      ),
    );
  }

  /// -------------------------
  /// LOADING
  /// -------------------------
  Widget _loading() {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// -------------------------
  /// FALLBACK + LOGGING
  /// -------------------------
  Widget _fallback({
    required String reason,
    required dynamic error,
    required String? url,
  }) {
    debugPrint("❌ Image Load Failed");
    debugPrint("🌐 URL: $url");
    debugPrint("⚠️ Reason: $reason");
    if (error != null) debugPrint("🔥 Error: $error");

    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
      ),
    );
  }
}