import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class DateTimeUtils {
  // 🌟 The Single Source of Truth for New Zealand Time
  static tz.Location get _nz => tz.getLocation('Pacific/Auckland');

  // --- 1. Get Exact New Zealand Time ---
  static tz.TZDateTime getNzTime() {
    return tz.TZDateTime.now(_nz);
  }

  // --- 2. Helper to create a pure NZ Date Object ---
  static tz.TZDateTime createNzTime(int year, int month, int day, int hour, int minute) {
    return tz.TZDateTime(_nz, year, month, day, hour, minute);
  }

  static tz.TZDateTime getActualDateTime() {
    // Cast to TZDateTime for safety, falling back to default if null
    final scheduled = CartManager.instance.scheduledTime as tz.TZDateTime?;
    return scheduled ?? getDefaultPickupTime();
  }

  // --- 3. Database Store Hours Logic ---
  static int getOpeningHour(int weekday) {
    return weekday == DateTime.monday ? 16 : 11;
  }

  static int getClosingHour() => 21;
  static int getClosingMinute() => 30;

  // --- 4. The Smart Default Time Calculator ---
  static tz.TZDateTime getDefaultPickupTime() {
    final nzNow = getNzTime();
    final currentTotalMinutes = nzNow.hour * 60 + nzNow.minute;
    final closeTotalMinutes = getClosingHour() * 60 + getClosingMinute();

    // Case A: Store is closed for the night.
    if (currentTotalMinutes >= closeTotalMinutes) {
      final tomorrow = nzNow.add(const Duration(days: 1));
      final openHour = getOpeningHour(tomorrow.weekday);
      return createNzTime(tomorrow.year, tomorrow.month, tomorrow.day, openHour, 0);
    }

    final openHour = getOpeningHour(nzNow.weekday);
    final openTotalMinutes = openHour * 60;

    // Case B: Early morning, store opens later today.
    if (currentTotalMinutes < openTotalMinutes) {
      return createNzTime(nzNow.year, nzNow.month, nzNow.day, openHour, 0);
    }

    // Case C: Open now
    return nzNow.add(const Duration(minutes: 15));
  }

  // --- 5. Validation Logic ---
  static bool isValidPickupTime(DateTime pickedDate, TimeOfDay pickedTime) {
    final nzNow = getNzTime();
    final pickedTotalMinutes = pickedTime.hour * 60 + pickedTime.minute;
    final currentTotalMinutes = nzNow.hour * 60 + nzNow.minute;
    final closeTotalMinutes = getClosingHour() * 60 + getClosingMinute();
    final openTotalMinutes = getOpeningHour(pickedDate.weekday) * 60;

    if (pickedDate.year == nzNow.year &&
        pickedDate.month == nzNow.month &&
        pickedDate.day == nzNow.day &&
        pickedTotalMinutes <= currentTotalMinutes) {
      return false;
    }

    if (pickedTotalMinutes < openTotalMinutes ||
        pickedTotalMinutes >= closeTotalMinutes) {
      return false;
    }

    return true;
  }

  // --- 6. Formatting Helpers ---
  static String formatDateTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return "${date.day}/${date.month} at $hour:$minute $ampm";
  }

  static String formatDurationToOpen(DateTime nextOpen, DateTime now) {
    final diff = nextOpen.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);

    List<String> parts = [];
    if (days > 0) parts.add("$days day${days == 1 ? '' : 's'}");
    if (hours > 0) parts.add("$hours hr${hours == 1 ? '' : 's'}");
    if (minutes > 0) parts.add("$minutes min${minutes == 1 ? '' : 's'}");

    if (parts.isEmpty) return "Opening very soon!";
    return "Opens in ${parts.join(' and ')}. You can still pre-order now!";
  }

  static String formatDurationToClose(DateTime closeTime, DateTime now) {
    final diff = closeTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    List<String> parts = [];
    if (hours > 0) parts.add("$hours hr${hours == 1 ? '' : 's'}");
    if (minutes > 0) parts.add("$minutes min${minutes == 1 ? '' : 's'}");

    final formattedClockTime = formatDateTime(closeTime).split(" at ")[1];

    if (parts.isEmpty) return "Closing very soon! Place your order now.";
    return "Open until $formattedClockTime. Closes in ${parts.join(' and ')}.";
  }

  // --- 7. Status & Business Hours Helpers ---
  static tz.TZDateTime? getNextOpenTime(DateTime nzTime, Map<String, dynamic>? hoursMap) {
    if (hoursMap == null) return null;
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    for (int offset = 0; offset <= 7; offset++) {
      final checkDate = nzTime.add(Duration(days: offset));
      final dayString = weekdays[checkDate.weekday - 1];
      final dayHours = hoursMap[dayString];

      if (dayHours != null && dayHours['open'] != null) {
        final openParts = (dayHours['open'] as String).split(':');
        if (openParts.length == 2) {
          final openHour = int.tryParse(openParts[0]) ?? 0;
          final openMinute = int.tryParse(openParts[1]) ?? 0;
          
          final openDateTime = createNzTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
            openHour,
            openMinute,
          );
          if (openDateTime.isAfter(nzTime)) return openDateTime;
        }
      }
    }
    return null;
  }

  static tz.TZDateTime? getCloseTimeForToday(DateTime nzTime, Map<String, dynamic>? hoursMap) {
    if (hoursMap == null) return null;
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentDayString = weekdays[nzTime.weekday - 1];
    final todayHours = hoursMap[currentDayString];

    if (todayHours != null && todayHours['close'] != null) {
      final closeParts = (todayHours['close'] as String).split(':');
      if (closeParts.length == 2) {
        final closeHour = int.tryParse(closeParts[0]) ?? 0;
        final closeMinute = int.tryParse(closeParts[1]) ?? 0;
        
        return createNzTime(
          nzTime.year,
          nzTime.month,
          nzTime.day,
          closeHour,
          closeMinute,
        );
      }
    }
    return null;
  }
}