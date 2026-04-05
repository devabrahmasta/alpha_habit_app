class TargetModel {
  final String userId;
  final int totalDays;
  final DateTime startDate;

  const TargetModel({
    required this.userId,
    this.totalDays = 90,
    required this.startDate,
  });

  /// Days elapsed since [startDate], clamped to [1, totalDays].
  int get dayElapsed {
    final diff = DateTime.now().difference(startDate).inDays + 1;
    return diff.clamp(1, totalDays);
  }

  Map<String, dynamic> toMap() => {
        'totalDays': totalDays,
        'startDate': startDate.toIso8601String(),
      };

  factory TargetModel.fromMap(String userId, Map<String, dynamic> m) {
    return TargetModel(
      userId: userId,
      totalDays: (m['totalDays'] as num?)?.toInt() ?? 90,
      startDate: DateTime.parse(m['startDate'] as String),
    );
  }
}
