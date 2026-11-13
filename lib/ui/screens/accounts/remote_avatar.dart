import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/models/remote_user.dart';
import '../../widgets/common.dart';

/// Foto profil dari API; jatuh ke avatar inisial bila gagal dimuat.
class RemoteAvatar extends StatelessWidget {
  const RemoteAvatar({super.key, required this.user, this.size = 44});
  final RemoteUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = InitialsAvatar(initials: user.initials, color: p.avatarColors[user.id % 6], size: size);
    if (user.image.isEmpty) return fallback;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: p.bgMuted,
        child: Image.network(
          user.image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
        ),
      ),
    );
  }
}
