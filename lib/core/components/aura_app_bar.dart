import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/notifications/notifications_screen.dart';
import 'custom_user_avatar.dart';

/// Tüm ana ekranlarda kullanılan ortak AppBar widget'ı.
/// DRY prensibi gereği tek bir yerde tanımlanır.
class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color? backgroundColor;

  const AuraAppBar({
    super.key,
    required this.scaffoldKey,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: Icon(Icons.menu, color: AppColors.accent),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      title: Text(
        'AuraCook',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CustomUserAvatar(radius: 17),
        ),
      ],
    );
  }
}
