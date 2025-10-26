import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Bildirim izni iste
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Bildirim izni verildi');
    }

    // FCM Token al
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Foreground bildirimleri dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Bildirim alındı: ${message.notification?.title}');
    });
  }
}
