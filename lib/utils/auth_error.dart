import 'package:firebase_auth/firebase_auth.dart';

String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Network unavailable. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a little and try again.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';
      default:
        return error.message ?? 'Sign-in failed. Please try again.';
    }
  }
  return error is StateError ? error.message : 'Sign-in failed. Please try again.';
}
