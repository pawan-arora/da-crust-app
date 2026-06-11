import 'package:flutter/material.dart';
import 'package:da_crust_app/core/utils/date_time_utils.dart'; // Adjust path as needed

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

    final todayClosingTime = DateTime(now.year, now.month, now.day, 21, 30); 
    DateTime firstAvailableDate = DateTime(now.year, now.month, now.day); 

    // If adding 15 mins pushes us past 9:30 PM, today is no longer an option. Jump to tomorrow.
    if (minAllowedTime.isAfter(todayClosingTime)) {
      firstAvailableDate = now.add(const Duration(days: 1));
      firstAvailableDate = DateTime(firstAvailableDate.year, firstAvailableDate.month, firstAvailableDate.day);
    }

    // Explicitly typed as DateTime to prevent TZDateTime mismatch errors
    DateTime smartDefaultTime = DateTimeUtils.getDefaultPickupTime();
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

        // --- VALIDATION LAYER ---

        // Validation 1: Explicit Past Time Check (MUST BE FIRST)
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
          return; // Stop execution here
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
          return; // Stop execution here
        }

        // Validation 3: Standard Operating Hours Check (LAST)
        if (!DateTimeUtils.isWithinOperatingHours(pickedDate, pickedTime)) {
          final openStr = pickedDate.weekday == DateTime.monday ? "4:00 PM" : "11:00 AM";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please select a time between $openStr and 9:30 PM.", 
                style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red.shade600, 
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          return; // Stop execution here
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
    final displayTime = scheduledTime ?? DateTimeUtils.getDefaultPickupTime();

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