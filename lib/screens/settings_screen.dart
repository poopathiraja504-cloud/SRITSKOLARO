import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/student_avatar.dart';
import 'accounts_sheet.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser!;
    final profile = auth.profile;
    final name = profile?.name ?? user.displayName ?? user.email?.split('@').first ?? 'Student';
    final photo = profile?.profilePhoto ?? user.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: StudentAvatar(name: name, photoUrl: photo, size: 56),
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(profile?.email ?? user.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark theme'),
                  value: theme.isDark,
                  onChanged: theme.setDarkMode,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Notifications'),
                  subtitle: Text('Campus updates are delivered through Firebase notifications.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Accounts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AccountsSheet(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Support'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(context, Uri.parse('https://www.sritcbe.ac.in')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'SRIT SKOLARO',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the SRIT website.')));
      }
    } catch (error, stackTrace) {
      debugPrint('Could not open support website: $error\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the SRIT website.')));
      }
    }
  }
}
