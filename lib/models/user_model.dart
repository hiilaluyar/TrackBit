class UserModel {
  final String uid;
  final String username;
  final String email;
  final List<String> friends;
  final int totalStreakDays;
  final int longestStreak;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.friends = const [],
    this.totalStreakDays = 0,
    this.longestStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'friends': friends,
      'totalStreakDays': totalStreakDays,
      'longestStreak': longestStreak,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      friends: List<String>.from(map['friends'] ?? []),
      totalStreakDays: map['totalStreakDays'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
    );
  }
}
