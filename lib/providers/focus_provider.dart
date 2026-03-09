import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/native_integration.dart';

class FocusProvider with ChangeNotifier {
  bool _isFocusing = false;
  bool _isResting = false;
  bool _isPomodoroMode = true;
  int _remainingSeconds = 25 * 60; // Default 25 minutes
  Timer? _timer;
  Set<String> _blacklistedApps = {};

  FocusProvider() {
    _loadBlacklistedApps();
  }

  Future<void> _loadBlacklistedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedApps = prefs.getStringList('blacklistedApps');
    if (savedApps != null) {
      _blacklistedApps = savedApps.toSet();
      notifyListeners();
    }
  }

  Future<void> _saveBlacklistedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blacklistedApps', _blacklistedApps.toList());
  }

  // Stats
  int _focusCyclesCompleted = 0;
  int _totalFocusedMinutes = 0;

  bool get isFocusing => _isFocusing;
  bool get isResting => _isResting;
  bool get isPomodoroMode => _isPomodoroMode;
  int get remainingSeconds => _remainingSeconds;
  Set<String> get blacklistedApps => _blacklistedApps;
  int get focusCyclesCompleted => _focusCyclesCompleted;
  int get totalFocusedMinutes => _totalFocusedMinutes;

  void togglePomodoroMode() {
    if (!_isFocusing && !_isResting) {
      _isPomodoroMode = !_isPomodoroMode;
      _remainingSeconds = _isPomodoroMode ? 25 * 60 : 30 * 60; // Just some defaults
      notifyListeners();
    }
  }

  void toggleAppBlacklist(String packageName) {
    if (_blacklistedApps.contains(packageName)) {
      _blacklistedApps.remove(packageName);
    } else {
      _blacklistedApps.add(packageName);
    }
    _saveBlacklistedApps();
    notifyListeners();
  }

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startFocus(int durationMinutes) {
    _isFocusing = true;
    _isResting = false;
    _remainingSeconds = durationMinutes * 60;
    _timer?.cancel();
    
    NativeIntegration.startPersistentService(_blacklistedApps.toList());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onSessionComplete(durationMinutes);
      }
    });
    notifyListeners();
  }

  void startRest(int durationMinutes) {
    _isFocusing = false;
    _isResting = true;
    _remainingSeconds = durationMinutes * 60;
    _timer?.cancel();

    NativeIntegration.stopPersistentService();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopFocus();
      }
    });
    notifyListeners();
  }

  void _onSessionComplete(int durationMinutes) {
    _focusCyclesCompleted++;
    _totalFocusedMinutes += durationMinutes;
    
    if (_isPomodoroMode) {
      // Start 5 min rest
      startRest(5);
    } else {
      stopFocus();
    }
  }

  void stopFocus() {
    _isFocusing = false;
    _isResting = false;
    _timer?.cancel();
    _remainingSeconds = _isPomodoroMode ? 25 * 60 : 30 * 60;
    
    NativeIntegration.stopPersistentService();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
