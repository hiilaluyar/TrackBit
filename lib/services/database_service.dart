import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== STREAK METHODS ====================

  // Kullanıcı streaklerini getir
  Stream<List<StreakModel>> getUserStreaks(String userId) {
    return _firestore
        .collection('streaks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('📊 Firestore\'dan ${snapshot.docs.length} streak geldi');

          var streaks = snapshot.docs.map((doc) {
            return StreakModel.fromMap(doc.data());
          }).toList();

          // Manuel sıralama - createdAt'a göre
          streaks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return streaks;
        })
        .handleError((error) {
          print('❌ Firestore hatası: $error');
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

      print('✅ Streak başarıyla eklendi: $name');
    } catch (e) {
      print('❌ Streak ekleme hatası: $e');
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

      print('✅ Streak güncellendi: $newCurrentStreak gün');
    } catch (e) {
      print('❌ Streak güncelleme hatası: $e');
      rethrow;
    }
  }

  // Streak sil
  Future<void> deleteStreak(String streakId) async {
    try {
      await _firestore.collection('streaks').doc(streakId).delete();
      print('✅ Streak silindi');
    } catch (e) {
      print('❌ Streak silme hatası: $e');
      rethrow;
    }
  }

  // Streak'leri kontrol et ve sıfırla (her gün çalıştırılacak)
  Future<void> checkAndResetStreaks() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      final snapshot = await _firestore.collection('streaks').get();

      for (var doc in snapshot.docs) {
        final streak = StreakModel.fromMap(doc.data());

        // Eğer son kontrol dünden önceyse ve bugün kontrol edilmediyse
        if (streak.lastChecked != null && !streak.isCheckedToday) {
          final lastCheck = DateTime(
            streak.lastChecked!.year,
            streak.lastChecked!.month,
            streak.lastChecked!.day,
          );
          final yesterdayDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
          );

          // Eğer son kontrol dünden önce ise streak'i sıfırla
          if (lastCheck.isBefore(yesterdayDate)) {
            await _firestore.collection('streaks').doc(streak.id).update({
              'currentStreak': 0,
            });
            print('🔄 Streak sıfırlandı: ${streak.name}');
          }
        }
      }
    } catch (e) {
      print('❌ Streak kontrol hatası: $e');
    }
  }

  // ==================== USER METHODS ====================

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        print('✅ Kullanıcı bulundu: ${doc.data()?['username']}');
        return UserModel.fromMap(doc.data()!);
      }
      print('⚠️ Kullanıcı bulunamadı');
      return null;
    } catch (e) {
      print('❌ Kullanıcı getirme hatası: $e');
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
      print('❌ Kullanıcı arama hatası: $e');
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

      print('✅ Arkadaş eklendi');
    } catch (e) {
      print('❌ Arkadaş ekleme hatası: $e');
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
          print('❌ Arkadaş streaklerini getirme hatası: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // ==================== CHALLENGE METHODS ====================

  // Challenge oluştur
  Future<String> createChallenge({
    required String userId,
    required String userName,
    required String name,
    required String emoji,
    required int durationDays,
  }) async {
    try {
      final challengeId = _firestore.collection('challenges').doc().id;
      final now = DateTime.now();

      await _firestore.collection('challenges').doc(challengeId).set({
        'id': challengeId,
        'name': name,
        'emoji': emoji,
        'creatorId': userId,
        'creatorName': userName,
        'participantIds': [userId],
        'participantScores': {userId: 0},
        'startDate': now.toIso8601String(),
        'endDate': now.add(Duration(days: durationDays)).toIso8601String(),
        'winnerId': null,
        'isActive': true,
        'createdAt': now.toIso8601String(),
      });

      print('✅ Challenge oluşturuldu: $name');
      return challengeId;
    } catch (e) {
      print('❌ Challenge oluşturma hatası: $e');
      rethrow;
    }
  }

  // Challenge'a katıl
  Future<void> joinChallenge(String challengeId, String userId) async {
    try {
      await _firestore.collection('challenges').doc(challengeId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
        'participantScores.$userId': 0,
      });

      print('✅ Challenge\'a katılındı');
    } catch (e) {
      print('❌ Challenge katılma hatası: $e');
      rethrow;
    }
  }

  // Challenge score güncelle
  Future<void> updateChallengeScore(String challengeId, String userId) async {
    try {
      final doc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();
      if (!doc.exists) return;

      final challenge = ChallengeModel.fromMap(doc.data()!);
      final currentScore = challenge.participantScores[userId] ?? 0;

      await _firestore.collection('challenges').doc(challengeId).update({
        'participantScores.$userId': currentScore + 1,
      });

      print('✅ Challenge score güncellendi');
    } catch (e) {
      print('❌ Challenge score güncelleme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının challengelarını getir
  Stream<List<ChallengeModel>> getUserChallenges(String userId) {
    return _firestore
        .collection('challenges')
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var challenges = snapshot.docs.map((doc) {
            return ChallengeModel.fromMap(doc.data());
          }).toList();

          // Aktif challengeları başa al
          challenges.sort((a, b) {
            if (a.isExpired && !b.isExpired) return 1;
            if (!a.isExpired && b.isExpired) return -1;
            return b.startDate.compareTo(a.startDate);
          });

          return challenges;
        })
        .handleError((error) {
          print('❌ Challenge getirme hatası: $error');
          return <ChallengeModel>[];
        });
  }

  // Arkadaşların challengelarını getir (davet için)
  Future<List<ChallengeModel>> getFriendsChallenges(
    List<String> friendIds,
  ) async {
    try {
      if (friendIds.isEmpty) return [];

      final snapshot = await _firestore
          .collection('challenges')
          .where('creatorId', whereIn: friendIds)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ChallengeModel.fromMap(doc.data()))
          .where((c) => !c.isExpired)
          .toList();
    } catch (e) {
      print('❌ Arkadaş challengelarını getirme hatası: $e');
      return [];
    }
  }

  // Challenge'ı bitir ve kazananı belirle
  Future<void> finishChallenge(String challengeId) async {
    try {
      final doc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();
      if (!doc.exists) return;

      final challenge = ChallengeModel.fromMap(doc.data()!);

      // En yüksek skoru bul
      String? winnerId;
      int maxScore = 0;

      challenge.participantScores.forEach((userId, score) {
        if (score > maxScore) {
          maxScore = score;
          winnerId = userId;
        }
      });

      await _firestore.collection('challenges').doc(challengeId).update({
        'isActive': false,
        'winnerId': winnerId,
      });

      print('✅ Challenge tamamlandı, kazanan: $winnerId');
    } catch (e) {
      print('❌ Challenge bitirme hatası: $e');
      rethrow;
    }
  }

  // Süresi dolan challengeları kontrol et
  Future<void> checkExpiredChallenges() async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final challenge = ChallengeModel.fromMap(doc.data());
        if (challenge.isExpired) {
          await finishChallenge(challenge.id);
        }
      }
    } catch (e) {
      print('❌ Challenge kontrol hatası: $e');
    }
  }
}
