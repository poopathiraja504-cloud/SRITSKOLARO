// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  Future<void> initializeForUser(String uid, FirebaseApp app) async {
    if (kIsWeb && FirebaseBootstrap.webVapidKey.isEmpty) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initialization = InitializationSettings(android: androidSettings);
      await _local.initialize(initialization);
      const channel = AndroidNotificationChannel(
        'srit_skolaro_updates',
        'SRIT SKOLARO updates',
        'Campus announcements and student updates',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    final prefs = await SharedPreferences.getInstance();
    final deviceKey = prefs.getString('notifications.deviceKey') ??
        DateTime.now().microsecondsSinceEpoch.toString();
    await prefs.setString('notifications.deviceKey', deviceKey);

    final token = kIsWeb
        ? (FirebaseBootstrap.webVapidKey.isEmpty
            ? null
            : await messaging.getToken(vapidKey: FirebaseBootstrap.webVapidKey))
        : await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await FirebaseFirestore.instanceFor(app: app)
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceKey)
          .set({
        'token': token,
        'platform': kIsWeb ? 'web' : 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null || kIsWeb) return;
      unawaited(_local.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'srit_skolaro_updates',
            'SRIT SKOLARO updates',
            'Campus announcements and student updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      ));
    });
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }
}
