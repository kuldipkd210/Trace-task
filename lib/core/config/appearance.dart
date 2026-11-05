enum AppAppearance {
  system,
  light,
  dark;

  String toJson() => name;

  static AppAppearance fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return AppAppearance.light;
      case 'dark':
        return AppAppearance.dark;
      case 'system':
      default:
        return AppAppearance.system;
    }
  }

  static AppAppearance flipped(bool currentlyDark) {
    return currentlyDark ? AppAppearance.light : AppAppearance.dark;
  }
}

