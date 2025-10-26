import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı streaklerini getir - INDEX SORUNU ÇÖZÜLDÜ
  Stream<List<StreakModel>> getUserStreaks(String userId) {
    return _firestore
        .collection('streaks')
        .where('userId', isEqualTo: userId)
        // orderBy kaldırıldı - index hatası engellendi
        .snapshots()
        .map((snapshot) {
          print(
            '📊 Firestore\'dan ${snapshot.docs.length} streak geldi',
          ); // DEBUG

          var streaks = snapshot.docs.map((doc) {
            print('Streak verisi: ${doc.data()}'); // DEBUG
            return StreakModel.fromMap(doc.data());
          }).toList();

          // Manuel olarak sıralama - createdAt'a göre
          streaks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return streaks;
        })
        .handleError((error) {
          print('❌ Firestore hatası: $error'); // DEBUG
          return <StreakModel>[];
        });
  }

  // Yeni streak ekle
  Future<void> addStreak({
    required String userId,
    required String name,
    required String emoji,
  }) async {
    try {
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

      print('✅ Streak başarıyla eklendi: $name'); // DEBUG
    } catch (e) {
      print('❌ Streak ekleme hatası: $e'); // DEBUG
      rethrow;
    }
  }

  // Streak'i işaretle
  Future<void> checkStreak(String streakId, StreakModel streak) async {
    try {
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

      print('✅ Streak güncellendi: $newCurrentStreak gün'); // DEBUG
    } catch (e) {
      print('❌ Streak güncelleme hatası: $e'); // DEBUG
      rethrow;
    }
  }

  // Streak sil
  Future<void> deleteStreak(String streakId) async {
    try {
      await _firestore.collection('streaks').doc(streakId).delete();
      print('✅ Streak silindi'); // DEBUG
    } catch (e) {
      print('❌ Streak silme hatası: $e'); // DEBUG
      rethrow;
    }
  }

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        print('✅ Kullanıcı bulundu: ${doc.data()?['username']}'); // DEBUG
        return UserModel.fromMap(doc.data()!);
      }
      print('⚠️ Kullanıcı bulunamadı'); // DEBUG
      return null;
    } catch (e) {
      print('❌ Kullanıcı getirme hatası: $e'); // DEBUG
      return null;
    }
  }

  // Kullanıcı ara (username ile)
  Future<List<UserModel>> searchUsers(String username) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: username)
          .where('username', isLessThanOrEqualTo: username + '\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('❌ Kullanıcı arama hatası: $e'); // DEBUG
      return [];
    }
  }

  // Arkadaş ekle
  Future<void> addFriend(String currentUserId, String friendUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([friendUserId]),
      });

      await _firestore.collection('users').doc(friendUserId).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      print('✅ Arkadaş eklendi'); // DEBUG
    } catch (e) {
      print('❌ Arkadaş ekleme hatası: $e'); // DEBUG
      rethrow;
    }
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
        })
        .handleError((error) {
          print('❌ Arkadaş streaklerini getirme hatası: $error'); // DEBUG
          return <Map<String, dynamic>>[];
        });
  }
}
