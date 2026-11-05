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
      final state = MenuBarState.compute(store.items, now, cal);
      TrayService.instance.updateState(state);

      for (final item in store.items) {
        if (item.hasFired(now) && !notifiedTasks.contains(item.id)) {
          notifiedTasks.add(item.id);
          NotificationService.instance.showTimedTaskAlert(
            title: item.title,
            body: 'Task is due now',
          );
        }
      }
    } catch (_) {}
  }

  try {
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
  } catch (e) {
    debugPrint('TrayService init warning: $e');
  }

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
        scaffoldBackgroundColor: const Color(0xFFFDFDFB),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181A1E),
      ),
      home: PanelScreen(
        model: widget.model,
        onAppearanceChange: _handleAppearanceChange,
      ),
    );
  }
}
