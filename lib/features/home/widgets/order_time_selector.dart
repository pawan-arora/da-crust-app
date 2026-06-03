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
    // Let the util class decide exactly what date/time to show by default!
    final smartDefaultTime = DateTimeUtils.getDefaultPickupTime();
    final initialDateToShow = scheduledTime ?? smartDefaultTime;

    // 1. Pick the Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateToShow, 
      firstDate: smartDefaultTime, // Locks out dates in the past/when closed
      lastDate: smartDefaultTime.add(const Duration(days: 7)), 
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
      // 2. Pick the Time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: initialDateToShow.hour, 
          minute: initialDateToShow.minute
        ), 
      );

      if (pickedTime != null && context.mounted) {
        
        // --- VALIDATION LAYER ---
        if (DateTimeUtils.isValidPickupTime(pickedDate, pickedTime)) {
          final newTime = DateTimeUtils.createNzTime(
            pickedDate.year, pickedDate.month, pickedDate.day, 
            pickedTime.hour, pickedTime.minute,
          );
          onTimeChanged(newTime);
        } else {
          final openStr = pickedDate.weekday == DateTime.monday ? "4:00 PM" : "11:00 AM";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please select a future time between $openStr and 9:30 PM.", 
                style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red.shade600, 
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 No more "ASAP"! Get the time they scheduled, or fallback to the smart default.
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