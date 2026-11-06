import 'package:uuid/uuid.dart';
import '../time/day.dart';
import 'flex.dart';

class Item {
  String id;
  String title;
  Day due;
  DateTime? dueAt;
  Flex flex;
  bool hasExplicitDate;
  DateTime createdAt;
  DateTime plannedAt;
  DateTime? doneAt;
  bool pinned;
  DateTime? snoozedUntil;
  double? sortOrder;

  Item({
    String? id,
    required this.title,
    required this.due,
    this.dueAt,
    this.flex = Flex.none,
    this.hasExplicitDate = false,
    required this.createdAt,
    DateTime? plannedAt,
    this.doneAt,
    this.pinned = false,
    this.snoozedUntil,
    this.sortOrder,
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

  /// A task is delayed only if it has an explicit date or time mentioned by the user
  /// and that deadline has passed. Plain tasks without date/time are never delayed.
  bool isDelayed(DateTime now, Day today) {
    if (!isOpen) return false;
    if (dueAt != null) {
      if (hasFired(now) || dueAt!.isBefore(now)) return true;
    }
    if (hasExplicitDate && due < today) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'due': due.toJson(),
      'dueAt': dueAt?.toUtc().toIso8601String(),
      'flex': flex.toJson(),
      'hasExplicitDate': hasExplicitDate,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'plannedAt': plannedAt.toUtc().toIso8601String(),
      'doneAt': doneAt?.toUtc().toIso8601String(),
      'pinned': pinned,
      'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
      'sortOrder': sortOrder,
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
      hasExplicitDate: json['hasExplicitDate'] as bool? ?? (json['dueAt'] != null),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      plannedAt: parseDate(json['plannedAt']),
      doneAt: parseDate(json['doneAt']),
      pinned: json['pinned'] as bool? ?? false,
      snoozedUntil: parseDate(json['snoozedUntil']),
      sortOrder: (json['sortOrder'] as num?)?.toDouble(),
    );
  }

  Item copyWith({
    String? id,
    String? title,
    Day? due,
    DateTime? dueAt,
    Flex? flex,
    bool? hasExplicitDate,
    DateTime? createdAt,
    DateTime? plannedAt,
    DateTime? doneAt,
    bool? pinned,
    DateTime? snoozedUntil,
    double? sortOrder,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      due: due ?? this.due,
      dueAt: dueAt ?? this.dueAt,
      flex: flex ?? this.flex,
      hasExplicitDate: hasExplicitDate ?? this.hasExplicitDate,
      createdAt: createdAt ?? this.createdAt,
      plannedAt: plannedAt ?? this.plannedAt,
      doneAt: doneAt ?? this.doneAt,
      pinned: pinned ?? this.pinned,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      sortOrder: sortOrder ?? this.sortOrder,
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
          snoozedUntil == other.snoozedUntil &&
          sortOrder == other.sortOrder;

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

