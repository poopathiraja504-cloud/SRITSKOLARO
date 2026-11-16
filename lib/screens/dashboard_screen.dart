import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/portal_section.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/student_avatar.dart';
import 'accounts_sheet.dart';
import 'attendance_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'website_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NotificationService _notifications = NotificationService();
  int _bottomIndex = 0;
  String? _notificationIdentity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final app = auth.currentApp;
    final identity = user == null || app == null ? null : '${app.name}:${user.uid}';
    if (identity != _notificationIdentity) {
      _notificationIdentity = identity;
      if (user != null && app != null) {
        unawaited(_configureNotifications(user.uid, app));
      } else {
        unawaited(_notifications.dispose());
      }
    }
  }

  Future<void> _configureNotifications(String uid, FirebaseApp app) async {
    try {
      await _notifications.initializeForUser(uid, app);
    } catch (error, stackTrace) {
      debugPrint('Could not configure student notifications: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications could not be enabled. Check Firebase setup.')),
        );
      }
    }
  }

  @override
  void dispose() {
    unawaited(_notifications.dispose());
    super.dispose();
  }

  void _openSection(PortalSection section) {
    Widget? screen;
    switch (section) {
      case PortalSection.profile:
        screen = const ProfileScreen();
      case PortalSection.attendance:
        screen = const AttendanceScreen();
      case PortalSection.documents:
        screen = const DocumentsScreen();
      case PortalSection.settings:
        screen = const SettingsScreen();
      case PortalSection.notifications:
        screen = const NotificationsScreen();
      default:
        screen = WebsiteScreen(section: section);
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen!));
  }

  Future<void> _openAccounts() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountsSheet(),
    );
  }

  void _onBottomTap(int index) {
    if (index == 0) {
      setState(() => _bottomIndex = 0);
    } else if (index == 1) {
      setState(() => _bottomIndex = 1);
      _openSection(PortalSection.academics);
    } else {
      setState(() => _bottomIndex = 2);
      _openSection(PortalSection.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final profile = auth.profile;
    final name = profile?.name ?? user.displayName ?? user.email?.split('@').first ?? 'Student';
    final email = profile?.email ?? user.email ?? '';
    final photo = profile?.profilePhoto.isNotEmpty == true
        ? profile!.profilePhoto
        : user.photoURL;
    final greeting = _greeting();

    return Scaffold(
      drawer: _NavigationDrawer(
        name: name,
        email: email,
        photoUrl: photo,
        onSelect: _openSection,
        onAccounts: _openAccounts,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.deepNavy, AppTheme.navy, Color(0xFF174E95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton.filledTonal(
                              onPressed: Scaffold.of(context).openDrawer,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: .12),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.menu),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'SRI RAMAKRISHNA INSTITUTE OF TECHNOLOGY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            button: true,
                            label: 'Open signed-in accounts',
                            child: InkWell(
                              onTap: _openAccounts,
                              borderRadius: BorderRadius.circular(40),
                              child: StudentAvatar(
                                name: name,
                                photoUrl: photo,
                                size: 48,
                                borderColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 17),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          _HeaderPill(
                            icon: Icons.calendar_today_outlined,
                            label: MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
                          ),
                          const _HeaderPill(icon: Icons.school_outlined, label: 'Student'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 820
                      ? 4
                      : constraints.maxWidth >= 560
                          ? 3
                          : 3;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick access', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: PortalSection.dashboard.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: constraints.maxWidth >= 560 ? 1.08 : .96,
                        ),
                        itemBuilder: (context, index) {
                          final section = PortalSection.dashboard[index];
                          return _DashboardTile(
                            section: section,
                            onTap: () => _openSection(section),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: _onBottomTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Academics'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.section, required this.onTap});

  final PortalSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.navy.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(section.icon, color: AppTheme.navy, size: 28),
              ),
              const SizedBox(height: 9),
              Text(
                section.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onSelect,
    required this.onAccounts,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final ValueChanged<PortalSection> onSelect;
  final VoidCallback onAccounts;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.deepNavy, AppTheme.navy]),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onAccounts();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentAvatar(name: name, photoUrl: photoUrl, size: 66, borderColor: Colors.white),
                    const SizedBox(height: 14),
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in PortalSection.navigation)
                    ListTile(
                      leading: Icon(section.icon),
                      title: Text(section.label),
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(section);
                      },
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Accounts'),
                    onTap: () {
                      Navigator.pop(context);
                      onAccounts();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFC2184B)),
                    title: const Text('Logout', style: TextStyle(color: Color(0xFFC2184B))),
                    onTap: () async {
                      Navigator.pop(context);
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Log out of this account?'),
                          content: const Text('Only the selected account will be signed out.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Logout')),
                          ],
                        ),
                      );
                      if (shouldLogout == true && context.mounted) {
                        await context.read<AuthProvider>().logoutSelected();
                      }
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('SRIT SKOLARO', style: TextStyle(color: AppTheme.secondaryText)),
            ),
          ],
        ),
      ),
    );
  }
}
