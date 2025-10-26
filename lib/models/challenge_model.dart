import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String id;
  final String name;
  final String emoji;
  final String creatorId;
  final String creatorName;
  final List<String> participantIds;
  final Map<String, int> participantScores; // userId: streak count
  final DateTime startDate;
  final DateTime endDate;
  final String? winnerId;
  final bool isActive;
  final DateTime createdAt;

  ChallengeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.creatorId,
    required this.creatorName,
    required this.participantIds,
    required this.participantScores,
    required this.startDate,
    required this.endDate,
    this.winnerId,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'participantIds': participantIds,
      'participantScores': participantScores,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'winnerId': winnerId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '🏆',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantScores: Map<String, int>.from(map['participantScores'] ?? {}),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : DateTime.now().add(Duration(days: 7)),
      winnerId: map['winnerId'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  int get totalDays => endDate.difference(startDate).inDays;

  String? getWinnerName(Map<String, String> userNames) {
    if (winnerId == null) return null;
    return userNames[winnerId];
  }
}
