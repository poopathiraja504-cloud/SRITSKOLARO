import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = auth.currentApp;
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: app == null || user == null
          ? const Center(child: Text('Sign in to view notifications.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instanceFor(app: app)
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Could not load student notifications: ${snapshot.error}');
                  return const Center(child: Text('Notifications could not be loaded.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data?.docs ?? const [];
                if (items.isEmpty) {
                  return const _EmptyNotifications();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = items[index].data();
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8EDF8),
                          foregroundColor: AppTheme.navy,
                          child: Icon(Icons.notifications_none),
                        ),
                        title: Text('${data['title'] ?? 'Campus update'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${data['body'] ?? ''}'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 54, color: AppTheme.secondaryText),
            SizedBox(height: 12),
            Text('No notifications yet.', style: TextStyle(color: AppTheme.secondaryText)),
          ],
        ),
      ),
    );
  }
}
