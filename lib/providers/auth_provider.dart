import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_profile.dart';
import '../services/firebase_bootstrap.dart';
import '../services/profile_service.dart';

class AccountSummary {
  const AccountSummary({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String id;
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
}

class _AccountContext {
  const _AccountContext(this.app, this.auth);

  final FirebaseApp app;
  final FirebaseAuth auth;
  String get id => app.name;
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({ProfileService profileService = const ProfileService()})
      : _profileService = profileService;

  static const _defaultName = '[DEFAULT]';
  static const _accountAppsKey = 'srit.auth.accountApps';
  static const _activeAccountKey = 'srit.auth.activeAccount';
  static Future<void>? _googleInitialization;

  final ProfileService _profileService;
  final Map<String, _AccountContext> _contexts = {};
  final Map<String, User> _users = {};
  final Map<String, StudentProfile> _profiles = {};
  final Map<String, StreamSubscription<User?>> _subscriptions = {};
  SharedPreferences? _preferences;
  String? _activeId;
  String? _profileError;
  bool _initializing = true;
  bool _disposed = false;

  bool get initializing => _initializing;
  String? get profileError => _profileError;
  String? get activeAccountId => _activeId;
  User? get currentUser => _activeId == null ? null : _users[_activeId];
  FirebaseApp? get currentApp =>
      _activeId == null ? null : _contexts[_activeId]?.app;
  StudentProfile? get profile =>
      _activeId == null ? null : _profiles[_activeId];
  bool get isSignedIn => currentUser != null;

  List<AccountSummary> get accounts => _users.entries.map((entry) {
        final user = entry.value;
        final profile = _profiles[entry.key];
        return AccountSummary(
          id: entry.key,
          uid: user.uid,
          name: profile?.name ??
              user.displayName ??
              user.email?.split('@').first ??
              'Student',
          email: profile?.email ?? user.email ?? '',
          photoUrl: profile?.profilePhoto.isNotEmpty == true
              ? profile!.profilePhoto
              : user.photoURL,
        );
      }).toList();

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final savedNames = _preferences!.getStringList(_accountAppsKey) ?? const [];
    final names = <String>{_defaultName, ...savedNames};

    for (final name in names) {
      try {
        final context = await _restoreContext(name);
        _contexts[name] = context;
        _watch(context);
      } catch (error, stackTrace) {
        debugPrint('Could not restore account session "$name": $error\n$stackTrace');
      }
    }

    await Future.wait(_contexts.values.map((context) async {
      try {
        await context.auth.authStateChanges().first;
      } catch (error) {
        debugPrint('Could not read auth state for "${context.id}": $error');
      }
    }));

    final preferred = _preferences!.getString(_activeAccountKey);
    if (preferred != null && _users.containsKey(preferred)) {
      _activeId = preferred;
    } else {
      _activeId = _users.keys.firstOrNull;
    }
    _initializing = false;
    if (_activeId != null) unawaited(_loadActiveProfile());
    _notify();
  }

  Future<_AccountContext> _restoreContext(String name) async {
    if (name == _defaultName) {
      return _AccountContext(
        Firebase.app(),
        FirebaseAuth.instance,
      );
    }
    final existing = Firebase.apps.where((candidate) => candidate.name == name);
    final app = existing.isNotEmpty
        ? existing.first
        : await Firebase.initializeApp(
            name: name,
            options: Firebase.app().options,
          );
    return _AccountContext(app, FirebaseAuth.instanceFor(app: app));
  }

  void _watch(_AccountContext context) {
    _subscriptions[context.id] = context.auth.authStateChanges().listen(
      (user) => _onAuthStateChanged(context, user),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Auth state listener failed (${context.id}): $error');
      },
    );
  }

  void _onAuthStateChanged(_AccountContext context, User? user) {
    if (_disposed) return;
    if (user == null) {
      _users.remove(context.id);
      _profiles.remove(context.id);
      if (_activeId == context.id) _activeId = _users.keys.firstOrNull;
      unawaited(_saveAccounts());
      _notify();
      if (_activeId != null) unawaited(_loadActiveProfile());
      return;
    }

    _users[context.id] = user;
    _activeId ??= context.id;
    unawaited(_saveAccounts());
    if (_activeId == context.id) unawaited(_loadActiveProfile());
    _notify();
  }

  Future<void> _loadActiveProfile() async {
    final activeId = _activeId;
    if (activeId == null) return;

    final user = _users[activeId];
    final context = _contexts[activeId];
    if (user == null || context == null) return;

    _profileError = null;
    try {
      final result = await _profileService.load(user, context.app);
      if (_activeId == activeId && _users[activeId]?.uid == user.uid) {
        _profiles[activeId] = result;
      }
    } catch (error, stackTrace) {
      debugPrint('Could not load student profile: $error\n$stackTrace');
      if (_activeId == activeId) {
        _profileError = 'Profile information could not be loaded.';
      }
    }
    _notify();
  }

  Future<void> signInWithEmail(
    String email,
    String password, {
    bool addAnother = false,
  }) async {
    final context = await _targetContext(addAnother);
    try {
      await context.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _activate(context.id);
    } catch (_) {
      await _discardEmptySecondary(context);
      rethrow;
    }
  }

  Future<void> createAccount(String name, String email, String password) async {
    final context = await _targetContext(false);
    try {
      final credential = await context.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      await _activate(context.id);
    } catch (_) {
      await _discardEmptySecondary(context);
      rethrow;
    }
  }

  Future<void> signInWithGoogle({bool addAnother = false}) async {
    final context = await _targetContext(addAnother);
    try {
      if (kIsWeb) {
        await context.auth.signInWithPopup(GoogleAuthProvider());
      } else {
        _googleInitialization ??= GoogleSignIn.instance.initialize(
          serverClientId: FirebaseBootstrap.androidServerClientId.isEmpty
              ? null
              : FirebaseBootstrap.androidServerClientId,
        );
        await _googleInitialization;
        final account = await GoogleSignIn.instance.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw StateError('Google did not return an ID token. Check OAuth setup.');
        }
        await context.auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }
      await _activate(context.id);
    } catch (_) {
      await _discardEmptySecondary(context);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final context = _activeId == null ? null : _contexts[_activeId];
    await (context?.auth ?? FirebaseAuth.instance)
        .sendPasswordResetEmail(email: email.trim());
  }

  Future<void> refreshProfile(StudentProfile profile) async {
    final id = _activeId;
    if (id == null || _users[id]?.uid != profile.uid) return;
    _profiles[id] = profile;
    _profileError = null;
    _notify();
  }

  Future<void> switchAccount(String id) async {
    if (!_users.containsKey(id)) {
      throw StateError('This account is no longer signed in.');
    }
    await _activate(id);
  }

  Future<void> logoutSelected() async {
    final id = _activeId;
    if (id == null) return;
    final context = _contexts[id];
    if (context == null) return;
    final remaining = _users.keys.where((accountId) => accountId != id).toList();
    _activeId = remaining.firstOrNull;
    _profiles.remove(id);
    await _preferences?.setString(_activeAccountKey, _activeId ?? '');
    _notify();
    await context.auth.signOut();
    await _removeSecondaryIfNeeded(id, context);
  }

  Future<void> removeAccount(String id) async {
    final context = _contexts[id];
    if (context == null || !_users.containsKey(id)) return;
    if (_activeId == id) {
      _activeId = _users.keys.where((accountId) => accountId != id).firstOrNull;
    }
    _profiles.remove(id);
    await _preferences?.setString(_activeAccountKey, _activeId ?? '');
    _notify();
    await context.auth.signOut();
    await _removeSecondaryIfNeeded(id, context);
  }

  Future<void> _removeSecondaryIfNeeded(
    String id,
    _AccountContext context,
  ) async {
    if (id == _defaultName) return;
    await _subscriptions.remove(id)?.cancel();
    _contexts.remove(id);
    await _saveAccounts();
    await context.app.delete();
  }

  Future<_AccountContext> _targetContext(bool addAnother) async {
    if (!addAnother || _users.isEmpty) {
      return _contexts[_defaultName] ??
          (throw StateError('Firebase authentication is not initialized.'));
    }
    final name = 'srit-account-${DateTime.now().microsecondsSinceEpoch}';
    final app = await Firebase.initializeApp(
      name: name,
      options: Firebase.app().options,
    );
    final context = _AccountContext(app, FirebaseAuth.instanceFor(app: app));
    _contexts[name] = context;
    _watch(context);
    return context;
  }

  Future<void> _activate(String id) async {
    _activeId = id;
    await _preferences?.setString(_activeAccountKey, id);
    _profileError = null;
    _notify();
    unawaited(_loadActiveProfile());
  }

  Future<void> _discardEmptySecondary(_AccountContext context) async {
    if (context.id == _defaultName || context.auth.currentUser != null) return;
    await _subscriptions.remove(context.id)?.cancel();
    _contexts.remove(context.id);
    await context.app.delete();
  }

  Future<void> _saveAccounts() async {
    final names = _users.keys.where((id) => id != _defaultName).toList();
    await _preferences?.setStringList(_accountAppsKey, names);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
