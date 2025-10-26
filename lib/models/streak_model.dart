import 'package:cloud_firestore/cloud_firestore.dart';

class StreakModel {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastChecked;
  final DateTime createdAt;

  StreakModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastChecked,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastChecked': lastChecked?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StreakModel.fromMap(Map<String, dynamic> map) {
    return StreakModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '⭐',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastChecked: map['lastChecked'] != null
          ? DateTime.parse(map['lastChecked'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  bool get isCheckedToday {
    if (lastChecked == null) return false;
    final now = DateTime.now();
    return lastChecked!.year == now.year &&
        lastChecked!.month == now.month &&
        lastChecked!.day == now.day;
  }
}
