import 'package:flutter/material.dart';

/// Widget for selecting date and time for deal start/end
class DateTimePickerField extends StatefulWidget {
  const DateTimePickerField({
    required this.label,
    required this.onDateTimeSelected,
    super.key,
    this.selectedDateTime,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });
  final String label;
  final DateTime? selectedDateTime;
  final Function(DateTime) onDateTimeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  late DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.selectedDateTime;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime.now(),
      lastDate: widget.lastDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime?.hour ?? 12,
          _selectedDateTime?.minute ?? 0,
        );
      });
      widget.onDateTimeSelected(_selectedDateTime!);
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDateTime == null) {
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime!),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime!.year,
          _selectedDateTime!.month,
          _selectedDateTime!.day,
          picked.hour,
          picked.minute,
        );
      });
      widget.onDateTimeSelected(_selectedDateTime!);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.errorText != null
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDateTime == null
                                ? 'Pick date'
                                : '${_selectedDateTime!.year}-${_selectedDateTime!.month.toString().padLeft(2, '0')}-${_selectedDateTime!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDateTime == null
                                  ? Colors.grey.shade400
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: GestureDetector(
                  onTap: _selectedDateTime == null ? null : _selectTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.errorText != null
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _selectedDateTime == null
                          ? Colors.grey.shade50
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDateTime == null
                              ? '12:00'
                              : '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDateTime == null
                                ? Colors.grey.shade400
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
}
