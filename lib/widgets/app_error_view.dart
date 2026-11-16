import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 54, color: AppTheme.orange),
                const SizedBox(height: 18),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(onPressed: onRetry, child: const Text('Try again')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
