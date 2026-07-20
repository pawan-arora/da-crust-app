import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:da_crust_app/core/utils/date_time_utils.dart';

class OrderTimeSelector extends StatelessWidget {
  final DateTime? scheduledTime;
  final ValueChanged<DateTime?> onTimeChanged;

  const OrderTimeSelector({
    super.key,
    required this.scheduledTime,
    required this.onTimeChanged,
  });

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final minAllowedTime = now.add(const Duration(minutes: 15));
    
    final hoursMap = RestaurantService.instance.openingHours;
    DateTime firstAvailableDate = DateTime(now.year, now.month, now.day);
    
    // Check if today is open. If so, calculate closing time to see if we missed it.
    if (DateTimeUtils.isDayOpen(now.weekday, hoursMap)) {
      final todayMinutes = DateTimeUtils.getDynamicOperatingMinutes(now.weekday, hoursMap);
      final todayClosingTime = DateTime(
        now.year, now.month, now.day,
        todayMinutes['close']! ~/ 60,
        todayMinutes['close']! % 60
      );

      if (minAllowedTime.isAfter(todayClosingTime)) {
        firstAvailableDate = now.add(const Duration(days: 1));
        firstAvailableDate = DateTime(firstAvailableDate.year, firstAvailableDate.month, firstAvailableDate.day);
      }
    } else {
      // If today is closed entirely, start looking from tomorrow
      firstAvailableDate = now.add(const Duration(days: 1));
      firstAvailableDate = DateTime(firstAvailableDate.year, firstAvailableDate.month, firstAvailableDate.day);
    }

    // Ensure firstAvailableDate lands on a day the store is ACTUALLY open
    while (!DateTimeUtils.isDayOpen(firstAvailableDate.weekday, hoursMap)) {
      firstAvailableDate = firstAvailableDate.add(const Duration(days: 1));
    }

    DateTime smartDefaultTime = DateTimeUtils.getDynamicDefaultPickupTime(hoursMap);
    if (smartDefaultTime.isBefore(firstAvailableDate)) {
      smartDefaultTime = firstAvailableDate;
    }
    final initialDateToShow = scheduledTime ?? smartDefaultTime;

    // --- Pick the Date ---
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateToShow,
      firstDate: firstAvailableDate,
      lastDate: firstAvailableDate.add(const Duration(days: 7)),
      // THIS DISABLES CLOSED DAYS IN THE CALENDAR UI
      selectableDayPredicate: (DateTime day) {
        return DateTimeUtils.isDayOpen(day.weekday, hoursMap);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      // --- Pick the Time ---
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: initialDateToShow.hour,
          minute: initialDateToShow.minute
        ),
      );

      if (pickedTime != null && context.mounted) {
        final selectedDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );

        // Validation 1: Explicit Past Time Check
        if (selectedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You cannot select a time in the past.",
                style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        // Validation 2: 15-Minute Prep Time Check
        if (selectedDateTime.isBefore(minAllowedTime)) {
          final minTimeOfDay = TimeOfDay.fromDateTime(minAllowedTime);
          final formattedMinTime = minTimeOfDay.format(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please allow at least 15 mins for prep. Earliest time is $formattedMinTime.",
                style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        // Validation 3: Standard Operating Hours Check using DYNAMIC method
        if (!DateTimeUtils.isWithinDynamicOperatingHours(pickedDate, pickedTime, hoursMap)) {
          
          if (!DateTimeUtils.isDayOpen(pickedDate.weekday, hoursMap)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Sorry, we are closed on this day.",
                  style: TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }

          final dayStr = DateTimeUtils.getDayString(pickedDate.weekday);
          final dayData = hoursMap?[dayStr];
          
          final fallbackOpenStr = pickedDate.weekday == DateTime.monday ? "4:00 PM" : "11:00 AM";
          final openStr = DateTimeUtils.formatTimeString(dayData?['open'] as String?, fallback: fallbackOpenStr);
          final closeStr = DateTimeUtils.formatTimeString(dayData?['close'] as String?, fallback: "9:30 PM");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please select a time between $openStr and $closeStr.",
                style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        // If all 3 validations pass, schedule the time!
        final newTime = DateTimeUtils.createNzTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        onTimeChanged(newTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoursMap = RestaurantService.instance.openingHours;
    final displayTime = scheduledTime ?? DateTimeUtils.getDynamicDefaultPickupTime(hoursMap);

    return InkWell(
      onTap: () => _pickDateTime(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Text(
              "Pickup: ${DateTimeUtils.formatDateTime(displayTime)}",
              style: TextStyle(
                color: scheduledTime == null ? Colors.black87 : Theme.of(context).primaryColor,
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