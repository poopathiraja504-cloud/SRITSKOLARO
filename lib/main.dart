import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_router.dart';
import 'services/firebase_bootstrap.dart';
import 'utils/app_theme.dart';
import 'widgets/app_error_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  AuthProvider? authProvider;
  try {
    await FirebaseBootstrap.initialize();
    authProvider = AuthProvider();
    await authProvider.initialize();
  } catch (error, stackTrace) {
    startupError = error;
    debugPrint('Application startup failed: $error\n$stackTrace');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(SritSkolaroApp(
    authProvider: authProvider,
    themeProvider: themeProvider,
    startupError: startupError,
  ));
}

class SritSkolaroApp extends StatelessWidget {
  const SritSkolaroApp({
    required this.authProvider,
    required this.themeProvider,
    required this.startupError,
    super.key,
  });

  final AuthProvider? authProvider;
  final ThemeProvider themeProvider;
  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        if (authProvider != null)
          ChangeNotifierProvider.value(value: authProvider!),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'SRIT SKOLARO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          home: startupError == null
              ? const AppRouter()
              : AppErrorView(
                  title: 'Unable to connect to Firebase',
                  message: _startupMessage(startupError!),
                ),
        ),
      ),
    );
  }

  String _startupMessage(Object error) {
    if (error is FirebaseException) {
      return '${error.message ?? error.code}. Verify the local Firebase setup and try again.';
    }
    return error is StateError
        ? error.message
        : 'Firebase could not be initialized. Verify the app configuration and try again.';
  }
}
