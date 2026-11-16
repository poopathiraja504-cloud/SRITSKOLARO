import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    required this.name,
    this.photoUrl,
    this.size = 52,
    this.borderColor,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final image = photoUrl == null || photoUrl!.isEmpty
        ? null
        : NetworkImage(photoUrl!);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.yellow,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Center(
              child: Text(
                _initials(name),
                style: TextStyle(
                  color: AppTheme.navy,
                  fontSize: size * .29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontSize: size * .29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'ST';
    return (parts.length == 1 ? parts.first.substring(0, 1) : '${parts.first[0]}${parts.last[0]}')
        .toUpperCase();
  }
}
