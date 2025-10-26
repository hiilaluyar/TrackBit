import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı streaklerini getir
  Stream<List<StreakModel>> getUserStreaks(String userId) {
    return _firestore
        .collection('streaks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return StreakModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Yeni streak ekle
  Future<void> addStreak({
    required String userId,
    required String name,
    required String emoji,
  }) async {
    final streakId = _firestore.collection('streaks').doc().id;

    await _firestore.collection('streaks').doc(streakId).set({
      'id': streakId,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastChecked': null,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Streak'i işaretle
  Future<void> checkStreak(String streakId, StreakModel streak) async {
    final now = DateTime.now();
    int newCurrentStreak = streak.currentStreak + 1;
    int newLongestStreak = streak.longestStreak;

    if (newCurrentStreak > newLongestStreak) {
      newLongestStreak = newCurrentStreak;
    }

    await _firestore.collection('streaks').doc(streakId).update({
      'currentStreak': newCurrentStreak,
      'longestStreak': newLongestStreak,
      'lastChecked': now.toIso8601String(),
    });
  }

  // Streak sil
  Future<void> deleteStreak(String streakId) async {
    await _firestore.collection('streaks').doc(streakId).delete();
  }

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Kullanıcı ara (username ile)
  Future<List<UserModel>> searchUsers(String username) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: username)
        .where('username', isLessThanOrEqualTo: username + '\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Arkadaş ekle
  Future<void> addFriend(String currentUserId, String friendUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'friends': FieldValue.arrayUnion([friendUserId]),
    });

    await _firestore.collection('users').doc(friendUserId).update({
      'friends': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // Arkadaşların streaklerini getir
  Stream<List<Map<String, dynamic>>> getFriendsStreaks(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('streaks')
        .where('userId', whereIn: friendIds)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> friendsStreaks = [];

          for (var doc in snapshot.docs) {
            final streak = StreakModel.fromMap(doc.data());
            final user = await getUserData(streak.userId);

            if (user != null && streak.currentStreak > 0) {
              friendsStreaks.add({'username': user.username, 'streak': streak});
            }
          }

          return friendsStreaks;
        });
  }
}
