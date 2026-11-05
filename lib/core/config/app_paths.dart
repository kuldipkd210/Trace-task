import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'appearance.dart';
import 'config.dart';

class AppPaths {
  static String? _baseDirOverride;

  static void setBaseDirOverride(String? path) {
    _baseDirOverride = path;
  }

  static Future<Directory> getBaseDir() async {
    final env = Platform.environment['TRACETASK_DATA_DIR'] ??
        Platform.environment['TACK_DATA_DIR'];
    if (_baseDirOverride != null) {
      final dir = Directory(_baseDirOverride!);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    if (env != null && env.isNotEmpty) {
      final dir = Directory(env);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }

    try {
      final appSupport = await getApplicationSupportDirectory();
      final dir = Directory(p.join(appSupport.path, 'tracetask'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } catch (_) {
      // Fallback for command line or test environments
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final dir = Directory(p.join(home, '.tracetask'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
  }

  static Future<File> getTasksFile() async {
    final base = await getBaseDir();
    return File(p.join(base.path, 'tasks.json'));
  }

  static Future<File> getConfigFile() async {
    final base = await getBaseDir();
    return File(p.join(base.path, 'config.json'));
  }

  static Future<Directory> getBackupsDir() async {
    final base = await getBaseDir();
    final dir = Directory(p.join(base.path, 'backups'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<Config> loadConfig() async {
    try {
      final file = await getConfigFile();
      if (!file.existsSync()) {
        final config = Config();
        const encoder = JsonEncoder.withIndent('  ');
        await file.writeAsString(encoder.convert(config.toJson()));
        return config;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return Config.fromJson(decoded);
    } catch (_) {
      return Config();
    }
  }

  static Future<bool> saveAppearance(AppAppearance appearance) async {
    try {
      final file = await getConfigFile();
      Map<String, dynamic> map = {};
      if (file.existsSync()) {
        final raw = await file.readAsString();
        map = jsonDecode(raw) as Map<String, dynamic>;
      }
      map['appearance'] = appearance.toJson();
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(map));
      return true;
    } catch (_) {
      return false;
    }
  }
}

