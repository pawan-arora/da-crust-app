import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:da_crust_app/features/home/widgets/pickup_time_sheet.dart';
import 'package:flutter/material.dart';
import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:timezone/timezone.dart' as tz;

class OrderTimeSelector extends StatelessWidget {
  final DateTime? scheduledTime;
  final ValueChanged<DateTime?> onTimeChanged;

  const OrderTimeSelector({
    super.key,
    required this.scheduledTime,
    required this.onTimeChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final hoursMap = RestaurantService.instance.openingHours;
    final nzNow = DateTimeUtils.getNzTime();
    final minAllowedTime = nzNow.add(const Duration(minutes: 15));

    // Build list of next open days (max 7) using NZ time
    final availableDates = <tz.TZDateTime>[];
    var cursor = tz.TZDateTime(nzNow.location, nzNow.year, nzNow.month, nzNow.day);

    // If today has no remaining slots, start from tomorrow
    if (DateTimeUtils.isDayOpen(cursor.weekday, hoursMap)) {
      final slotsToday = DateTimeUtils.generateTimeSlots(cursor, hoursMap, minAllowedTime);
      if (slotsToday.isEmpty) {
        cursor = cursor.add(const Duration(days: 1));
      }
    } else {
      cursor = cursor.add(const Duration(days: 1));
    }

    int safety = 0;
    while (availableDates.length < 7 && safety < 14) {
      if (DateTimeUtils.isDayOpen(cursor.weekday, hoursMap)) {
        final slots = DateTimeUtils.generateTimeSlots(cursor, hoursMap, minAllowedTime);
        if (slots.isNotEmpty) {
          availableDates.add(cursor);
        }
      }
      cursor = cursor.add(const Duration(days: 1));
      safety++;
    }

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No available pickup times right now.")),
      );
      return;
    }

    // Pre-select
    tz.TZDateTime selectedDate = availableDates.first;
    if (scheduledTime != null) {
      final match = availableDates.where((d) =>
          d.year == scheduledTime!.year &&
          d.month == scheduledTime!.month &&
          d.day == scheduledTime!.day);
      if (match.isNotEmpty) selectedDate = match.first;
    }

    TimeOfDay? selectedTime;
    if (scheduledTime != null) {
      selectedTime = TimeOfDay(
        hour: scheduledTime!.hour,
        minute: scheduledTime!.minute,
      );
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370, maxHeight: 480),
            child: PickupTimeSheet(
              availableDates: availableDates,
              initialDate: selectedDate,
              initialTime: selectedTime,
              minAllowedTime: minAllowedTime,
              hoursMap: hoursMap,
              onConfirm: (date, time) {
                final newTime = DateTimeUtils.createNzTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                onTimeChanged(newTime);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoursMap = RestaurantService.instance.openingHours;
    final displayTime = scheduledTime ??
        DateTimeUtils.getDynamicDefaultPickupTime(hoursMap);

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              "Pickup: ${DateTimeUtils.formatDateTime(displayTime)}",
              style: TextStyle(
                color: scheduledTime == null
                    ? Colors.black87
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (scheduledTime != null)
              GestureDetector(
                onTap: () => onTimeChanged(null),
                child: const Icon(Icons.close, color: Colors.grey, size: 18),
              )
            else
              const Icon(Icons.access_time, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}