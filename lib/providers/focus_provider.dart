import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/native_integration.dart';

class FocusProvider with ChangeNotifier {
  // Config state
  int _userFocusDurationSeconds = 30 * 60;
  bool _isPomodoroMode = true;
  bool _isStrictMode = false;
  Set<String> _blacklistedApps = {};

  // Active state
  bool _isFocusing = false;
  bool _isResting = false;
  int _remainingSeconds = 30 * 60;
  Timer? _timer;
  
  // Pomodoro tracking
  int _pomodoroElapsedSeconds = 0;
  int _savedFocusSeconds = 0;

  FocusProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load blacklisted apps
    final savedApps = prefs.getStringList('blacklistedApps');
    if (savedApps != null) {
      _blacklistedApps = savedApps.toSet();
    }
    
    // Load stats
    _focusCyclesCompleted = prefs.getInt('focusCyclesCompleted') ?? 0;
    _totalFocusedMinutes = prefs.getInt('totalFocusedMinutes') ?? 0;
    _isPomodoroMode = prefs.getBool('isPomodoroMode') ?? true;
    _isStrictMode = prefs.getBool('isStrictMode') ?? false;
    _userFocusDurationSeconds = prefs.getInt('userFocusDurationSeconds') ?? 30 * 60;

    final isFocusing = prefs.getBool('isFocusing') ?? false;
    final isResting = prefs.getBool('isResting') ?? false;
    final endTimeMillis = prefs.getInt('endTime');
    final pElapsed = prefs.getInt('pomodoroElapsedSeconds') ?? 0;
    final savedFocus = prefs.getInt('savedFocusSeconds') ?? 0;

    if (!isFocusing && !isResting) {
        _remainingSeconds = _userFocusDurationSeconds;
    } else if (endTimeMillis != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final now = DateTime.now();
      final diffSeconds = endTime.difference(now).inSeconds;

      if (diffSeconds > 0) {
        _isFocusing = isFocusing;
        _isResting = isResting;
        _remainingSeconds = diffSeconds;
        _pomodoroElapsedSeconds = pElapsed;
        _savedFocusSeconds = savedFocus;
        
        if (_isFocusing) {
            final remainingAtSave = prefs.getInt('remainingSecondsAtSave') ?? diffSeconds;
            final passed = remainingAtSave - diffSeconds;
            if (passed > 0) {
                _pomodoroElapsedSeconds += passed;
            }
            NativeIntegration.startPersistentService(_blacklistedApps.toList());
        }
        
        _startInternalTimer();
      } else {
        if (isFocusing || isResting) {
           _focusCyclesCompleted++;
           _totalFocusedMinutes += (_userFocusDurationSeconds ~/ 60);
           _saveStats();
        }
        _clearTimerState();
        _remainingSeconds = _userFocusDurationSeconds;
      }
    } else {
       _remainingSeconds = _userFocusDurationSeconds;
    }
    notifyListeners();
  }

  Future<void> _saveBlacklistedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blacklistedApps', _blacklistedApps.toList());
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focusCyclesCompleted', _focusCyclesCompleted);
    await prefs.setInt('totalFocusedMinutes', _totalFocusedMinutes);
    await prefs.setBool('isPomodoroMode', _isPomodoroMode);
    await prefs.setBool('isStrictMode', _isStrictMode);
    await prefs.setInt('userFocusDurationSeconds', _userFocusDurationSeconds);
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFocusing', _isFocusing);
    await prefs.setBool('isResting', _isResting);
    await prefs.setInt('pomodoroElapsedSeconds', _pomodoroElapsedSeconds);
    await prefs.setInt('savedFocusSeconds', _savedFocusSeconds);
    await prefs.setInt('remainingSecondsAtSave', _remainingSeconds);
    
    final endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    await prefs.setInt('endTime', endTime.millisecondsSinceEpoch);
  }

  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFocusing');
    await prefs.remove('isResting');
    await prefs.remove('endTime');
    await prefs.remove('pomodoroElapsedSeconds');
    await prefs.remove('savedFocusSeconds');
    await prefs.remove('remainingSecondsAtSave');
  }

  // Stats
  int _focusCyclesCompleted = 0;
  int _totalFocusedMinutes = 0;

  bool get isFocusing => _isFocusing;
  bool get isResting => _isResting;
  bool get isPomodoroMode => _isPomodoroMode;
  bool get isStrictMode => _isStrictMode;
  int get remainingSeconds => _remainingSeconds;
  int get userFocusDurationSeconds => _userFocusDurationSeconds;
  Set<String> get blacklistedApps => _blacklistedApps;
  int get focusCyclesCompleted => _focusCyclesCompleted;
  int get totalFocusedMinutes => _totalFocusedMinutes;

  void setUserFocusDuration(int minutes, int seconds) {
    if (!_isFocusing && !_isResting) {
      _userFocusDurationSeconds = minutes * 60 + seconds;
      _remainingSeconds = _userFocusDurationSeconds;
      _saveStats();
      notifyListeners();
    }
  }

  void togglePomodoroMode() {
    if (!_isFocusing && !_isResting) {
      _isPomodoroMode = !_isPomodoroMode;
      _saveStats();
      notifyListeners();
    }
  }

  void toggleStrictMode() {
    if (!_isFocusing && !_isResting) {
      _isStrictMode = !_isStrictMode;
      _saveStats();
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

  void startFocus([int? ignored]) {
    _isFocusing = true;
    _isResting = false;
    _remainingSeconds = _userFocusDurationSeconds;
    _pomodoroElapsedSeconds = 0;
    _timer?.cancel();
    
    NativeIntegration.startPersistentService(_blacklistedApps.toList());

    _saveTimerState();
    _startInternalTimer();
    notifyListeners();
  }
  
  void _startInternalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      
      if (_isFocusing && _isPomodoroMode) {
        _pomodoroElapsedSeconds++;
        if (_pomodoroElapsedSeconds >= 25 * 60 && _remainingSeconds > 0) {
          // Switch to rest
          _isFocusing = false;
          _isResting = true;
          _pomodoroElapsedSeconds = 0;
          _savedFocusSeconds = _remainingSeconds;
          _remainingSeconds = 5 * 60; // 5 min rest
          NativeIntegration.stopPersistentService();
          _saveTimerState();
          notifyListeners();
          return;
        }
      }
      notifyListeners();
    } else {
      if (_isFocusing) {
        _onFocusComplete();
      } else if (_isResting) {
        _onRestComplete();
      }
    }
  }

  void _onFocusComplete() {
     _focusCyclesCompleted++;
     _totalFocusedMinutes += (_userFocusDurationSeconds ~/ 60);
     _saveStats();
     
     _clearTimerState();
     stopFocus();
  }

  void _onRestComplete() {
      // Rest is over, resume focus!
      _isFocusing = true;
      _isResting = false;
      _pomodoroElapsedSeconds = 0;
      _remainingSeconds = _savedFocusSeconds;
      NativeIntegration.startPersistentService(_blacklistedApps.toList());
      _saveTimerState();
      notifyListeners();
  }

  void stopFocus() {
    _isFocusing = false;
    _isResting = false;
    _timer?.cancel();
    _remainingSeconds = _userFocusDurationSeconds;
    _pomodoroElapsedSeconds = 0;
    
    NativeIntegration.stopPersistentService();
    _clearTimerState();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
