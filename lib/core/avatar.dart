import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Resident profile icon, stored as a single string on the backend:
///
/// * `null` / empty / anything else → default person icon.
/// * `data:image/jpeg;base64,...` → photo chosen from the gallery.
class AvatarValue {
  AvatarValue._();

  static const String photoPrefix = 'data:image/';

  static bool isPhoto(String? avatar) =>
      avatar != null && avatar.startsWith(photoPrefix);

  static Uint8List? photoBytes(String? avatar) {
    if (!isPhoto(avatar)) return null;
    final comma = avatar!.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(avatar.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}

/// Renders a profile icon at any size (used in the drawer and the editor).
class AvatarView extends StatelessWidget {
  const AvatarView({super.key, required this.avatar, this.radius = 24});

  final String? avatar;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = AvatarValue.photoBytes(avatar);

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes != null
          ? null
          : Icon(Icons.person, size: radius, color: scheme.onPrimaryContainer),
    );
  }
}
