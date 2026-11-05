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

  // 3. Setup Desktop Services
  await WindowService.instance.initialize(
    onBlur: () {
      // Auto-save draft and hide on blur (matching macOS panel behavior)
      if (model.text.trim().isNotEmpty) {
        model.submit();
      }
      WindowService.instance.hide();
    },
  );

  await NotificationService.instance.initialize();

  await HotkeyService.instance.initialize(
    onTrigger: () async {
      await WindowService.instance.toggle();
    },
  );

  // 4. Background Timer: update Tray status & fire alerts for timed tasks
  final notifiedTasks = <String>{};

  void updateTrayAndAlerts() {
    final now = clock.now;
    final state = MenuBarState.compute(store.items, now, cal);
    TrayService.instance.updateState(state);

    // Check for newly fired tasks
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

  await TrayService.instance.initialize(
    onToggle: () {
      WindowService.instance.toggle();
    },
    onAppearance: (appearance) async {
      await AppPaths.saveAppearance(appearance);
      model.config.appearance = appearance;
      await TrayService.instance.updateContextMenu(appearance);
    },
  );

  updateTrayAndAlerts();
  Timer.periodic(const Duration(seconds: 15), (_) => updateTrayAndAlerts());

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
    await TrayService.instance.updateContextMenu(appearance);
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
        scaffoldBackgroundColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: PanelScreen(
        model: widget.model,
        onAppearanceChange: _handleAppearanceChange,
      ),
    );
  }
}
