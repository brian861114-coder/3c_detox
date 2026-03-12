import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/focus_provider.dart';
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
  String? _selectedBlockListId; // null means use default (active) block list

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final focusProvider = context.watch<FocusProvider>();

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
                  Color(0xFFE8E6F8),
                  Color(0xFFE0F4E8),
                  Color(0xFFD6E8EE),
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
                      // Resolve the block list name for display
                      String blockListName = lang.translate('default_list');
                      bool blockListMissing = false;
                      if (schedule.blockListId != null) {
                        try {
                          final list = focusProvider.getBlockList(schedule.blockListId!);
                          // Check if it fell back to first (meaning the original list was deleted)
                          if (list.id != schedule.blockListId) {
                            blockListMissing = true;
                            blockListName = lang.translate('default_list');
                          } else {
                            blockListName = list.name;
                          }
                        } catch (_) {
                          blockListMissing = true;
                          blockListName = lang.translate('default_list');
                        }
                      }

                      final showWarning = schedule.blockListChanged || blockListMissing;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: schedule.isEnabled
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: showWarning
                                ? Colors.redAccent.withOpacity(0.5)
                                : Colors.white.withOpacity(0.6),
                            width: showWarning ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(left: 16, right: 4),
                          title: Text(
                            '${schedule.startHour.toString().padLeft(2, '0')}:${schedule.startMinute.toString().padLeft(2, '0')} (${schedule.durationMinutes} min)',
                            style: TextStyle(
                              color: schedule.isEnabled
                                  ? const Color(0xFF334155)
                                  : const Color(0xFF94A3B8),
                              decoration: schedule.isEnabled
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule.weekdays.map((d) => _getDayName(d, lang)).join(', '),
                                style: TextStyle(
                                  color: schedule.isEnabled
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFBDC5D1),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.block,
                                    size: 14,
                                    color: showWarning
                                        ? Colors.redAccent
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      blockListName,
                                      style: TextStyle(
                                        color: showWarning
                                            ? Colors.redAccent
                                            : const Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (showWarning) ...[
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: lang.translate('blocklist_changed_hint'),
                                      child: const Icon(
                                        Icons.error,
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (!schedule.isEnabled)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    lang.translate('schedule_disabled'),
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Enable/Disable toggle
                              Switch(
                                value: schedule.isEnabled,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (bool value) {
                                  scheduleProvider.toggleScheduleEnabled(schedule.id);
                                  // If re-enabling, clear the warning flag
                                  if (value && schedule.blockListChanged) {
                                    scheduleProvider.clearBlockListChangedFlag(schedule.id);
                                  }
                                },
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () => scheduleProvider.removeSchedule(schedule.id),
                              ),
                            ],
                          ),
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
                          const SizedBox(height: 12),
                          // Block List Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.block, size: 18, color: Color(0xFF475569)),
                                const SizedBox(width: 8),
                                Text(
                                  '${lang.translate('block_list')}: ',
                                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                ),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedBlockListId ?? '__default__',
                                      dropdownColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF334155)),
                                      style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500, fontSize: 14),
                                      items: [
                                        DropdownMenuItem(
                                          value: '__default__',
                                          child: Text(
                                            lang.translate('default_list'),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...focusProvider.blockLists.map((list) {
                                          return DropdownMenuItem(
                                            value: list.id,
                                            child: Text(
                                              list.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == '__default__') {
                                            _selectedBlockListId = null;
                                          } else {
                                            _selectedBlockListId = value;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
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
                                blockListId: _selectedBlockListId,
                              );
                              scheduleProvider.addSchedule(newSchedule);
                              setState(() {
                                _selectedDays.clear();
                                _selectedBlockListId = null;
                              });
                            },
                            child: Text(
                              lang.translate('add_schedule'),
                              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
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
