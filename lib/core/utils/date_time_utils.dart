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

  static List<TimeOfDay> generateTimeSlots(
    tz.TZDateTime date,
    Map<String, dynamic>? hoursMap,
    tz.TZDateTime minAllowedTime,
  ) {
    final minutes =
        DateTimeUtils.getDynamicOperatingMinutes(date.weekday, hoursMap);
    final openMinutes = minutes['open']!;
    final closeMinutes = minutes['close']!;
    final lastAllowed = closeMinutes - 15;

    if (lastAllowed < openMinutes) return [];

    final slots = <TimeOfDay>[];
    int current = openMinutes;

    while (current <= lastAllowed) {
      final hour = current ~/ 60;
      final minute = current % 60;
      final slotDt = DateTimeUtils.createNzTime(
        date.year, date.month, date.day, hour, minute,
      );

      final isToday = date.year == minAllowedTime.year &&
          date.month == minAllowedTime.month &&
          date.day == minAllowedTime.day;

      if (isToday && slotDt.isBefore(minAllowedTime)) {
        current += 15;
        continue;
      }

      slots.add(TimeOfDay(hour: hour, minute: minute));
      current += 15;
    }
    return slots;
  }
  // --- 2. Helper to create a pure NZ Date Object ---
  static tz.TZDateTime createNzTime(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
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
      return createNzTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        openHour,
        0,
      );
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

  // Strictly checks if a time falls within the store's open/close window ---
  static bool isWithinOperatingHours(
    DateTime pickedDate,
    TimeOfDay pickedTime,
  ) {
    final pickedTotalMinutes = pickedTime.hour * 60 + pickedTime.minute;
    final closeTotalMinutes = getClosingHour() * 60 + getClosingMinute();
    final openTotalMinutes = getOpeningHour(pickedDate.weekday) * 60;

    if (pickedTotalMinutes < openTotalMinutes ||
        pickedTotalMinutes >= closeTotalMinutes) {
      return false;
    }

    return true;
  }

  // --- 6. Formatting Helpers ---
  static String formatDateTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
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
  static tz.TZDateTime? getNextOpenTime(
    DateTime nzTime,
    Map<String, dynamic>? hoursMap,
  ) {
    if (hoursMap == null) return null;
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

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

  static tz.TZDateTime? getCloseTimeForToday(
    DateTime nzTime,
    Map<String, dynamic>? hoursMap,
  ) {
    if (hoursMap == null) return null;
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
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

  // =======================================================================
  // --- 8. NEW: Dynamic Time Methods for OrderTimeSelector (SAFE ADDITIONS)
  // =======================================================================

  static const List<String> _weekdaysMap = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static String getDayString(int weekday) => _weekdaysMap[weekday - 1];

  /// Checks if the day exists in the database map. Missing means closed.
  static bool isDayOpen(int weekday, Map<String, dynamic>? hoursMap) {
    if (hoursMap == null || hoursMap.isEmpty)
      return true; // Fallback if DB fetch fails
    final dayStr = getDayString(weekday);
    return hoursMap.containsKey(dayStr);
  }

  /// Gets dynamic minutes from map, falls back to old logic if map is null/missing
  static Map<String, int> getDynamicOperatingMinutes(
    int weekday,
    Map<String, dynamic>? hoursMap,
  ) {
    int openMins = getOpeningHour(weekday) * 60;
    int closeMins = getClosingHour() * 60 + getClosingMinute();

    if (hoursMap != null) {
      final dayStr = getDayString(weekday);
      final dayData = hoursMap[dayStr];
      if (dayData != null) {
        if (dayData['open'] != null) {
          final openParts = (dayData['open'] as String).split(':');
          openMins = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
        }
        if (dayData['close'] != null) {
          final closeParts = (dayData['close'] as String).split(':');
          closeMins = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
        }
      }
    }
    return {'open': openMins, 'close': closeMins};
  }

  /// Scans up to 7 days ahead to find the very next time the store is open
  static tz.TZDateTime getDynamicDefaultPickupTime(
    Map<String, dynamic>? hoursMap,
  ) {
    final nzNow = getNzTime();

    // Check up to 7 days forward to find an open day
    for (int offset = 0; offset < 7; offset++) {
      final checkDate = nzNow.add(Duration(days: offset));
      final isTodayInLoop = (offset == 0);

      if (isDayOpen(checkDate.weekday, hoursMap)) {
        final opMinutes = getDynamicOperatingMinutes(
          checkDate.weekday,
          hoursMap,
        );
        final openTotalMinutes = opMinutes['open']!;
        final closeTotalMinutes = opMinutes['close']!;

        if (isTodayInLoop) {
          final currentTotalMinutes = nzNow.hour * 60 + nzNow.minute;

          if (currentTotalMinutes >= closeTotalMinutes) {
            // Store closed for today, let the loop move to tomorrow
            continue;
          } else if (currentTotalMinutes < openTotalMinutes) {
            // Early morning, store opens later today
            return createNzTime(
              checkDate.year,
              checkDate.month,
              checkDate.day,
              openTotalMinutes ~/ 60,
              openTotalMinutes % 60,
            );
          } else {
            // Open right now!
            return nzNow.add(const Duration(minutes: 15));
          }
        } else {
          // This is a future day. Return its exact opening time.
          return createNzTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
            openTotalMinutes ~/ 60,
            openTotalMinutes % 60,
          );
        }
      }
    }

    // Absolute fallback if map is fully empty/corrupt
    return nzNow.add(const Duration(minutes: 15));
  }

  static bool isWithinDynamicOperatingHours(
    DateTime pickedDate,
    TimeOfDay pickedTime,
    Map<String, dynamic>? hoursMap,
  ) {
    // If the day is completely missing from DB, it's not operating.
    if (!isDayOpen(pickedDate.weekday, hoursMap)) return false;

    final pickedTotalMinutes = pickedTime.hour * 60 + pickedTime.minute;
    final opMinutes = getDynamicOperatingMinutes(pickedDate.weekday, hoursMap);

    if (pickedTotalMinutes < opMinutes['open']! ||
        pickedTotalMinutes >= opMinutes['close']!) {
      return false;
    }
    return true;
  }

  static String formatTimeString(String? timeStr, {required String fallback}) {
    if (timeStr == null) return fallback;
    final parts = timeStr.split(':');
    if (parts.length != 2) return fallback;

    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final ampm = h >= 12 ? "PM" : "AM";
    final hr12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return "$hr12:$m $ampm";
  }
}
