import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';

enum RestaurantState { open, closed, openingSoon, closingSoon }

class RestaurantStatusWidget extends StatefulWidget {
  const RestaurantStatusWidget({super.key});

  @override
  State<RestaurantStatusWidget> createState() => _RestaurantStatusWidgetState();
}

class _RestaurantStatusWidgetState extends State<RestaurantStatusWidget> {
  Map<String, dynamic>? _hoursMap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  // --- 🌟 FETCH DATA ONCE ---
  Future<void> _loadHours() async {
    final hours = await RestaurantService.instance.fetchOpeningHours();
    if (mounted) {
      setState(() {
        _hoursMap = hours;
        _isLoading = false;
      });
    }
  }

  // --- LOGIC HELPERS ---
  RestaurantState _checkStatus(DateTime nzTime) {
    if (_hoursMap == null) return RestaurantState.closed;

    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentDayString = weekdays[nzTime.weekday - 1];

    final todayHours = _hoursMap![currentDayString];
    if (todayHours == null || todayHours['open'] == null || todayHours['close'] == null) {
      return RestaurantState.closed;
    }

    final openParts = (todayHours['open'] as String).split(':');
    final closeParts = (todayHours['close'] as String).split(':');

    if (openParts.length != 2 || closeParts.length != 2) return RestaurantState.closed;

    final openMinutes = (int.tryParse(openParts[0]) ?? 0) * 60 + (int.tryParse(openParts[1]) ?? 0);
    final closeMinutes = (int.tryParse(closeParts[0]) ?? 0) * 60 + (int.tryParse(closeParts[1]) ?? 0);
    final currentMinutes = nzTime.hour * 60 + nzTime.minute;

    if (currentMinutes >= openMinutes && currentMinutes < closeMinutes) {
      if (closeMinutes - currentMinutes <= 15) return RestaurantState.closingSoon;
      return RestaurantState.open;
    } else if (currentMinutes < openMinutes && (openMinutes - currentMinutes) <= 30) {
      return RestaurantState.openingSoon;
    } else {
      return RestaurantState.closed;
    }
  }

 void _handleBadgeTap(BuildContext context, DateTime nzTime, RestaurantState status) {
    String message = "";

    if (status == RestaurantState.closed || status == RestaurantState.openingSoon) {
      final nextOpen = DateTimeUtils.getNextOpenTime(nzTime, _hoursMap);
      message = nextOpen != null 
          ? DateTimeUtils.formatDurationToOpen(nextOpen, nzTime)
          : "Cannot determine next opening time.";
    } else {
      final closeTime = DateTimeUtils.getCloseTimeForToday(nzTime, _hoursMap);
      message = closeTime != null 
          ? DateTimeUtils.formatDurationToClose(closeTime, nzTime)
          : "Cannot determine closing time.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        duration: const Duration(seconds: 4), 
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey.shade900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 24, width: 80); 
    }

    final nzTime = DateTimeUtils.getNzTime();
    final status = _checkStatus(nzTime);

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case RestaurantState.open:
        badgeColor = Colors.green.shade500;
        badgeText = "Open Now";
        badgeIcon = Icons.check_circle;
        break;
      case RestaurantState.closingSoon:
        badgeColor = Colors.deepOrange.shade500;
        badgeText = "Closing Soon";
        badgeIcon = Icons.timer;
        break;
      case RestaurantState.openingSoon:
        badgeColor = Colors.orange.shade600; 
        badgeText = "Opening Soon";
        badgeIcon = Icons.access_time_filled;
        break;
      case RestaurantState.closed:
        badgeColor = Colors.red.shade500;
        badgeText = "Closed";
        badgeIcon = Icons.cancel;
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _handleBadgeTap(context, nzTime, status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(80), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}