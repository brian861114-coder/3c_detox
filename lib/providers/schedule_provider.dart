import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class ScheduleProvider with ChangeNotifier {
  List<FocusSchedule> _schedules = [];

  List<FocusSchedule> get schedules => _schedules;

  ScheduleProvider() {
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? schedulesJson = prefs.getString('focus_schedules');
    if (schedulesJson != null) {
      final List<dynamic> decoded = jsonDecode(schedulesJson);
      _schedules = decoded.map((item) => FocusSchedule.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_schedules.map((s) => s.toJson()).toList());
    await prefs.setString('focus_schedules', encoded);
  }

  void addSchedule(FocusSchedule schedule) {
    _schedules.add(schedule);
    _saveSchedules();
    notifyListeners();
  }

  void removeSchedule(String id) {
    _schedules.removeWhere((schedule) => schedule.id == id);
    _saveSchedules();
    notifyListeners();
  }

  /// Toggle the enabled/disabled state of a schedule
  void toggleScheduleEnabled(String id) {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(
        isEnabled: !_schedules[index].isEnabled,
      );
      _saveSchedules();
      notifyListeners();
    }
  }

  /// Get list of schedule names that use a specific block list
  List<String> getSchedulesUsingBlockList(String blockListId) {
    final result = <String>[];
    for (var schedule in _schedules) {
      if (schedule.blockListId == blockListId) {
        final time = '${schedule.startHour.toString().padLeft(2, '0')}:${schedule.startMinute.toString().padLeft(2, '0')}';
        result.add(time);
      }
    }
    return result;
  }

  /// When a block list is deleted or modified,
  /// disable all schedules using it and mark them with blockListChanged flag
  void onBlockListChanged(String blockListId) {
    bool changed = false;
    for (int i = 0; i < _schedules.length; i++) {
      if (_schedules[i].blockListId == blockListId) {
        _schedules[i] = _schedules[i].copyWith(
          isEnabled: false,
          blockListChanged: true,
        );
        changed = true;
      }
    }
    if (changed) {
      _saveSchedules();
      notifyListeners();
    }
  }

  /// Clear the blockListChanged flag for a schedule (user acknowledges the change)
  void clearBlockListChangedFlag(String scheduleId) {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(blockListChanged: false);
      _saveSchedules();
      notifyListeners();
    }
  }

  bool isCurrentlyInScheduledFocus() {
    return getCurrentActiveSchedule() != null;
  }

  /// Returns the currently active schedule if one matches, or null
  FocusSchedule? getCurrentActiveSchedule() {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
    final prevDay = currentDay == 1 ? 7 : currentDay - 1;

    for (var schedule in _schedules) {
      // Only check enabled schedules
      if (!schedule.isEnabled) continue;

      // Check for today's schedule
      if (schedule.weekdays.contains(currentDay)) {
        final startToday = DateTime(now.year, now.month, now.day, schedule.startHour, schedule.startMinute);
        final endToday = startToday.add(Duration(minutes: schedule.durationMinutes));

        if (now.isAfter(startToday) && now.isBefore(endToday)) {
          return schedule;
        }
      }

      // Check for yesterday's schedule (in case it crosses midnight)
      if (schedule.weekdays.contains(prevDay)) {
        final yesterday = now.subtract(const Duration(days: 1));
        final startYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, schedule.startHour, schedule.startMinute);
        final endYesterday = startYesterday.add(Duration(minutes: schedule.durationMinutes));

        if (now.isAfter(startYesterday) && now.isBefore(endYesterday)) {
          return schedule;
        }
      }
    }
    return null;
  }
}
