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

  bool isCurrentlyInScheduledFocus() {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
    final prevDay = currentDay == 1 ? 7 : currentDay - 1;

    for (var schedule in _schedules) {
      // Check for today's schedule
      if (schedule.weekdays.contains(currentDay)) {
        final startToday = DateTime(now.year, now.month, now.day, schedule.startHour, schedule.startMinute);
        final endToday = startToday.add(Duration(minutes: schedule.durationMinutes));

        if (now.isAfter(startToday) && now.isBefore(endToday)) {
          return true;
        }
      }

      // Check for yesterday's schedule (in case it crosses midnight)
      if (schedule.weekdays.contains(prevDay)) {
        // Construct yesterday's start time
        final yesterday = now.subtract(const Duration(days: 1));
        final startYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, schedule.startHour, schedule.startMinute);
        final endYesterday = startYesterday.add(Duration(minutes: schedule.durationMinutes));

        if (now.isAfter(startYesterday) && now.isBefore(endYesterday)) {
          return true;
        }
      }
    }
    return false;
  }
}
