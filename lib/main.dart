import 'dart:async';
import 'package:flutter/material.dart';
import 'core/config/app_paths.dart';
import 'core/config/appearance.dart';
import 'core/config/config.dart';
import 'core/models/menu_bar_state.dart';
import 'core/panel/panel_model.dart';
import 'core/store/task_store.dart';
import 'core/time/day.dart';
import 'core/time/day_calendar.dart';
import 'services/hotkey_service.dart';
import 'services/notification_service.dart';
import 'services/tray_service.dart';
import 'services/window_service.dart';
import 'ui/panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Config & Paths
  final config = await AppPaths.loadConfig();
  final tasksFile = await AppPaths.getTasksFile();
  final backupDir = await AppPaths.getBackupsDir();

  // 2. Setup Core Engine
  const clock = SystemClock();
  final cal = DayCalendar(rolloverHour: config.dayRolloverHour);
  final store = TaskStore(
    file: tasksFile,
    backupDir: backupDir,
    clock: clock,
    cal: cal,
  );
  final model = PanelModel(store: store, config: config);

  // 3. Setup Desktop Services (safely guarded)
  try {
    await WindowService.instance.initialize();
  } catch (e) {
    debugPrint('WindowService init warning: $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('NotificationService init warning: $e');
  }

  try {
    await HotkeyService.instance.initialize(
      onTrigger: () async {
        await WindowService.instance.toggle();
      },
    );
  } catch (e) {
    debugPrint('HotkeyService init warning: $e');
  }

  // 4. Setup Tray & Periodic Timer
  final notifiedTasks = <String>{};

  void updateTrayAndAlerts() {
    try {
      final now = clock.now;
      final state = MenuBarState.compute(
        store.items,
        now,
        cal,
        quiet: model.quietMode,
      );
      TrayService.instance.updateState(state);

      final pinnedTasks = store.items.where((i) => i.isOpen && i.pinned).toList();
      pinnedTasks.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          final orderComp = a.sortOrder!.compareTo(b.sortOrder!);
          if (orderComp != 0) return orderComp;
        }
        final timeA = a.dueAt ?? cal.dateOn(a.due, cal.rolloverHour);
        final timeB = b.dueAt ?? cal.dateOn(b.due, cal.rolloverHour);
        final timeComp = timeA.compareTo(timeB);
        if (timeComp != 0) return timeComp;
        return a.createdAt.compareTo(b.createdAt);
      });
      TrayService.instance.updateContextMenu(pinnedTasks: pinnedTasks, cal: cal);

      if (!model.quietMode) {
        for (final item in store.items) {
          if (item.hasFired(now) && !notifiedTasks.contains(item.id)) {
            notifiedTasks.add(item.id);
            NotificationService.instance.showTimedTaskAlert(
              title: item.title,
              body: 'Task is due now',
            );
          }
        }
      }
    } catch (_) {}
  }

  try {
    await TrayService.instance.initialize(
      onToggle: () {
        WindowService.instance.toggle();
      },
      onTaskSelect: (taskId) {
        model.selectID(taskId);
        WindowService.instance.show();
      },
      onTaskComplete: (taskId) {
        final item = model.store.item(taskId);
        if (item != null) {
          model.markDone(taskId);
          if (!model.quietMode) {
            NotificationService.instance.showTaskCompleted(title: item.title);
          }
        }
      },
    );
  } catch (e) {
    debugPrint('TrayService init warning: $e');
  }

  updateTrayAndAlerts();
  store.addListener(updateTrayAndAlerts);
  model.addListener(updateTrayAndAlerts);
  Timer.periodic(const Duration(seconds: 10), (_) => updateTrayAndAlerts());

  runApp(TraceTaskApp(model: model, initialConfig: config));
}

class TraceTaskApp extends StatefulWidget {
  final PanelModel model;
  final Config initialConfig;

  const TraceTaskApp({
    super.key,
    required this.model,
    required this.initialConfig,
  });

  @override
  State<TraceTaskApp> createState() => _TraceTaskAppState();
}

class _TraceTaskAppState extends State<TraceTaskApp> {
  late AppAppearance _appearance;

  @override
  void initState() {
    super.initState();
    _appearance = widget.initialConfig.appearance;
  }

  void _handleAppearanceChange(AppAppearance appearance) async {
    setState(() {
      _appearance = appearance;
    });
    await AppPaths.saveAppearance(appearance);
    widget.model.config.appearance = appearance;
  }

  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode;
    switch (_appearance) {
      case AppAppearance.light:
        themeMode = ThemeMode.light;
      case AppAppearance.dark:
        themeMode = ThemeMode.dark;
      case AppAppearance.system:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TraceTask',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFDFDFB),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF212328),
      ),
      home: PanelScreen(
        model: widget.model,
        onAppearanceChange: _handleAppearanceChange,
      ),
    );
  }
}
