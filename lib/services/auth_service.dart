import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Kayıt ol
  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Kullanıcı adı kontrol et
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return 'Bu kullanıcı adı zaten alınmış';
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'username': username,
        'email': email,
        'friends': [],
        'totalStreakDays': 0,
        'longestStreak': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Şifre çok zayıf';
      } else if (e.code == 'email-already-in-use') {
        return 'Bu email zaten kullanılıyor';
      } else if (e.code == 'invalid-email') {
        return 'Geçersiz email adresi';
      }
      return e.message;
    } catch (e) {
      return 'Bir hata oluştu: $e';
    }
  }

  // Giriş yap
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Kullanıcı bulunamadı';
      } else if (e.code == 'wrong-password') {
        return 'Hatalı şifre';
      } else if (e.code == 'invalid-email') {
        return 'Geçersiz email adresi';
      }
      return e.message;
    } catch (e) {
      return 'Bir hata oluştu: $e';
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
