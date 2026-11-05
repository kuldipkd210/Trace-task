import 'package:flutter_test/flutter_test.dart';
import 'package:tracetask/core/models/bucket.dart';
import 'package:tracetask/core/models/flex.dart';
import 'package:tracetask/core/models/item.dart';
import 'package:tracetask/core/models/menu_bar_state.dart';
import 'package:tracetask/core/models/ranker.dart';
import 'package:tracetask/core/models/sections.dart';
import 'package:tracetask/core/config/config.dart';
import 'package:tracetask/core/panel/panel_model.dart';
import 'package:tracetask/core/parser/parser.dart';
import 'package:tracetask/core/store/task_store.dart';
import 'package:tracetask/core/time/day.dart';
import 'package:tracetask/core/time/day_calendar.dart';

void main() {
  const cal = DayCalendar(rolloverHour: 3);

  DateTime at(int y, int m, int d, [int h = 12, int min = 0]) {
    return DateTime(y, m, d, h, min);
  }

  Day day(int y, int m, int d) => Day(year: y, month: m, day: d);

  final thu0100 = at(2026, 11, 5, 1);

  group('Day & DayCalendar', () {
    test('rollover boundary: 02:59 is previous day, 03:00 is today', () {
      expect(cal.dayOf(at(2026, 11, 5, 2, 59)), day(2026, 11, 4));
      expect(cal.dayOf(at(2026, 11, 5, 3, 0)), day(2026, 11, 5));
    });

    test('month and year end after midnight', () {
      expect(cal.dayOf(at(2026, 12, 1, 1)), day(2026, 11, 30));
      expect(cal.dayOf(at(2027, 1, 1, 2)), day(2026, 12, 31));
    });

    test('endOfWeek is Sunday', () {
      expect(cal.endOfWeek(day(2026, 11, 4)), day(2026, 11, 8));
      expect(cal.endOfWeek(day(2026, 11, 8)), day(2026, 11, 8));
      expect(cal.endOfWeek(day(2026, 11, 9)), day(2026, 11, 15));
    });

    test('endOfMonth handles leap year', () {
      expect(cal.endOfMonth(day(2028, 2, 10)), day(2028, 2, 29));
      expect(cal.endOfMonth(day(2026, 12, 31)), day(2026, 12, 31));
    });

    test('validDay rejects impossible dates', () {
      expect(cal.validDay(2026, 2, 30), isNull);
      expect(cal.validDay(2026, 13, 1), isNull);
      expect(cal.validDay(2026, 4, 31), isNull);
      expect(cal.validDay(2028, 2, 29), day(2028, 2, 29));
      expect(cal.validDay(2027, 2, 29), isNull);
    });

    test('hour before rollover lands on next calendar date', () {
      expect(cal.dateOn(day(2026, 11, 4), 2), at(2026, 11, 5, 2));
      expect(cal.dateOn(day(2026, 11, 4), 9), at(2026, 11, 4, 9));
    });
  });

  group('Parser', () {
    ParsedTask parse(String text, [DateTime? now]) {
      return Parser.parse(text, now ?? thu0100, cal);
    }

    test('no date at 01:00 is current work day', () {
      final task = parse('pay rent');
      expect(task.title, 'pay rent');
      expect(task.due, day(2026, 11, 4));
      expect(task.dueAt, isNull);
      expect(task.hasDate, isFalse);
    });

    test('tomorrow at 01:00 is Thursday work day', () {
      expect(parse('pay rent tmr').due, day(2026, 11, 5));
      expect(parse('pay rent tomorrow').due, day(2026, 11, 5));
    });

    test('2am at 01:00 is in one hour', () {
      final task = parse('deploy 2am');
      expect(task.dueAt, at(2026, 11, 5, 2));
      expect(task.due, day(2026, 11, 4));
    });

    test('3pm at 01:00 is Thursday afternoon', () {
      final task = parse('call bank 3pm');
      expect(task.dueAt, at(2026, 11, 5, 15));
      expect(task.due, day(2026, 11, 5));
      expect(task.title, 'call bank');
    });

    test('Friday at 01:00', () {
      expect(parse('send invoice fri').due, day(2026, 11, 6));
    });

    test('date and time in either order', () {
      final now = at(2026, 11, 4, 10);
      expect(parse('meet fri 3pm', now).dueAt, at(2026, 11, 6, 15));
      expect(parse('meet 3pm fri', now).dueAt, at(2026, 11, 6, 15));
    });

    test('month dates', () {
      final now = at(2026, 11, 4, 10);
      expect(parse('tax docs nov 12', now).due, day(2026, 11, 12));
      expect(parse('tax docs 12 nov', now).due, day(2026, 11, 12));
      expect(parse('tax docs jan 5', now).due, day(2027, 1, 5));
    });

    test('relative time: in 2h, in 30m, in 3d', () {
      final now = at(2026, 11, 4, 10);
      expect(parse('ping sam in 2h', now).dueAt, at(2026, 11, 4, 12));
      expect(parse('ping sam in 30m', now).dueAt, at(2026, 11, 4, 10, 30));
      expect(parse('ping sam in 3d', now).due, day(2026, 11, 7));
      expect(parse('ping sam in 3d', now).title, 'ping sam');
    });

    test('names and bare numbers stay titles', () {
      expect(parse('call tom').title, 'call tom');
      expect(parse('call tom').hasDate, isFalse);
      expect(parse('room 12').title, 'room 12');
      expect(parse('room 12').hasDate, isFalse);
    });

    test('trailing dot keeps words literal', () {
      expect(parse('call mon').title, 'call');
      final literal = parse('call mon.');
      expect(literal.title, 'call mon');
      expect(literal.hasDate, isFalse);
    });

    test('date word alone stays title', () {
      expect(parse('monday').title, 'monday');
      expect(parse('3pm').title, '3pm');
    });

    test('flex week and month', () {
      final now = at(2026, 11, 4, 10);
      expect(parse('review week', now).flex, Flex.week);
      expect(parse('renew month', now).flex, Flex.month);
    });
  });

  group('Item & Sections & Ranker', () {
    test('bucket classification', () {
      final today = day(2026, 11, 4);
      final itemToday = Item(
        title: 'Task 1',
        due: today,
        createdAt: at(2026, 11, 4, 9),
      );
      final itemWeek = Item(
        title: 'Task 2',
        due: day(2026, 11, 7),
        createdAt: at(2026, 11, 4, 9),
      );
      final itemMonth = Item(
        title: 'Task 3',
        due: day(2026, 11, 25),
        createdAt: at(2026, 11, 4, 9),
      );

      expect(Sections.bucketOf(itemToday, today, cal), Bucket.today);
      expect(Sections.bucketOf(itemWeek, today, cal), Bucket.week);
      expect(Sections.bucketOf(itemMonth, today, cal), Bucket.month);
    });

    test('Ranker prioritizes pinned > fired > imminent > overdue > general', () {
      final now = at(2026, 11, 4, 12);
      final today = day(2026, 11, 4);

      final normal = Item(
        id: '1',
        title: 'Normal',
        due: today,
        createdAt: at(2026, 11, 4, 8),
      );
      final pinned = Item(
        id: '2',
        title: 'Pinned',
        due: today,
        pinned: true,
        createdAt: at(2026, 11, 4, 8),
      );
      final fired = Item(
        id: '3',
        title: 'Fired',
        due: today,
        dueAt: at(2026, 11, 4, 11),
        createdAt: at(2026, 11, 4, 8),
      );

      final ranked = Ranker.today([normal, pinned, fired], now, cal);
      expect(ranked[0].id, pinned.id);
      expect(ranked[1].id, fired.id);
      expect(ranked[2].id, normal.id);
    });

    test('MenuBarState title and tone', () {
      final now = at(2026, 11, 4, 12);

      // Empty
      expect(MenuBarState.compute([], now, cal).title, '✓');
      expect(MenuBarState.compute([], now, cal).tone, TrayTone.normal);

      // Fired task gives red tone
      final fired = Item(
        title: 'Call client',
        due: day(2026, 11, 4),
        dueAt: at(2026, 11, 4, 11),
        createdAt: now,
      );
      final state = MenuBarState.compute([fired], now, cal);
      expect(state.tone, TrayTone.red);
      expect(state.title, '1 · Call client');
    });

    test('MenuBarState priority: earliest time > pinned > last added', () {
      final now = at(2026, 11, 4, 12);

      // Case 1: Only plain tasks -> last task added wins
      final task1 = Item(title: 'Task One', due: day(2026, 11, 4), createdAt: at(2026, 11, 4, 9));
      final task2 = Item(title: 'Task Two', due: day(2026, 11, 4), createdAt: at(2026, 11, 4, 10));
      var state = MenuBarState.compute([task1, task2], now, cal);
      expect(state.title, '2 · Task Two');

      // Case 2: Pinned task wins over unpinned newer task
      final pinnedTask = Item(title: 'Important Pinned', due: day(2026, 11, 4), pinned: true, createdAt: at(2026, 11, 4, 8));
      state = MenuBarState.compute([task1, task2, pinnedTask], now, cal);
      expect(state.title, '3 · Important Pinned');

      // Case 3: Task with earliest time wins over pinned task and newer tasks
      final timedEarlier = Item(
        title: 'Meeting at 2pm',
        due: day(2026, 11, 4),
        dueAt: at(2026, 11, 4, 14),
        createdAt: at(2026, 11, 4, 7),
      );
      final timedLater = Item(
        title: 'Dinner at 7pm',
        due: day(2026, 11, 4),
        dueAt: at(2026, 11, 4, 19),
        createdAt: at(2026, 11, 4, 11),
      );
      state = MenuBarState.compute([task1, task2, pinnedTask, timedEarlier, timedLater], now, cal);
      expect(state.title, '5 · Meeting at 2pm');
    });
  });

  group('TaskStore', () {
    test('add, markDone, delete, undo', () {
      final clock = FakeClock(at(2026, 11, 4, 10));
      final store = TaskStore(clock: clock, cal: cal);

      final item = store.add(ParsedTask(
        title: 'Buy milk',
        due: day(2026, 11, 4),
        hasDate: false,
      ));

      expect(store.items.length, 1);
      expect(store.items.first.title, 'Buy milk');
      expect(store.items.first.isOpen, isTrue);

      store.markDone(item.id);
      expect(store.items.first.isOpen, isFalse);
      expect(store.items.first.doneAt, clock.now);

      expect(store.undo(), isTrue);
      expect(store.items.first.isOpen, isTrue);

      store.delete(item.id);
      expect(store.items.isEmpty, isTrue);

      expect(store.undo(), isTrue);
      expect(store.items.length, 1);
    });
  });

  group('PanelModel Selection & Interactions', () {
    test('task addition selects new task', () {
      final clock = FakeClock(at(2026, 11, 4, 10));
      final store = TaskStore(clock: clock, cal: cal);
      final model = PanelModel(store: store, config: Config());

      clock.now = at(2026, 11, 4, 10, 1);
      model.setText('First task');
      model.submit();

      expect(model.flatIDs.length, 1);
      expect(model.selectedID, model.flatIDs.first);
      expect(model.store.item(model.selectedID!)?.title, 'First task');

      clock.now = at(2026, 11, 4, 10, 2);
      model.setText('Second task');
      model.submit();

      expect(model.flatIDs.length, 2);
      expect(model.store.item(model.selectedID!)?.title, 'Second task');
    });

    test('arrow navigation moves selection up and down', () {
      final clock = FakeClock(at(2026, 11, 4, 10));
      final store = TaskStore(clock: clock, cal: cal);
      final model = PanelModel(store: store, config: Config());

      clock.now = at(2026, 11, 4, 10, 1);
      model.setText('Task A');
      model.submit();
      clock.now = at(2026, 11, 4, 10, 2);
      model.setText('Task B');
      model.submit();
      clock.now = at(2026, 11, 4, 10, 3);
      model.setText('Task C');
      model.submit();

      final ids = model.flatIDs;
      expect(ids.length, 3);
      expect(model.selectedID, ids[2]);

      model.selectPrevious();
      expect(model.selectedID, ids[1]);

      model.selectPrevious();
      expect(model.selectedID, ids[0]);

      // At top, selectPrevious stays at top
      model.selectPrevious();
      expect(model.selectedID, ids[0]);

      model.selectNext();
      expect(model.selectedID, ids[1]);

      model.selectNext();
      expect(model.selectedID, ids[2]);

      // At bottom, selectNext stays at bottom
      model.selectNext();
      expect(model.selectedID, ids[2]);
    });

    test('markDone and delete cleanly reselect adjacent task', () {
      final clock = FakeClock(at(2026, 11, 4, 10));
      final store = TaskStore(clock: clock, cal: cal);
      final model = PanelModel(store: store, config: Config());

      model.setText('Task 1');
      model.submit();
      model.setText('Task 2');
      model.submit();
      model.setText('Task 3');
      model.submit();

      final id2 = model.flatIDs[1];
      model.selectID(id2);

      // Delete middle item (Task 2) -> should reselect Task 3 (now index 1)
      model.deleteSelected();
      expect(model.flatIDs.length, 2);
      expect(model.selectedID, model.flatIDs[1]);

      // Mark done on Task 3 -> should reselect Task 1
      model.markSelectedDone();
      expect(model.flatIDs.length, 1);
      expect(model.selectedID, model.flatIDs.first);

      // Delete last remaining task -> selectedID becomes null
      model.deleteSelected();
      expect(model.flatIDs.isEmpty, isTrue);
      expect(model.selectedID, isNull);
    });

    test('undo restores item and selection', () {
      final clock = FakeClock(at(2026, 11, 4, 10));
      final store = TaskStore(clock: clock, cal: cal);
      final model = PanelModel(store: store, config: Config());

      model.setText('Task to delete');
      model.submit();
      expect(model.flatIDs.length, 1);

      model.deleteSelected();
      expect(model.flatIDs.isEmpty, isTrue);

      model.undo();
      expect(model.flatIDs.length, 1);
      expect(model.selectedID, isNotNull);
    });
  });
}

