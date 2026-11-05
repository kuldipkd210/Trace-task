import 'appearance.dart';

class Config {
  int dayRolloverHour;
  int workStartHour;
  int workEndHour;
  int nudgeIntervalMinutes;
  int awayMinutes;
  int hudSeconds;
  int maxHUDsPerDay;
  int staleDays;
  int quietMinutes;
  int snoozeMinutes;
  String hotkey;
  AppAppearance appearance;

  Config({
    this.dayRolloverHour = 3,
    this.workStartHour = 9,
    this.workEndHour = 3,
    this.nudgeIntervalMinutes = 90,
    this.awayMinutes = 10,
    this.hudSeconds = 4,
    this.maxHUDsPerDay = 12,
    this.staleDays = 7,
    this.quietMinutes = 60,
    this.snoozeMinutes = 15,
    this.hotkey = 'option+space',
    this.appearance = AppAppearance.system,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayRolloverHour': dayRolloverHour,
      'workStartHour': workStartHour,
      'workEndHour': workEndHour,
      'nudgeIntervalMinutes': nudgeIntervalMinutes,
      'awayMinutes': awayMinutes,
      'hudSeconds': hudSeconds,
      'maxHUDsPerDay': maxHUDsPerDay,
      'staleDays': staleDays,
      'quietMinutes': quietMinutes,
      'snoozeMinutes': snoozeMinutes,
      'hotkey': hotkey,
      'appearance': appearance.toJson(),
    };
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    final d = Config();
    return Config(
      dayRolloverHour: json['dayRolloverHour'] as int? ?? d.dayRolloverHour,
      workStartHour: json['workStartHour'] as int? ?? d.workStartHour,
      workEndHour: json['workEndHour'] as int? ?? d.workEndHour,
      nudgeIntervalMinutes:
          json['nudgeIntervalMinutes'] as int? ?? d.nudgeIntervalMinutes,
      awayMinutes: json['awayMinutes'] as int? ?? d.awayMinutes,
      hudSeconds: json['hudSeconds'] as int? ?? d.hudSeconds,
      maxHUDsPerDay: json['maxHUDsPerDay'] as int? ?? d.maxHUDsPerDay,
      staleDays: json['staleDays'] as int? ?? d.staleDays,
      quietMinutes: json['quietMinutes'] as int? ?? d.quietMinutes,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? d.snoozeMinutes,
      hotkey: json['hotkey'] as String? ?? d.hotkey,
      appearance: json['appearance'] != null
          ? AppAppearance.fromJson(json['appearance'] as String)
          : d.appearance,
    );
  }

  Config copyWith({
    int? dayRolloverHour,
    int? workStartHour,
    int? workEndHour,
    int? nudgeIntervalMinutes,
    int? awayMinutes,
    int? hudSeconds,
    int? maxHUDsPerDay,
    int? staleDays,
    int? quietMinutes,
    int? snoozeMinutes,
    String? hotkey,
    AppAppearance? appearance,
  }) {
    return Config(
      dayRolloverHour: dayRolloverHour ?? this.dayRolloverHour,
      workStartHour: workStartHour ?? this.workStartHour,
      workEndHour: workEndHour ?? this.workEndHour,
      nudgeIntervalMinutes: nudgeIntervalMinutes ?? this.nudgeIntervalMinutes,
      awayMinutes: awayMinutes ?? this.awayMinutes,
      hudSeconds: hudSeconds ?? this.hudSeconds,
      maxHUDsPerDay: maxHUDsPerDay ?? this.maxHUDsPerDay,
      staleDays: staleDays ?? this.staleDays,
      quietMinutes: quietMinutes ?? this.quietMinutes,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      hotkey: hotkey ?? this.hotkey,
      appearance: appearance ?? this.appearance,
    );
  }
}

