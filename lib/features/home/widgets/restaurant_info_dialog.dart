import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantInfoDialog extends StatefulWidget {
  const RestaurantInfoDialog({super.key});

  @override
  State<RestaurantInfoDialog> createState() => _RestaurantInfoDialogState();
}

class _RestaurantInfoDialogState extends State<RestaurantInfoDialog> {
  Map<String, dynamic>? _restaurantData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
  }

  // --- 🌟 FETCH DATA ONCE VIA SERVICE ---
  Future<void> _loadRestaurantInfo() async {
    final data = await RestaurantService.instance.fetchRestaurantData();
    if (mounted) {
      setState(() {
        _restaurantData = data;
        _isLoading = false;
      });
    }
  }

  // Dynamically accepts the address from Firebase
  Future<void> _launchMaps(String address) async {
    // Fixed the string interpolation and used the standard Google Maps search URL
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch Google Maps');
    }
  }

  // Helper to convert Firebase "21:30" to "9:30 PM"
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), 
        child: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    // 1. Loading State
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Error / Empty State
    if (_restaurantData == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text("Could not load restaurant information.")),
      );
    }

    // 3. Extract Firebase Data (Using our cached _restaurantData)
    final name = _restaurantData!['name'] ?? "Da Crust";
    final aboutText = _restaurantData!['about'] ?? "Welcome to our restaurant.";
    
    final addressMap = _restaurantData!['address'] as Map<String, dynamic>? ?? {};
    final street = addressMap['street'] ?? "";
    final city = addressMap['city'] ?? "";
    final postalCode = addressMap['postalCode'] ?? "";
    final country = addressMap['country'] ?? "";
    final fullAddress = "$street, $city $postalCode, $country";
    
    final contactMap = _restaurantData!['contact'] as Map<String, dynamic>? ?? {};
    final phone = contactMap['phone'] ?? "";

    final hoursMap = _restaurantData!['openingHourse'] as Map<String, dynamic>? ?? {};

    // 4. Build the UI with dynamic data
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. HEADER BANNER ---
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  image: DecorationImage(
                    image: const AssetImage('assets/images/pizza.jpg'), 
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(150), 
                      BlendMode.darken,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 30, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withAlpha(120),
                  radius: 16,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 2. ABOUT US DESCRIPTION ---
                Text(
                  "About Us",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  aboutText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // --- 3. CONTACT & LOCATION INFO ---
                _buildInfoRow(
                  context, 
                  icon: Icons.location_on, 
                  title: street, 
                  subtitle: "$city $postalCode, $country",
                  actionText: "Get Directions",
                  onAction: () => _launchMaps(fullAddress),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context, 
                  icon: Icons.phone, 
                  title: phone, 
                  subtitle: "Call to order",
                  actionText: "Copy Number",
                  onAction: () async {
                    await Clipboard.setData(ClipboardData(text: phone));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Phone number copied!"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating, 
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // --- 4. OPENING HOURS ---
                Text(
                  "Opening Hours",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildHoursRow("Monday", _formatTimeRange(hoursMap['monday'])),
                      const Divider(height: 16),
                      _buildHoursRow("Tuesday - Sunday", _formatTimeRange(hoursMap['tuesday'])),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- 5. GOOGLE MAPS DIRECTION BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _launchMaps(fullAddress),
                    icon: const Icon(Icons.map),
                    label: const Text("Open in Google Maps", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for Address and Phone rows
  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String title, required String subtitle, required String actionText, required VoidCallback onAction}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionText, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Helper widget for formatting hours
  Widget _buildHoursRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        Text(hours, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}