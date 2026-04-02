import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/block_list.dart';
import '../utils/native_integration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class FocusProvider with ChangeNotifier {
  // Config state
  int _userFocusDurationSeconds = 30 * 60;
  bool _isPomodoroMode = true;
  bool _isStrictMode = false;
  bool _isAlarmEnabled = false;
  bool _isMusicEnabled = false;
  bool _isShuffleMusic = false;
  List<String> _musicPaths = [];
  
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  int _currentMusicIndex = 0;
  StreamSubscription? _onCompleteSubscription;
  
  // Block Lists
  List<BlockList> _blockLists = [];
  String _activeBlockListId = '';

  // Active state
  bool _isFocusing = false;
  bool _isResting = false;
  int _remainingSeconds = 30 * 60;
  Timer? _timer;
  bool _isAlarmRinging = false;
  Timer? _alarmAutoStopTimer;
  
  // Pomodoro tracking
  int _pomodoroElapsedSeconds = 0;
  int _savedFocusSeconds = 0;

  FocusProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load block lists
    final blockListsJson = prefs.getStringList('blockLists');
    if (blockListsJson != null && blockListsJson.isNotEmpty) {
      _blockLists = blockListsJson.map((e) => BlockList.fromJson(e)).toList();
    } else {
      // Setup default list (migrate old blacklisted apps if they exist)
      final oldSavedApps = prefs.getStringList('blacklistedApps');
      final defaultList = BlockList(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        name: '新封鎖清單1', 
        apps: oldSavedApps ?? []
      );
      _blockLists = [defaultList];
    }
    
    _activeBlockListId = prefs.getString('activeBlockListId') ?? _blockLists.first.id;
    // ensure active list exists
    if (!_blockLists.any((list) => list.id == _activeBlockListId)) {
        _activeBlockListId = _blockLists.first.id;
    }
    
    // Load stats
    _focusCyclesCompleted = prefs.getInt('focusCyclesCompleted') ?? 0;
    _totalFocusedMinutes = prefs.getInt('totalFocusedMinutes') ?? 0;
    _isPomodoroMode = prefs.getBool('isPomodoroMode') ?? true;
    _isStrictMode = prefs.getBool('isStrictMode') ?? false;
    _isAlarmEnabled = prefs.getBool('isAlarmEnabled') ?? false;
    _isMusicEnabled = prefs.getBool('isMusicEnabled') ?? false;
    _isShuffleMusic = prefs.getBool('isShuffleMusic') ?? false;
    _musicPaths = prefs.getStringList('musicPaths') ?? [];
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
            NativeIntegration.startPersistentService(getActiveBlockListApps(), _remainingSeconds);
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

  Future<void> _saveBlockLists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _blockLists.map((e) => e.toJson()).toList();
    await prefs.setStringList('blockLists', jsonList);
    await prefs.setString('activeBlockListId', _activeBlockListId);
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focusCyclesCompleted', _focusCyclesCompleted);
    await prefs.setInt('totalFocusedMinutes', _totalFocusedMinutes);
    await prefs.setBool('isPomodoroMode', _isPomodoroMode);
    await prefs.setBool('isStrictMode', _isStrictMode);
    await prefs.setBool('isAlarmEnabled', _isAlarmEnabled);
    await prefs.setBool('isMusicEnabled', _isMusicEnabled);
    await prefs.setBool('isShuffleMusic', _isShuffleMusic);
    await prefs.setStringList('musicPaths', _musicPaths);
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
  bool get isAlarmEnabled => _isAlarmEnabled;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isShuffleMusic => _isShuffleMusic;
  List<String> get musicPaths => List.unmodifiable(_musicPaths);
  bool get isAlarmRinging => _isAlarmRinging;
  int get currentMusicIndex => _currentMusicIndex;
  
  int get remainingSeconds => _remainingSeconds;
  int get userFocusDurationSeconds => _userFocusDurationSeconds;
  int get focusCyclesCompleted => _focusCyclesCompleted;
  int get totalFocusedMinutes => _totalFocusedMinutes;

  List<BlockList> get blockLists => _blockLists;
  String get activeBlockListId => _activeBlockListId;

  List<String> getActiveBlockListApps() {
    try {
      return _blockLists.firstWhere((list) => list.id == _activeBlockListId).apps;
    } catch (e) {
      return [];
    }
  }

  BlockList getBlockList(String id) {
    return _blockLists.firstWhere((list) => list.id == id, orElse: () => _blockLists.first);
  }

  void setActiveBlockList(String id) {
    if (!_isFocusing && !_isResting) {
        _activeBlockListId = id;
        _saveBlockLists();
        notifyListeners();
    }
  }

  String createBlockList() {
    int counter = 1;
    String newName = "新封鎖清單$counter";
    while (_blockLists.any((list) => list.name == newName)) {
      counter++;
      newName = "新封鎖清單$counter";
    }
    
    final newList = BlockList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName,
      apps: []
    );
    _blockLists.add(newList);
    _saveBlockLists();
    notifyListeners();
    return newList.id;
  }

  void updateBlockListName(String id, String newName) {
    final list = _blockLists.firstWhere((list) => list.id == id);
    // Only update if new name is unique or same as current
    if (newName.isNotEmpty && !_blockLists.any((l) => l.name == newName && l.id != id)) {
        list.name = newName;
        _saveBlockLists();
        notifyListeners();
    }
  }

  void deleteBlockList(String id) {
     if (_blockLists.length > 1 && !_isFocusing && !_isResting) {
         _blockLists.removeWhere((list) => list.id == id);
         if (_activeBlockListId == id) {
             _activeBlockListId = _blockLists.first.id;
         }
         _saveBlockLists();
         notifyListeners();
     }
  }

  void toggleAppInList(String listId, String packageName) {
    final list = _blockLists.firstWhere((list) => list.id == listId);
    if (list.apps.contains(packageName)) {
      list.apps.remove(packageName);
    } else {
      list.apps.add(packageName);
    }
    _saveBlockLists();
    notifyListeners();
  }

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

  void toggleAlarm() {
    _isAlarmEnabled = !_isAlarmEnabled;
    _saveStats();
    notifyListeners();
  }

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (!_isMusicEnabled) {
      _musicPlayer.stop();
    } else if (_isFocusing || _isResting) {
      if (_musicPaths.isNotEmpty) _playMusic();
    }
    _saveStats();
    notifyListeners();
  }

  void removeMusicPath(String path) {
    if (_musicPaths.contains(path)) {
      _musicPaths.remove(path);
      if ((_isFocusing || _isResting) && _isMusicEnabled) {
         _musicPlayer.stop();
         if (_musicPaths.isNotEmpty) {
            _playMusic();
         }
      }
      _saveStats();
      notifyListeners();
    }
  }

  void toggleShuffle() {
    _isShuffleMusic = !_isShuffleMusic;
    _saveStats();
    notifyListeners();
  }

  void setMusicPaths(List<String> paths) {
    _musicPaths = paths;
    _saveStats();
    notifyListeners();
  }

  void addMusicPaths(List<String> paths) {
    for (var p in paths) {
      if (!_musicPaths.contains(p)) {
        _musicPaths.add(p);
      }
    }
    _saveStats();
    notifyListeners();
  }

  void addMusicFromDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        List<String> newPaths = [];
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (var entity in entities) {
          if (entity is File) {
             final ext = entity.path.toLowerCase();
             if (ext.endsWith('.mp3') || ext.endsWith('.wav') || ext.endsWith('.m4a') || ext.endsWith('.aac') || ext.endsWith('.flac')) {
               if (!_musicPaths.contains(entity.path)) {
                 newPaths.add(entity.path);
               }
             }
          }
        }
        _musicPaths.addAll(newPaths);
        _saveStats();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error reading directory: $e");
    }
  }

  void stopAlarm() {
     _isAlarmRinging = false;
     _alarmPlayer.stop();
     _alarmAutoStopTimer?.cancel();
     notifyListeners();
  }

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<String> getBlockListApps(String blockListId) {
    try {
      return _blockLists.firstWhere((list) => list.id == blockListId).apps;
    } catch (e) {
      return getActiveBlockListApps();
    }
  }

  void startFocus([int? ignored]) {
    _isFocusing = true;
    _isResting = false;
    _remainingSeconds = _userFocusDurationSeconds;
    _pomodoroElapsedSeconds = 0;
    _timer?.cancel();
    
    NativeIntegration.startPersistentService(getActiveBlockListApps(), _remainingSeconds);

    _saveTimerState();
    _startInternalTimer();

    if (_isMusicEnabled && _musicPaths.isNotEmpty) {
      _playMusic();
    }

    notifyListeners();
  }

  void _playMusic() async {
    if (_musicPaths.isEmpty) return;
    
    if (_isShuffleMusic) {
      _currentMusicIndex = math.Random().nextInt(_musicPaths.length);
    } else {
      _currentMusicIndex = 0;
    }
    
    _playCurrentTrack();
    
    // Cancel old subscription to prevent duplicate listeners
    await _onCompleteSubscription?.cancel();
    _onCompleteSubscription = _musicPlayer.onPlayerComplete.listen((event) {
       if ((_isFocusing || _isResting) && _isMusicEnabled) {
         _playNextTrack();
       }
    });
  }

  void _playCurrentTrack({int retryCount = 0}) async {
    if (_musicPaths.isEmpty) return;
    // Guard against infinite recursion
    if (retryCount >= _musicPaths.length) {
      debugPrint("All music files are invalid, disabling music.");
      _isMusicEnabled = false;
      notifyListeners();
      return;
    }
    try {
      final file = File(_musicPaths[_currentMusicIndex]);
      if (!await file.exists()) {
        throw Exception("File not found");
      }
      await _musicPlayer.play(DeviceFileSource(_musicPaths[_currentMusicIndex]));
    } catch (e) {
      debugPrint("Error playing music: $e");
      // Remove missing file and try next
      _musicPaths.removeAt(_currentMusicIndex);
      _saveStats();
      if (_musicPaths.isEmpty) {
        _isMusicEnabled = false;
        notifyListeners();
        return;
      }
      if (_currentMusicIndex >= _musicPaths.length) {
        _currentMusicIndex = 0;
      }
      _playCurrentTrack(retryCount: retryCount + 1);
    }
  }

  void _playNextTrack() {
    if (_musicPaths.isEmpty) return;
    if (_isShuffleMusic) {
      _currentMusicIndex = math.Random().nextInt(_musicPaths.length);
    } else {
      _currentMusicIndex = (_currentMusicIndex + 1) % _musicPaths.length;
    }
    _playCurrentTrack();
  }

  void playSpecificTrack(int index) async {
    if (index >= 0 && index < _musicPaths.length) {
      _currentMusicIndex = index;
      _isShuffleMusic = false;
      _saveStats();
      
      if ((_isFocusing || _isResting) && _isMusicEnabled) {
         await _musicPlayer.stop();
         _playCurrentTrack();
      } else {
         _isMusicEnabled = true;
         await _musicPlayer.stop();
         _playCurrentTrack();
      }
      notifyListeners();
    }
  }

  void startScheduledFocus({required int durationSeconds, String? blockListId}) {
    _isFocusing = true;
    _isResting = false;
    _remainingSeconds = durationSeconds;
    _pomodoroElapsedSeconds = 0;
    _timer?.cancel();

    // Use the schedule's block list if specified, otherwise use active list
    final appsToBlock = (blockListId != null)
        ? getBlockListApps(blockListId)
        : getActiveBlockListApps();

    NativeIntegration.startPersistentService(appsToBlock, _remainingSeconds);

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
     
     // Stop focus FIRST, then trigger alarm so alarm UI state is not overwritten
     stopFocus();
     
     if (_isAlarmEnabled) {
       _triggerAlarm();
     }
  }

  void _triggerAlarm() async {
    _isAlarmRinging = true;
    notifyListeners();
    
    try {
      // Loop alarm sound (using a default system sound or simple asset)
      // Since we don't have assets yet, we'll try to find a system sound or just use audioplayers with logic
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      // Play the retro mechanical twin-bell alarm
      await _alarmPlayer.play(AssetSource('retro_alarm.wav'));
    } catch (e) {
      debugPrint("Alarm error: $e");
    }

    _alarmAutoStopTimer = Timer(const Duration(minutes: 5), () {
      stopAlarm();
    });
  }

  void _onRestComplete() {
      // Rest is over, resume focus!
      _isFocusing = true;
      _isResting = false;
      _pomodoroElapsedSeconds = 0;
      _remainingSeconds = _savedFocusSeconds;
      NativeIntegration.startPersistentService(getActiveBlockListApps(), _remainingSeconds);
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
    
    _musicPlayer.stop();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alarmAutoStopTimer?.cancel();
    _onCompleteSubscription?.cancel();
    _musicPlayer.dispose();
    _alarmPlayer.dispose();
    super.dispose();
  }
}
