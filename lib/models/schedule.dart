class FocusSchedule {
  final String id;
  final List<int> weekdays; // 1 = Monday, 7 = Sunday
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int durationMinutes;

  FocusSchedule({
    required this.id,
    required this.weekdays,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekdays': weekdays,
        'startHour': startHour,
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
      };

  factory FocusSchedule.fromJson(Map<String, dynamic> json) {
    return FocusSchedule(
      id: json['id'],
      weekdays: List<int>.from(json['weekdays']),
      startHour: json['startHour'],
      startMinute: json['startMinute'],
      durationMinutes: json['durationMinutes'],
    );
  }
}
