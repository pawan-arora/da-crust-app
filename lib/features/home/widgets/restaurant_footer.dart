import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantFooter extends StatefulWidget {
  const RestaurantFooter({super.key});

  @override
  State<RestaurantFooter> createState() => _RestaurantFooterState();
}

class _RestaurantFooterState extends State<RestaurantFooter> {
  Map<String, dynamic>? _restaurantData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFooterData();
  }

  Future<void> _loadFooterData() async {
    final data = await RestaurantService.instance.fetchRestaurantData();
    if (mounted) {
      setState(() {
        _restaurantData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchFacebook(String urlString) async {
    if (urlString.isEmpty) return;
    
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Could not launch Facebook: $e');
    }
  }

  String _formatTimeRange(Map<String, dynamic>? dayData) {
    if (dayData == null || dayData['open'] == null || dayData['close'] == null) {
      return "Closed";
    }

    String formatTime(String time) {
      final parts = time.split(':');
      if (parts.length != 2) return time;
      
      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      
      hour = hour % 12;
      if (hour == 0) hour = 12; 
      
      return '$hour:$minute $ampm';
    }

    return '${formatTime(dayData['open'])} – ${formatTime(dayData['close'])}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurantData == null) {
      return const SizedBox.shrink(); 
    }

    final name = _restaurantData!['name'] ?? "Da Crust Pizzeria & Indian Takeaways";
    final fbUrl = _restaurantData!['facebookUrl'] ?? "";
    
    final addressMap = _restaurantData!['address'] as Map<String, dynamic>? ?? {};
    final street = addressMap['street'] ?? "20 Diana Street";
    final city = addressMap['city'] ?? "Lumsden";

    final contactMap = _restaurantData!['contact'] as Map<String, dynamic>? ?? {};
    final phone = contactMap['phone'] ?? "";

    final hoursMap = _restaurantData!['openingHourse'] as Map<String, dynamic>? ?? {};
    final monHours = _formatTimeRange(hoursMap['monday']);
    final tueSunHours = _formatTimeRange(hoursMap['tuesday']);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          if (fbUrl.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _launchFacebook(fbUrl),
              icon: const Icon(Icons.facebook, color: Colors.white, size: 20),
              label: const Text("Follow us on Facebook"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          _buildCompactRow(context, Icons.location_on, "$street, $city"),
          const SizedBox(height: 12),
          
          _buildCompactRow(context, Icons.access_time, "Mon: $monHours  |  Tue–Sun: $tueSunHours"),
          const SizedBox(height: 12),
          
          if (phone.isNotEmpty)
            _buildCompactRow(context, Icons.phone, phone),
        ],
      ),
    );
  }

  // --- 🌟 THE FIX IS HERE ---
  Widget _buildCompactRow(BuildContext context, IconData icon, String text) {
    return Row(
      // 🌟 1. Changed to 'start' so the icon stays at the top if text wraps to two lines
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        // 🌟 2. Added a tiny top padding to perfectly align the icon with the text baseline
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 12),
        // 🌟 3. Wrapped Text in Expanded! This forces the text to wrap instead of overflowing.
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.4, // 🌟 4. Added line height so wrapped text breathes nicely
            ),
          ),
        ),
      ],
    );
  }
}