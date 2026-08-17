import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class PickupTimeSheet extends StatefulWidget {
  final List<tz.TZDateTime> availableDates;
  final tz.TZDateTime initialDate;
  final TimeOfDay? initialTime;
  final tz.TZDateTime minAllowedTime;
  final Map<String, dynamic>? hoursMap;
  final void Function(tz.TZDateTime date, TimeOfDay time) onConfirm;

  const PickupTimeSheet({super.key, 
    required this.availableDates,
    required this.initialDate,
    required this.initialTime,
    required this.minAllowedTime,
    required this.hoursMap,
    required this.onConfirm,
  });

  @override
  State<PickupTimeSheet> createState() => _PickupTimeSheetState();
}

class _PickupTimeSheetState extends State<PickupTimeSheet> {
  late tz.TZDateTime selectedDate;
  TimeOfDay? selectedTime;
  late List<TimeOfDay> currentSlots;
  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedTime = widget.initialTime;
    currentSlots = _generateSlots(selectedDate);
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  List<TimeOfDay> _generateSlots(tz.TZDateTime date) {
    final minutes = DateTimeUtils.getDynamicOperatingMinutes(
        date.weekday, widget.hoursMap);
    final open = minutes['open']!;
    final close = minutes['close']!;
    final last = close - 15;
    if (last < open) return [];

    final slots = <TimeOfDay>[];
    int current = open;

    while (current <= last) {
      final h = current ~/ 60;
      final m = current % 60;
      final slotDt = DateTimeUtils.createNzTime(
        date.year, date.month, date.day, h, m,
      );

      final isToday = date.year == widget.minAllowedTime.year &&
          date.month == widget.minAllowedTime.month &&
          date.day == widget.minAllowedTime.day;

      if (isToday && slotDt.isBefore(widget.minAllowedTime)) {
        current += 15;
        continue;
      }

      slots.add(TimeOfDay(hour: h, minute: m));
      current += 15;
    }
    return slots;
  }

  void _onDateSelected(tz.TZDateTime date) {
    setState(() {
      selectedDate = date;
      currentSlots = _generateSlots(date);
      if (selectedTime != null &&
          !currentSlots.any((t) =>
              t.hour == selectedTime!.hour &&
              t.minute == selectedTime!.minute)) {
        selectedTime = null;
      }
    });
  }

  void _scrollDates(bool forward) {
    final offset = _dateScrollController.offset + (forward ? 180 : -180);
    _dateScrollController.animateTo(
      offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatDateChip(tz.TZDateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${weekdays[date.weekday - 1]}\n${date.day} ${months[date.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 0),
          child: Row(
            children: [
              const Spacer(),
              Text(
                "Select Pickup Time",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Date chips + arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 26),
                onPressed: () => _scrollDates(false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ListView.separated(
                    controller: _dateScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.availableDates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final date = widget.availableDates[index];
                      final isSelected = date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;

                      return GestureDetector(
                        onTap: () => _onDateSelected(date),
                        child: Container(
                          width: 62,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? primary : Colors.grey.shade300,
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatDateChip(date),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? primary : Colors.black87,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 26),
                onPressed: () => _scrollDates(true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.grey.shade200),

        // Time list
        Flexible(
          child: currentSlots.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("No available times"),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: currentSlots.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final slot = currentSlots[index];
                    final isSelected = selectedTime != null &&
                        selectedTime!.hour == slot.hour &&
                        selectedTime!.minute == slot.minute;

                    return ListTile(
                      dense: true,
                      title: Text(
                        slot.format(context),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? primary : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? primary : Colors.grey.shade400,
                        size: 20,
                      ),
                      onTap: () => setState(() => selectedTime = slot),
                    );
                  },
                ),
        ),

        // Confirm
        if (selectedTime != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  widget.onConfirm(selectedDate, selectedTime!);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Confirm",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }
}