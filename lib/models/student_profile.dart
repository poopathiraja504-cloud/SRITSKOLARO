class StudentProfile {
  const StudentProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.studentId = '',
    this.department = '',
    this.profilePhoto = '',
  });

  final String uid;
  final String name;
  final String email;
  final String studentId;
  final String department;
  final String profilePhoto;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'ST';
    return (parts.length == 1 ? parts.first.substring(0, 1) : '${parts.first[0]}${parts.last[0]}')
        .toUpperCase();
  }

  factory StudentProfile.fromMap(String uid, Map<String, dynamic> data, {
    required String fallbackName,
    required String fallbackEmail,
  }) {
    final nestedProfile = data['profile'];
    final profile = nestedProfile is Map<String, dynamic> ? nestedProfile : <String, dynamic>{};
    return StudentProfile(
      uid: uid,
      name: _firstValue([
            profile['username'],
            profile['name'],
            data['displayName'],
            data['name'],
            data['username'],
            fallbackName,
          ]) ??
          'Student',
      email: _firstValue([data['email'], fallbackEmail]) ?? '',
      studentId: _firstValue([data['studentId'], data['admissionNumber']]) ?? '',
      department: _firstValue([data['department'], data['course']]) ?? '',
      profilePhoto: _firstValue([
            profile['profilePhoto'],
            data['profilePhoto'],
            data['avatarUrl'],
          ]) ??
          '',
    );
  }

  static String? _firstValue(Iterable<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
