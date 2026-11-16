import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/auth_error.dart';
import '../widgets/student_avatar.dart';
import 'login_screen.dart';

class AccountsSheet extends StatelessWidget {
  const AccountsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accounts = auth.accounts;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.viewPaddingOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.secondaryText,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Accounts', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Switch between your signed-in accounts',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final account in accounts)
                  _AccountTile(
                    account: account,
                    current: account.id == auth.activeAccountId,
                    onSelect: () async {
                      try {
                        await auth.switchAccount(account.id);
                        if (context.mounted) Navigator.pop(context);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyAuthError(error))),
                          );
                        }
                      }
                    },
                    onRemove: account.id == auth.activeAccountId
                        ? null
                        : () => _removeAccount(context, account.id),
                  ),
                const Divider(height: 22),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EDF8),
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.add),
                  ),
                  title: const Text('Add another account', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Sign in without logging out of the current one'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(addAnother: true),
                    ));
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFC2184B)),
                  title: const Text('Logout', style: TextStyle(color: Color(0xFFC2184B), fontWeight: FontWeight.w800)),
                  onTap: () => _confirmLogout(context, auth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAccount(BuildContext context, String id) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this account?'),
        content: const Text('This signs the account out on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (shouldRemove == true && context.mounted) {
      await context.read<AuthProvider>().removeAccount(id);
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of this account?'),
        content: const Text('Only the selected account will be signed out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC2184B)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      Navigator.pop(context);
      await auth.logoutSelected();
    }
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.current,
    required this.onSelect,
    required this.onRemove,
  });

  final AccountSummary account;
  final bool current;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: current ? const Color(0xFFE8EDF8) : Theme.of(context).colorScheme.surface,
      child: ListTile(
        onTap: onSelect,
        leading: StudentAvatar(name: account.name, photoUrl: account.photoUrl, size: 48),
        title: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(account.email, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: current
            ? const Chip(label: Text('Current'))
            : IconButton(
                tooltip: 'Remove account from this device',
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}
