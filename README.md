# SRIT SKOLARO

Responsive Flutter application for Android and Web, connected to the SRIT Firebase project.

## Requirements

- Flutter 3.35 or later
- Android Studio / Android SDK for Android builds
- A Firebase project configured as `srit-skolaro`

Only the Android and Web Flutter platforms are included in this repository.

## Local Firebase configuration

The supplied Android Firebase configuration is installed at `android/app/google-services.json` on the local machine and is intentionally ignored by Git. To set up another checkout, copy the Android app's `google-services.json` from Firebase Console to that location. Confirm its package name is `com.srit.skolaro`.

In Firebase Console:

1. Enable Email/Password and Google under **Authentication → Sign-in method**.
2. Add the Android debug and release SHA-1/SHA-256 fingerprints to the Android app. The supplied configuration has no OAuth clients yet, so Google sign-in will not work until this step is completed and the configuration file is downloaded again.
3. Create the Cloud Firestore database and Firebase Storage bucket.
4. Deploy `firestore.rules` and `storage.rules` with the Firebase CLI.
5. For Android release builds, configure an upload key in `android/key.properties`. Never commit the keystore or its passwords.
6. To use Web Push, create a Web Push certificate in Firebase Console and pass its VAPID public key to the Web script.

The Web Firebase API key is read locally from `google-services.json` by `scripts/flutter_web.ps1`; it is not embedded in source control. The Web app ID and project identifiers match the SRIT SKOLARO Firebase Web app.

## Run and build

```powershell
flutter pub get
flutter run
```

For Web, use the helper so Firebase options and the Messaging service worker are generated from local configuration:

```powershell
.\scripts\flutter_web.ps1 -Action run
.\scripts\flutter_web.ps1 -Action build
```

Optional arguments:

```powershell
.\scripts\flutter_web.ps1 -Action build `
  -GoogleWebClientId "<web-oauth-client-id>" `
  -GoogleServerClientId "<web-oauth-client-id>" `
  -VapidKey "<firebase-web-push-vapid-key>"
```

The temporary Web options file and generated service worker are removed after the script exits. Supply a VAPID key to enable Web Push.

Build a test APK:

```powershell
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. A Play Store release requires a private release keystore configured locally; this repository does not contain signing credentials.

## Student data and access rules

Student profile, attendance, documents, notifications, and device tokens are scoped under `users/{uid}`. Firestore rules deny cross-user reads and client writes to school-managed attendance/documents/notifications. Profile image writes are restricted to the signed-in user's Storage path and image size/type. Configure Firebase-side administrative ingestion separately to publish those records.
