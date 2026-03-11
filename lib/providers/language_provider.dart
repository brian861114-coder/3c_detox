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
      'strict_mode': 'Strict Mode',
      'set_focus_time': 'Set Focus Time',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'schedules': 'Schedules',
      'add_schedule': 'Add Schedule',
      'duration': 'Duration',
      'day_1': 'Mon',
      'day_2': 'Tue',
      'day_3': 'Wed',
      'day_4': 'Thu',
      'day_5': 'Fri',
      'day_6': 'Sat',
      'day_7': 'Sun',
      'perm_title': 'Required Permissions',
      'perm_desc': 'To ensure FocusFlow can properly lock your phone and prevent distractions, please grant the following 3 permissions. Click each button below to go to settings:',
      'perm_overlay': '1. Display over other apps',
      'perm_usage': '2. Usage Data Access',
      'perm_battery': '3. Unrestricted Battery',
      'perm_done': 'I have granted all permissions',
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
      'strict_mode': '嚴格模式',
      'set_focus_time': '設定專注時間',
      'cancel': '取消',
      'confirm': '確認',
      'schedules': '排程',
      'add_schedule': '新增排程',
      'duration': '持續時間',
      'day_1': '一',
      'day_2': '二',
      'day_3': '三',
      'day_4': '四',
      'day_5': '五',
      'day_6': '六',
      'day_7': '日',
      'perm_title': '需要授權',
      'perm_desc': '為了確保 FocusFlow 能夠在您專注時鎖定手機並防止干擾，請務必授予以下 3 項權限。請點擊下方按鈕前往設定：',
      'perm_overlay': '1. 顯示於上方',
      'perm_usage': '2. 使用量資料存取',
      'perm_battery': '3. 電池不受限制',
      'perm_done': '我已完成上述所有授權',
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
      'strict_mode': '厳格モード',
      'set_focus_time': '集中時間を設定',
      'cancel': 'キャンセル',
      'confirm': '確認',
      'schedules': 'スケジュール',
      'add_schedule': 'スケジュールを追加',
      'duration': '期間',
      'day_1': '月',
      'day_2': '火',
      'day_3': '水',
      'day_4': '木',
      'day_5': '金',
      'day_6': '土',
      'day_7': '日',
      'perm_title': '必要な権限',
      'perm_desc': 'FocusFlow が適切に電話をロックし、気を散らすものを防ぐために、以下の3つの権限を付与してください。下の各ボタンをクリックして設定に移動します：',
      'perm_overlay': '1. 他のアプリの上に表示',
      'perm_usage': '2. 使用状況データへのアクセス',
      'perm_battery': '3. バッテリーの最適化の対象外',
      'perm_done': 'すべての権限を付与しました',
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
