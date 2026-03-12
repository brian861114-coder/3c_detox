class FocusSchedule {
  final String id;
  final List<int> weekdays; // 1 = Monday, 7 = Sunday
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int durationMinutes;
  final String? blockListId; // optional: which block list to use
  final bool isEnabled; // whether this schedule is active
  final bool blockListChanged; // flag: associated block list was modified/deleted

  FocusSchedule({
    required this.id,
    required this.weekdays,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    this.blockListId,
    this.isEnabled = true,
    this.blockListChanged = false,
  });

  FocusSchedule copyWith({
    String? id,
    List<int>? weekdays,
    int? startHour,
    int? startMinute,
    int? durationMinutes,
    String? blockListId,
    bool? isEnabled,
    bool? blockListChanged,
  }) {
    return FocusSchedule(
      id: id ?? this.id,
      weekdays: weekdays ?? this.weekdays,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      blockListId: blockListId ?? this.blockListId,
      isEnabled: isEnabled ?? this.isEnabled,
      blockListChanged: blockListChanged ?? this.blockListChanged,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekdays': weekdays,
        'startHour': startHour,
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
        'blockListId': blockListId,
        'isEnabled': isEnabled,
        'blockListChanged': blockListChanged,
      };

  factory FocusSchedule.fromJson(Map<String, dynamic> json) {
    return FocusSchedule(
      id: json['id'],
      weekdays: List<int>.from(json['weekdays']),
      startHour: json['startHour'],
      startMinute: json['startMinute'],
      durationMinutes: json['durationMinutes'],
      blockListId: json['blockListId'],
      isEnabled: json['isEnabled'] ?? true,
      blockListChanged: json['blockListChanged'] ?? false,
    );
  }
}
