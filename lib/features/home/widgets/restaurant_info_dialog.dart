import 'package:da_crust_app/core/constants/app_assets.dart';
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

  Future<void> _loadRestaurantInfo() async {
    final data = await RestaurantService.instance.fetchRestaurantData();
    if (mounted) {
      setState(() {
        _restaurantData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps(String address) async {
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}",
    );
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch Google Maps');
    }
  }

  String _formatTimeRange(Map<String, dynamic>? dayData) {
    if (dayData == null ||
        dayData['open'] == null ||
        dayData['close'] == null) {
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
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurantData == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text("Could not load restaurant information.")),
      );
    }

    // 🌟 Grab screen width to check if we are on Mobile or Desktop!
    final isMobile = MediaQuery.of(context).size.width < 600;

    final name = _restaurantData!['name'] ?? "Da Crust";
    final aboutText = _restaurantData!['about'] ?? "Welcome to our restaurant.";

    final addressMap =
        _restaurantData!['address'] as Map<String, dynamic>? ?? {};
    final street = addressMap['street'] ?? "";
    final city = addressMap['city'] ?? "";
    final postalCode = addressMap['postalCode'] ?? "";
    final country = addressMap['country'] ?? "";
    final fullAddress = "$street, $city $postalCode, $country";

    final contactMap =
        _restaurantData!['contact'] as Map<String, dynamic>? ?? {};
    final phone = contactMap['phone'] ?? "";

    final hoursMap =
        _restaurantData!['openingHourse'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  image: DecorationImage(
                    image: const AssetImage(AppAssets.pizzaBackground),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(150),
                      BlendMode.darken,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
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
                Text(
                  "About Us",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  aboutText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                _buildInfoRow(
                  context,
                  icon: Icons.location_on,
                  title: street,
                  subtitle: "$city $postalCode, $country",
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.phone,
                  title: phone,
                  subtitle: isMobile ? "Call to order" : "Click to copy",
                  actionText: isMobile ? "Call Now" : "Copy Number",
                  onAction: () async {
                    if (isMobile) {
                      // MOBILE: Launch the Phone Dialer
                      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not launch phone dialer."),
                            ),
                          );
                        }
                      }
                    } else {
                      // DESKTOP: Copy to Clipboard
                      try {
                        await Clipboard.setData(ClipboardData(text: phone));
                        if (context.mounted) {
                          // 🌟 FIX 1: Clear the queue so the message shows instantly
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Phone number copied!"),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        // 🌟 FIX 2: Catch the silent crash if testing on an insecure HTTP network
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Number: $phone (Copy manually is blocked by browser)",
                              ),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  "Opening Hours",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                      _buildHoursRow(
                        "Monday",
                        _formatTimeRange(hoursMap['monday']),
                      ),
                      const Divider(height: 16),
                      _buildHoursRow(
                        "Tuesday - Sunday",
                        _formatTimeRange(hoursMap['tuesday']),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _launchMaps(fullAddress),
                    icon: const Icon(Icons.map),
                    label: const Text(
                      "Open in Google Maps",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(hours, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
