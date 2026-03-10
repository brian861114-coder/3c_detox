import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<int> _selectedDays = [];
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationHours = 1;
  int _durationMins = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(lang.translate('schedules'), style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8E6F8), // pastel lavender
                  Color(0xFFE0F4E8), // mint green
                  Color(0xFFD6E8EE), // baby blue
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
          Expanded(
            child: ListView.builder(
              itemCount: scheduleProvider.schedules.length,
              itemBuilder: (context, index) {
                final schedule = scheduleProvider.schedules[index];
                return ListTile(
                  title: Text(
                    '${schedule.startHour.toString().padLeft(2, '0')}:${schedule.startMinute.toString().padLeft(2, '0')} (${schedule.durationMinutes} min)',
                    style: const TextStyle(color: Color(0xFF334155)),
                  ),
                  subtitle: Text(
                    schedule.weekdays.map((d) => _getDayName(d, lang)).join(', '),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => scheduleProvider.removeSchedule(schedule.id),
                  ),
                );
              },
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                ),
                child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(_getDayName(day, lang)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF10B981).withOpacity(0.6),
                      backgroundColor: Colors.white.withOpacity(0.6),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                      onPressed: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                          builder: (context, child) {
                             return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                             );
                          },
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      child: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                    ),
                    Row(
                      children: [
                        Text('${lang.translate('duration')}: ', style: const TextStyle(color: Color(0xFF334155))),
                        DropdownButton<int>(
                          value: _durationHours,
                          dropdownColor: const Color(0xFFF8FAFC),
                          style: const TextStyle(color: Color(0xFF334155)),
                          underline: const SizedBox(),
                          items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i hr'))),
                          onChanged: (v) {
                            if (v != null) setState(() => _durationHours = v);
                          },
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _durationMins,
                          dropdownColor: const Color(0xFFF8FAFC),
                          style: const TextStyle(color: Color(0xFF334155)),
                          underline: const SizedBox(),
                          items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Text('$i min'))),
                          onChanged: (v) {
                            if (v != null) setState(() => _durationMins = v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: (_selectedDays.isEmpty || (_durationHours == 0 && _durationMins == 0)) ? null : () {
                    final newSchedule = FocusSchedule(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      weekdays: List.from(_selectedDays),
                      startHour: _selectedTime.hour,
                      startMinute: _selectedTime.minute,
                      durationMinutes: _durationHours * 60 + _durationMins,
                    );
                    scheduleProvider.addSchedule(newSchedule);
                    setState(() {
                      _selectedDays.clear();
                    });
                  },
                  child: Text(lang.translate('add_schedule'), style: const TextStyle(fontSize: 16)),
                ),
              ],
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

  String _getDayName(int dayIndex, LanguageProvider lang) {
    const pfx = 'day_';
    return lang.translate('$pfx$dayIndex');
  }
}
