import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/auth_error.dart';

enum _AuthMode { signIn, createAccount, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.addAnother = false, super.key});

  final bool addAnother;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_mode != _AuthMode.forgotPassword &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_mode == _AuthMode.forgotPassword &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      if (_mode == _AuthMode.forgotPassword) {
        await auth.sendPasswordReset(_emailController.text);
        if (mounted) {
          setState(() => _success = 'Password reset email sent. Check your inbox.');
        }
      } else if (_mode == _AuthMode.createAccount) {
        await auth.createAccount(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
        _finishSignIn();
      } else {
        await auth.signInWithEmail(
          _emailController.text,
          _passwordController.text,
          addAnother: widget.addAnother,
        );
        _finishSignIn();
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .signInWithGoogle(addAnother: widget.addAnother);
      _finishSignIn();
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finishSignIn() {
    if (widget.addAnother && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = switch (_mode) {
      _AuthMode.signIn => widget.addAnother ? 'Add another account' : 'Welcome back',
      _AuthMode.createAccount => 'Create your account',
      _AuthMode.forgotPassword => 'Reset your password',
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                children: [
                  if (widget.addAnother)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: AppTheme.deepNavy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/skolaro-logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SRIT SKOLARO',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: isDark ? Colors.white : AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your campus, connected.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            _mode == _AuthMode.forgotPassword
                                ? 'We’ll email you a secure password reset link.'
                                : 'Sign in with your student account to continue.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 22),
                          if (_mode == _AuthMode.signIn) ...[
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _googleSignIn,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Row(children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('OR CONTINUE WITH EMAIL'),
                                ),
                                Expanded(child: Divider()),
                              ]),
                            ),
                          ],
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_mode == _AuthMode.createAccount) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) => value == null || value.trim().isEmpty
                                        ? 'Enter your name.'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                                        ? null
                                        : 'Enter a valid email address.';
                                  },
                                ),
                                if (_mode != _AuthMode.forgotPassword) ...[
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    autofillHints: _mode == _AuthMode.createAccount
                                        ? const [AutofillHints.newPassword]
                                        : const [AutofillHints.password],
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Enter your password.';
                                      if (_mode == _AuthMode.createAccount && value.length < 6) {
                                        return 'Use at least 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_mode == _AuthMode.signIn && !widget.addAnother)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                          _mode = _AuthMode.forgotPassword;
                                          _error = null;
                                          _success = null;
                                        }),
                                child: const Text('Forgot password?'),
                              ),
                            )
                          else
                            const SizedBox(height: 14),
                          if (_error != null) ...[
                            _MessageBox(message: _error!, isError: true),
                            const SizedBox(height: 12),
                          ],
                          if (_success != null) ...[
                            _MessageBox(message: _success!, isError: false),
                            const SizedBox(height: 12),
                          ],
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.navy,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _busy
                                ? const SizedBox.square(
                                    dimension: 21,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(switch (_mode) {
                                    _AuthMode.signIn => 'Sign in',
                                    _AuthMode.createAccount => 'Create account',
                                    _AuthMode.forgotPassword => 'Send reset link',
                                  }),
                          ),
                          const SizedBox(height: 12),
                          if (!widget.addAnother)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _mode = _mode == _AuthMode.createAccount
                                            ? _AuthMode.signIn
                                            : _mode == _AuthMode.forgotPassword
                                                ? _AuthMode.signIn
                                                : _AuthMode.createAccount;
                                        _error = null;
                                        _success = null;
                                      }),
                              child: Text(switch (_mode) {
                                _AuthMode.signIn => 'New to SRIT? Create account',
                                _AuthMode.createAccount => 'Already have an account? Sign in',
                                _AuthMode.forgotPassword => 'Back to sign in',
                              }),
                            ),
                          if (widget.addAnother)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sri Ramakrishna Institute of Technology · Coimbatore',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Theme.of(context).colorScheme.error : Colors.green.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}
