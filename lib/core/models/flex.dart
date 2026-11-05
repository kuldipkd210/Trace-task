enum Flex {
  none,
  week,
  month;

  String toJson() => name;

  static Flex fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'week':
        return Flex.week;
      case 'month':
        return Flex.month;
      case 'none':
      default:
        return Flex.none;
    }
  }
}

