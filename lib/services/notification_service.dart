import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  Future<void> initialize() async {
    await localNotifier.setup(
      appName: 'TraceTask',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> showTimedTaskAlert({
    required String title,
    String? body,
  }) async {
    final notification = LocalNotification(
      title: 'Task Due: $title',
      body: body ?? 'Press hotkey to open TraceTask',
    );
    await notification.show();
  }
}

