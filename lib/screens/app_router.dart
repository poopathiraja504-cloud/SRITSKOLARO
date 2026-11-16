import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/splash_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _splashFinished = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _splashFinished = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_splashFinished || auth.initializing) {
      return const SplashScreen();
    }
    if (!auth.isSignedIn) return const LoginScreen();
    return const DashboardScreen();
  }
}
