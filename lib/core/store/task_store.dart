import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/bucket.dart';
import '../models/date_pick.dart';
import '../models/flex.dart';
import '../models/item.dart';
import '../models/sections.dart';
import '../parser/parser.dart';
import '../time/day.dart';
import '../time/day_calendar.dart';

class TaskStore extends ChangeNotifier {
  List<Item> _items = [];
  String? _saveError;

  final TackClock clock;
  final DayCalendar cal;
  final File? file;
  final Directory? backupDir;

  final List<List<Item>> _undoStack = [];
  Day? _lastBackupDay;

  static const int undoLimit = 50;
  static const int backupsKept = 14;
  static const int doneRetentionDays = 90;

  List<Item> get items => List.unmodifiable(_items);
  String? get saveError => _saveError;

  TaskStore({
    this.file,
    this.backupDir,
    required this.clock,
    required this.cal,
  }) {
    _load();
  }

  Item? item(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // MARK: - Mutations

  Item add(ParsedTask parsed, {Bucket? bucket}) {
    final now = clock.now;
    var newItem = Item(
      title: parsed.title,
      due: parsed.due,
      dueAt: parsed.dueAt,
      flex: parsed.flex,
      hasExplicitDate: parsed.hasDate || parsed.dueAt != null,
      createdAt: now,
    );

    if (bucket != null) {
      _place(newItem, bucket);
    }

    _mutate((items) => items.add(newItem));
    return newItem;
  }

  void markDone(String id) {
    _change(id, (item) => item.doneAt = clock.now);
  }

  void delete(String id) {
    _mutate((items) => items.removeWhere((i) => i.id == id));
  }

  void move(String id, Bucket bucket) {
    _change(id, (item) => _place(item, bucket));
  }

  void setDate(String id, DatePick pick) {
    final resolved = pick.resolve(cal);
    _change(id, (item) {
      item.due = resolved.due;
      item.dueAt = resolved.dueAt;
      item.flex = Flex.none;
      item.hasExplicitDate = true;
      item.snoozedUntil = null;
      item.plannedAt = clock.now;
    });
  }

  void togglePin(String id) {
    _change(id, (item) {
      item.pinned = !item.pinned;
    });
  }

  void reorder(String movedId, String targetId, {bool insertBefore = true}) {
    if (movedId == targetId) return;

    _mutate((items) {
      final movedIdx = items.indexWhere((i) => i.id == movedId);
      final targetIdx = items.indexWhere((i) => i.id == targetId);
      if (movedIdx == -1 || targetIdx == -1) return;

      final moved = items[movedIdx];
      final target = items[targetIdx];

      final today = cal.dayOf(clock.now);
      if (target.pinned && !moved.pinned) {
        moved.pinned = true;
      } else if (!target.pinned && moved.pinned) {
        moved.pinned = false;
        _place(moved, Sections.bucketOf(target, today, cal));
      } else if (!target.pinned && !moved.pinned) {
        final targetBucket = Sections.bucketOf(target, today, cal);
        final movedBucket = Sections.bucketOf(moved, today, cal);
        if (targetBucket != movedBucket) {
          _place(moved, targetBucket);
        }
      }

      // Reorder items directly in items list
      items.removeAt(movedIdx);
      final newTargetIdx = items.indexWhere((i) => i.id == targetId);
      final insertIdx = (insertBefore ? newTargetIdx : newTargetIdx + 1).clamp(0, items.length);
      items.insert(insertIdx, moved);

      // Update explicit sortOrder on all items
      for (var i = 0; i < items.length; i++) {
        items[i].sortOrder = i.toDouble();
      }
    });
  }

  void snooze(String id, int minutes) {
    _change(id, (item) {
      item.snoozedUntil = clock.now.add(Duration(minutes: minutes));
    });
  }

  void edit(String id, ParsedTask parsed, {Bucket? bucket}) {
    _change(id, (item) {
      item.title = parsed.title;
      if (parsed.hasDate || parsed.dueAt != null) {
        item.due = parsed.due;
        item.dueAt = parsed.dueAt;
        item.flex = parsed.flex;
        item.hasExplicitDate = true;
        item.snoozedUntil = null;
        item.plannedAt = clock.now;
      }
      if (bucket != null) {
        _place(item, bucket);
      }
    });
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    _items = _undoStack.removeLast();
    _persist();
    notifyListeners();
    return true;
  }

  // MARK: - Internals

  void _place(Item item, Bucket bucket) {
    final today = cal.dayOf(clock.now);
    item.dueAt = null;
    item.snoozedUntil = null;
    item.plannedAt = clock.now;

    switch (bucket) {
      case Bucket.today:
        item.due = today;
        item.flex = Flex.none;
      case Bucket.week:
        item.flex = Flex.week;
        item.due = Parser.flexDue(Flex.week, today, cal);
      case Bucket.month:
        item.flex = Flex.month;
        item.due = Parser.flexDue(Flex.month, today, cal);
    }
  }

  void _change(String id, void Function(Item) mutateItem) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _mutate((items) => mutateItem(items[index]));
  }

  void _mutate(void Function(List<Item>) action) {
    // Clone for undo stack
    _undoStack.add(_items.map((i) => i.copyWith()).toList());
    if (_undoStack.length > undoLimit) {
      _undoStack.removeAt(0);
    }

    final next = _items.map((i) => i.copyWith()).toList();
    action(next);
    _items = next;
    _persist();
    notifyListeners();
  }

  void _persist() {
    if (file == null) return;
    try {
      final data = {
        'version': 1,
        'items': _items.map((i) => i.toJson()).toList(),
      };
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(data);

      // Atomic write via temp file
      final tempFile = File('${file!.path}.tmp');
      tempFile.writeAsStringSync(jsonString, flush: true);
      tempFile.renameSync(file!.path);

      _saveError = null;
      _backupIfNeeded();
    } catch (e) {
      _saveError = 'TraceTask could not save: $e';
    }
  }

  void _backupIfNeeded() {
    if (backupDir == null || file == null) return;
    final today = cal.dayOf(clock.now);
    if (_lastBackupDay == today) return;
    _lastBackupDay = today;

    try {
      if (!backupDir!.existsSync()) backupDir!.createSync(recursive: true);
      final target = File(p.join(backupDir!.path, 'tasks-$today.json'));
      if (!target.existsSync()) {
        file!.copySync(target.path);
      }

      final backups = _sortedBackups();
      if (backups.length > backupsKept) {
        for (final old in backups.sublist(0, backups.length - backupsKept)) {
          try {
            old.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  List<File> _sortedBackups() {
    if (backupDir == null || !backupDir!.existsSync()) return [];
    return backupDir!
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = p.basename(f.path);
          return name.startsWith('tasks-') && name.endsWith('.json');
        })
        .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  }

  void _load() {
    if (file == null || !file!.existsSync()) return;
    try {
      final raw = file!.readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final rawItems = (map['items'] as List<dynamic>)
          .map((itemJson) => Item.fromJson(itemJson as Map<String, dynamic>))
          .toList();
      _items = _prune(rawItems);
    } catch (e) {
      // Corrupt file handling
      final corruptFile = File(
        '${file!.path}.corrupt-${clock.now.millisecondsSinceEpoch}.json',
      );
      try {
        file!.renameSync(corruptFile.path);
      } catch (_) {}

      final backups = _sortedBackups().reversed.toList();
      for (final backup in backups) {
        try {
          final raw = backup.readAsStringSync();
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final rawItems = (map['items'] as List<dynamic>)
              .map((itemJson) => Item.fromJson(itemJson as Map<String, dynamic>))
              .toList();
          _items = _prune(rawItems);
          break;
        } catch (_) {}
      }

      _saveError =
          'tasks.json was unreadable. Restored latest backup and preserved corrupt file as ${p.basename(corruptFile.path)}';
    }
  }

  List<Item> _prune(List<Item> loaded) {
    final cutoff = clock.now.subtract(const Duration(days: doneRetentionDays));
    return loaded.where((item) {
      if (item.doneAt == null) return true;
      return item.doneAt!.isAfter(cutoff);
    }).toList();
  }
}

