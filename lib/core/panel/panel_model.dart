import 'package:flutter/foundation.dart';
import '../config/config.dart';
import '../models/bucket.dart';
import '../models/date_pick.dart';
import '../models/flex.dart';
import '../models/item.dart';
import '../models/ranker.dart';
import '../models/sections.dart';
import '../parser/parser.dart';
import '../store/task_store.dart';
import '../time/day.dart';
import '../time/day_calendar.dart';

enum PanelEffect { none, close }

class TaskRow {
  final Item item;
  final bool isStale;
  final int overdueDays;

  String get id => item.id;

  const TaskRow({
    required this.item,
    required this.isStale,
    required this.overdueDays,
  });
}

class TaskGroup {
  final Bucket bucket;
  final List<TaskRow> rows;

  int get id => bucket.id;

  const TaskGroup({required this.bucket, required this.rows});
}

class PanelModel extends ChangeNotifier {
  final TaskStore store;
  Config config;

  String _text = '';
  String? _selectedID;
  String? _editingID;
  Bucket? _bucketOverride;
  DatePick? _datePick;
  DatePick? _dateOverride;
  bool _showingShortcuts = false;
  final bool _reviewMode = false;
  bool _isListening = false;
  String? _dictationError;

  PanelModel({
    required this.store,
    required this.config,
  }) {
    store.addListener(_onStoreUpdated);
    _ensureSelection();
  }

  void _onStoreUpdated() {
    _ensureSelection();
    notifyListeners();
  }

  void _ensureSelection() {
    final ids = flatIDs;
    if (ids.isEmpty) {
      _selectedID = null;
    } else if (_selectedID == null || !ids.contains(_selectedID)) {
      _selectedID = ids.first;
    }
  }

  @override
  void dispose() {
    store.removeListener(_onStoreUpdated);
    super.dispose();
  }

  // MARK: - Getters

  String get text => _text;
  String? get selectedID => _selectedID;
  String? get editingID => _editingID;
  Bucket? get bucketOverride => _bucketOverride;
  DatePick? get datePick => _datePick;
  DatePick? get dateOverride => _dateOverride;
  bool get showingShortcuts => _showingShortcuts;
  bool get reviewMode => _reviewMode;
  bool get isListening => _isListening;
  String? get dictationError => _dictationError;

  TackClock get clock => store.clock;
  DayCalendar get cal => store.cal;

  List<TaskGroup> get groups {
    final now = clock.now;
    final today = cal.dayOf(now);

    TaskRow toRow(Item item) {
      final inToday = Sections.bucketOf(item, today, cal) == Bucket.today;
      return TaskRow(
        item: item,
        isStale: inToday && Sections.isStale(item, today, config.staleDays, cal),
        overdueDays: Sections.overdueDays(item, today, cal),
      );
    }

    return [
      TaskGroup(
        bucket: Bucket.today,
        rows: Ranker.today(store.items, now, cal).map(toRow).toList(),
      ),
      TaskGroup(
        bucket: Bucket.week,
        rows: Ranker.later(store.items, Bucket.week, now, cal).map(toRow).toList(),
      ),
      TaskGroup(
        bucket: Bucket.month,
        rows: Ranker.later(store.items, Bucket.month, now, cal).map(toRow).toList(),
      ),
    ];
  }

  List<String> get flatIDs => groups.expand((g) => g.rows.map((r) => r.id)).toList();

  String? get preview {
    final trimmed = _text.trim();
    if (trimmed.isEmpty) return null;
    final now = clock.now;

    if (_datePick == null && _bucketOverride != null) {
      return '→ ${_bucketOverride!.title}';
    }

    final parsed = _parsedInput(trimmed, override: _datePick ?? _dateOverride);
    if (_editingID != null && !parsed.hasDate) {
      return 'Editing. Date stays the same';
    }
    return Parser.label(parsed, now, cal);
  }

  // MARK: - Actions

  void setText(String value) {
    _text = value;
    notifyListeners();
  }

  void setBucketOverride(Bucket? bucket) {
    _bucketOverride = bucket;
    _dateOverride = null;
    notifyListeners();
  }

  void openDatePick({DateTime? initialDate, bool hasTime = false}) {
    final now = clock.now;
    _datePick = DatePick(
      date: initialDate ?? now,
      hasTime: hasTime,
    );
    notifyListeners();
  }

  void updateDatePick(DatePick pick) {
    _datePick = pick;
    notifyListeners();
  }

  void cancelDatePick() {
    _datePick = null;
    notifyListeners();
  }

  void commitDatePick() {
    if (_datePick == null) return;
    if (_text.trim().isNotEmpty) {
      _dateOverride = _datePick;
      _bucketOverride = null;
    } else if (_selectedID != null) {
      store.setDate(_selectedID!, _datePick!);
    }
    _datePick = null;
    notifyListeners();
  }

  void toggleShortcuts() {
    _showingShortcuts = !_showingShortcuts;
    notifyListeners();
  }

  void selectNext() {
    final ids = flatIDs;
    if (ids.isEmpty) return;
    if (_selectedID == null || !ids.contains(_selectedID)) {
      _selectedID = ids.first;
    } else {
      final index = ids.indexOf(_selectedID!);
      if (index < ids.length - 1) {
        _selectedID = ids[index + 1];
      }
    }
    notifyListeners();
  }

  void selectPrevious() {
    final ids = flatIDs;
    if (ids.isEmpty) return;
    if (_selectedID == null || !ids.contains(_selectedID)) {
      _selectedID = ids.last;
    } else {
      final index = ids.indexOf(_selectedID!);
      if (index > 0) {
        _selectedID = ids[index - 1];
      }
    }
    notifyListeners();
  }

  void selectID(String? id) {
    _selectedID = id;
    notifyListeners();
  }

  void startEditing(String id) {
    final target = store.item(id);
    if (target == null) return;
    _editingID = id;
    _text = target.title;
    _selectedID = id;
    notifyListeners();
  }

  void cancelEditing() {
    _editingID = null;
    _text = '';
    notifyListeners();
  }

  PanelEffect submit() {
    final trimmed = _text.trim();
    if (trimmed.isEmpty) return PanelEffect.none;

    final parsed = _parsedInput(trimmed, override: _datePick ?? _dateOverride);
    if (_editingID != null) {
      store.edit(_editingID!, parsed, bucket: _bucketOverride);
      _selectedID = _editingID;
      _editingID = null;
    } else {
      final added = store.add(parsed, bucket: _bucketOverride);
      _selectedID = added.id;
    }

    _text = '';
    _bucketOverride = null;
    _dateOverride = null;
    _datePick = null;
    notifyListeners();
    return PanelEffect.close;
  }

  void markSelectedDone() {
    if (_selectedID != null) {
      markDone(_selectedID!);
    }
  }

  void markDone(String id) {
    final ids = flatIDs;
    final index = ids.indexOf(id);
    store.markDone(id);
    _reselect(ids, index, id);
  }

  void deleteSelected() {
    if (_selectedID != null) {
      delete(_selectedID!);
    }
  }

  void delete(String id) {
    final ids = flatIDs;
    final index = ids.indexOf(id);
    store.delete(id);
    _reselect(ids, index, id);
  }

  void _reselect(List<String> ids, int removedIndex, String removedId) {
    final remaining = ids.where((i) => i != removedId).toList();
    if (remaining.isEmpty) {
      _selectedID = null;
    } else {
      final nextIndex = removedIndex < remaining.length ? removedIndex : remaining.length - 1;
      _selectedID = remaining[nextIndex];
    }
    notifyListeners();
  }

  void togglePinSelected() {
    if (_selectedID != null) {
      store.togglePin(_selectedID!);
      notifyListeners();
    }
  }

  void togglePin(String id) {
    store.togglePin(id);
    _selectedID = id;
    notifyListeners();
  }

  void snoozeSelected(int minutes) {
    if (_selectedID != null) {
      store.snooze(_selectedID!, minutes);
      notifyListeners();
    }
  }

  void moveSelected(Bucket bucket) {
    if (_selectedID != null) {
      store.move(_selectedID!, bucket);
      notifyListeners();
    }
  }

  void move(String id, Bucket bucket) {
    store.move(id, bucket);
    _selectedID = id;
    notifyListeners();
  }

  void toggleDictation() {
    _isListening = !_isListening;
    if (_isListening) {
      _dictationError = null;
    }
    notifyListeners();
  }

  void undo() {
    if (store.undo()) {
      _ensureSelection();
      notifyListeners();
    }
  }

  void clearOrClose() {
    if (_showingShortcuts) {
      _showingShortcuts = false;
    } else if (_datePick != null) {
      _datePick = null;
    } else if (_editingID != null) {
      cancelEditing();
    } else if (_text.isNotEmpty) {
      _text = '';
    }
    notifyListeners();
  }

  ParsedTask _parsedInput(String input, {DatePick? override}) {
    final rawParsed = Parser.parse(input, clock.now, cal);
    if (override != null) {
      final res = override.resolve(cal);
      return ParsedTask(
        title: rawParsed.title,
        due: res.due,
        dueAt: res.dueAt,
        flex: Flex.none,
        hasDate: true,
      );
    }
    return rawParsed;
  }
}

