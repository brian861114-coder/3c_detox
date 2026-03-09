import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'pomodoro_mode': 'Pomodoro Mode',
      'resting': 'Resting...',
      'focus_active': 'Focus Mode Active',
      'ready_to_focus': 'Ready to Focus?',
      'start_focus': 'START FOCUS',
      'give_up': 'GIVE UP',
      'focus_stats': 'Focus Stats',
      'total_focused_time': 'Total Focused Time',
      'pomodoro_sessions': 'Pomodoro Sessions',
      'choose_apps_to_block': 'Choose Apps to Block',
      'minutes': 'minutes',
      'completed': 'completed',
    },
    'zh': {
      'pomodoro_mode': '番茄鐘模式',
      'resting': '休息中...',
      'focus_active': '專注模式運行中',
      'ready_to_focus': '準備好專注了嗎？',
      'start_focus': '開始專注',
      'give_up': '放棄',
      'focus_stats': '專注統計',
      'total_focused_time': '總專注時間',
      'pomodoro_sessions': '已完成番茄鐘',
      'choose_apps_to_block': '選擇要封鎖的應用程式',
      'minutes': '分鐘',
      'completed': '次',
    },
    'ja': {
      'pomodoro_mode': 'ポモドーロモード',
      'resting': '休憩中...',
      'focus_active': '集中モード実行中',
      'ready_to_focus': '集中する準備はできましたか？',
      'start_focus': '集中を開始',
      'give_up': 'あきらめる',
      'focus_stats': '集中統計',
      'total_focused_time': '総集中時間',
      'pomodoro_sessions': '完了したポモドーロ',
      'choose_apps_to_block': 'ブロックするアプリを選択',
      'minutes': '分',
      'completed': '回',
    },
  };

  void changeLanguage(String languageCode) async {
    if (_localizedStrings.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('language_code');
    if (savedCode != null && _localizedStrings.containsKey(savedCode)) {
      _currentLanguage = savedCode;
      notifyListeners();
    }
  }

  String translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ?? key;
  }
}
