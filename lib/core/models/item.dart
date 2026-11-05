import 'package:uuid/uuid.dart';
import '../time/day.dart';
import 'flex.dart';

class Item {
  String id;
  String title;
  Day due;
  DateTime? dueAt;
  Flex flex;
  DateTime createdAt;
  DateTime plannedAt;
  DateTime? doneAt;
  bool pinned;
  DateTime? snoozedUntil;

  Item({
    String? id,
    required this.title,
    required this.due,
    this.dueAt,
    this.flex = Flex.none,
    required this.createdAt,
    DateTime? plannedAt,
    this.doneAt,
    this.pinned = false,
    this.snoozedUntil,
  })  : id = id ?? const Uuid().v4(),
        plannedAt = plannedAt ?? createdAt;

  bool get isOpen => doneAt == null;

  /// A timed task whose time has passed and is not snoozed.
  bool hasFired(DateTime now) {
    if (!isOpen || dueAt == null) return false;
    if (dueAt!.isAfter(now)) return false;
    if (snoozedUntil != null && snoozedUntil!.isAfter(now)) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'due': due.toJson(),
      'dueAt': dueAt?.toUtc().toIso8601String(),
      'flex': flex.toJson(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'plannedAt': plannedAt.toUtc().toIso8601String(),
      'doneAt': doneAt?.toUtc().toIso8601String(),
      'pinned': pinned,
      'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.parse(value as String).toLocal();
    }

    return Item(
      id: json['id'] as String,
      title: json['title'] as String,
      due: Day.fromJson(json['due']),
      dueAt: parseDate(json['dueAt']),
      flex: Flex.fromJson(json['flex'] as String? ?? 'none'),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      plannedAt: parseDate(json['plannedAt']),
      doneAt: parseDate(json['doneAt']),
      pinned: json['pinned'] as bool? ?? false,
      snoozedUntil: parseDate(json['snoozedUntil']),
    );
  }

  Item copyWith({
    String? id,
    String? title,
    Day? due,
    DateTime? dueAt,
    Flex? flex,
    DateTime? createdAt,
    DateTime? plannedAt,
    DateTime? doneAt,
    bool? pinned,
    DateTime? snoozedUntil,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      due: due ?? this.due,
      dueAt: dueAt ?? this.dueAt,
      flex: flex ?? this.flex,
      createdAt: createdAt ?? this.createdAt,
      plannedAt: plannedAt ?? this.plannedAt,
      doneAt: doneAt ?? this.doneAt,
      pinned: pinned ?? this.pinned,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          due == other.due &&
          dueAt == other.dueAt &&
          flex == other.flex &&
          createdAt == other.createdAt &&
          plannedAt == other.plannedAt &&
          doneAt == other.doneAt &&
          pinned == other.pinned &&
          snoozedUntil == other.snoozedUntil;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        due,
        dueAt,
        flex,
        createdAt,
        plannedAt,
        doneAt,
        pinned,
        snoozedUntil,
      );
}

