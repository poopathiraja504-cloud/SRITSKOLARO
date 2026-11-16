import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/student_profile.dart';
import '../providers/auth_provider.dart' as srit_auth;
import '../services/profile_service.dart';
import '../utils/app_theme.dart';
import '../widgets/student_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = const ProfileService();
  Uint8List? _selectedImage;
  String? _selectedContentType;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _selectImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (contentType == null) {
        setState(() {
          _message = 'Choose a JPEG, PNG, or WebP image.';
          _messageIsError = true;
        });
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = bytes;
        _selectedContentType = contentType;
        _message = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error is FirebaseException
              ? error.message ?? 'Could not open the image picker.'
              : 'Could not open the image picker. Please try again.';
          _messageIsError = true;
        });
      }
    }
  }

  Future<void> _saveImage() async {
    final auth = context.read<srit_auth.AuthProvider>();
    final user = auth.currentUser;
    final app = auth.currentApp;
    final profile = _profile(auth, user);
    final image = _selectedImage;
    final contentType = _selectedContentType;
    if (user == null || app == null || profile == null || image == null || contentType == null) {
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final updated = await _profileService.savePhoto(
        user: user,
        app: app,
        profile: profile,
        bytes: image,
        contentType: contentType,
      );
      await auth.refreshProfile(updated);
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _selectedContentType = null;
          _message = 'Profile picture saved successfully.';
          _messageIsError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error is FirebaseException
              ? error.message ?? 'Unable to save the profile picture.'
              : error is StateError
                  ? error.message
                  : 'Unable to save the profile picture. Please try again.';
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  StudentProfile? _profile(srit_auth.AuthProvider auth, User? user) {
    final loaded = auth.profile;
    if (loaded != null) return loaded;
    if (user == null) return null;
    return StudentProfile(
      uid: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Student',
      email: user.email ?? '',
      profilePhoto: user.photoURL ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<srit_auth.AuthProvider>();
    final user = auth.currentUser;
    final profile = _profile(auth, user);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (auth.profileError != null)
              _InlineMessage(message: auth.profileError!, isError: true),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    StudentAvatar(name: profile.name, photoUrl: profile.profilePhoto, size: 78),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          if (profile.studentId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(profile.studentId, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryText)),
                          ],
                          const SizedBox(height: 3),
                          Text(profile.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryText)),
                          if (profile.department.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(profile.department, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  children: [
                    Text('Profile Picture', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: _selectedImage != null
                                ? Image.memory(_selectedImage!, fit: BoxFit.cover)
                                : profile.profilePhoto.isNotEmpty
                                    ? Image.network(
                                        profile.profilePhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _InitialsPreview(profile: profile),
                                      )
                                    : _InitialsPreview(profile: profile),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _selectImage,
                              icon: const Icon(Icons.add_photo_alternate_outlined, size: 24),
                              label: const Text('Change', style: TextStyle(fontSize: 18)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.navy,
                                backgroundColor: const Color(0xFFE8EDF7),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: FilledButton(
                              onPressed: _selectedImage == null || _saving ? null : _saveImage,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.navy,
                                disabledBackgroundColor: const Color(0xFFE1E3E9),
                                disabledForegroundColor: const Color(0xFF9AA2B8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _saving
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      _InlineMessage(message: _message!, isError: _messageIsError),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsPreview extends StatelessWidget {
  const _InitialsPreview({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.yellow,
      child: Center(
        child: Text(
          profile.initials,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 54,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Theme.of(context).colorScheme.error : Colors.green.shade700;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}
