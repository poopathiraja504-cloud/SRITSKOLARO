import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .86, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) => Opacity(
            opacity: scale.clamp(0, 1),
            child: Transform.scale(scale: scale, child: child),
          ),
          child: Image.asset(
            'assets/images/skolaro-logo.png',
            width: 250,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              'SRIT SKOLARO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
