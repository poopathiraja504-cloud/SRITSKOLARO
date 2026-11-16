import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static const webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const webAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const projectId = 'srit-skolaro';
  static const messagingSenderId = '100221373274';
  static const storageBucket = 'srit-skolaro.firebasestorage.app';
  static const webMeasurementId = 'G-PMHMBYXY9TG';
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const androidServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const webVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: webApiKey,
        appId: webAppId,
        authDomain: webAuthDomain,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        measurementId: webMeasurementId,
      );

  static Future<void> initialize() async {
    if (kIsWeb) {
      if (webApiKey.isEmpty || webAppId.isEmpty || webAuthDomain.isEmpty) {
        throw StateError(
          'Web Firebase settings are missing. Build with the Firebase web settings '
          'described in README.md.',
        );
      }
      await Firebase.initializeApp(options: webOptions);
    } else {
      await Firebase.initializeApp();
    }
  }
}
