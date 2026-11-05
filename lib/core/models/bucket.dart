enum Bucket {
  today(0, 'Today'),
  week(1, 'Week'),
  month(2, 'Month');

  final int id;
  final String title;

  const Bucket(this.id, this.title);
}

