import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/student_profile.dart';

class ProfileService {
  const ProfileService();

  Future<StudentProfile> load(User user, FirebaseApp app) async {
    final firestore = FirebaseFirestore.instanceFor(app: app);
    final reference = firestore.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final profile = StudentProfile.fromMap(
      user.uid,
      data,
      fallbackName: user.displayName ?? user.email?.split('@').first ?? 'Student',
      fallbackEmail: user.email ?? '',
    );
    final resolvedProfile = profile.profilePhoto.isEmpty && user.photoURL != null
        ? StudentProfile(
            uid: profile.uid,
            name: profile.name,
            email: profile.email,
            studentId: profile.studentId,
            department: profile.department,
            profilePhoto: user.photoURL!,
          )
        : profile;

    if (!snapshot.exists) {
      await reference.set({
        'uid': user.uid,
        'displayName': profile.name,
        'email': profile.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return resolvedProfile;
  }

  Future<StudentProfile> savePhoto({
    required User user,
    required FirebaseApp app,
    required StudentProfile profile,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('Choose an image smaller than 5 MB.');
    }
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(contentType)) {
      throw StateError('Choose a JPEG, PNG, or WebP image.');
    }

    final storage = FirebaseStorage.instanceFor(app: app);
    final reference = storage.ref('users/${user.uid}/profile/profile-picture');
    final snapshot = await reference.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final photoUrl = await snapshot.ref.getDownloadURL();
    final firestore = FirebaseFirestore.instanceFor(app: app);
    await firestore.collection('users').doc(user.uid).set({
      'profilePhoto': photoUrl,
      'profile': {'profilePhoto': photoUrl},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return StudentProfile(
      uid: profile.uid,
      name: profile.name,
      email: profile.email,
      studentId: profile.studentId,
      department: profile.department,
      profilePhoto: photoUrl,
    );
  }
}
