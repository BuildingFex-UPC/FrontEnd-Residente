import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Resident profile icon, stored as a single string on the backend:
///
/// * `null` / empty  → default person icon.
/// * `preset|😀|#FF5722` → emoji on a solid color circle.
/// * `data:image/jpeg;base64,...` → photo chosen from the gallery.
class AvatarValue {
  AvatarValue._();

  static const String presetPrefix = 'preset|';
  static const String photoPrefix = 'data:image/';

  /// Emojis the resident can pick from the avatar grid.
  static const emojis = <String>[
    '😀', '😊', '😎', '🙂', '😇', '🧐',
    '😺', '🐶', '🐼', '🦊', '🦁', '🐨',
    '🌟', '🔥', '🍀', '⚽', '🎮', '📚',
    '🎧', '🌵', '🌈', '💡', '🚀', '🎯',
  ];

  /// Solid colors for the preset background.
  static const colors = <Color>[
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF00BCD4),
  ];

  static String preset(String emoji, Color color) {
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return '$presetPrefix$emoji|$hex';
  }

  static String? emojiOf(String? avatar) {
    if (avatar == null || !avatar.startsWith(presetPrefix)) return null;
    final parts = avatar.substring(presetPrefix.length).split('|');
    return parts.isEmpty ? null : parts.first;
  }

  static Color? colorOf(String? avatar) {
    if (avatar == null || !avatar.startsWith(presetPrefix)) return null;
    final parts = avatar.substring(presetPrefix.length).split('|');
    if (parts.length < 2) return null;
    final hex = parts[1].replaceFirst('#', '');
    if (hex.length != 6) return null;
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0);
  }

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
    final emoji = AvatarValue.emojiOf(avatar);
    final color = AvatarValue.colorOf(avatar);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color ?? scheme.primaryContainer,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes != null
          ? null
          : Text(
              emoji ?? '👤',
              style: TextStyle(fontSize: radius),
            ),
    );
  }
}
