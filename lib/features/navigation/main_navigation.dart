import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../home/home_screen.dart';
import '../recipes/recipes_screen.dart';
import '../aura/aura_screen.dart';
import '../social/social_screen.dart';
import '../social/reels/reels_feed_screen.dart';
import '../profile/profile_screen.dart';
import '../../l10n/app_localizations.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const HomeScreen(),
    const RecipesScreen(),
    const AuraScreen(),
    const SocialScreen(),
    ReelsFeedScreen(isTabActive: _currentIndex == 4),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final items = <_NavItem>[
      _NavItem(icon: Icons.home, filledIcon: Icons.home, label: l10n.homeTab.toUpperCase()),
      _NavItem(
          icon: Icons.restaurant_menu_outlined,
          filledIcon: Icons.restaurant_menu,
          label: l10n.recipesTab.toUpperCase()),
      _NavItem(
          icon: Icons.auto_awesome_outlined,
          filledIcon: Icons.auto_awesome,
          label: l10n.auraTab.toUpperCase()),
      _NavItem(
          icon: Icons.group_outlined,
          filledIcon: Icons.group,
          label: l10n.socialTab.toUpperCase()),
      _NavItem(
          icon: Icons.smart_display_outlined,
          filledIcon: Icons.smart_display,
          label: l10n.reelsTab.toUpperCase()),
      _NavItem(
          icon: Icons.person_outlined,
          filledIcon: Icons.person,
          label: l10n.profileTab.toUpperCase()),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(items),
    );
  }

  Widget _buildBottomNavBar(List<_NavItem> items) {

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isActive = _currentIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 14 : 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.filledIcon : item.icon,
                        color: isActive
                            ? AppColors.accent
                            : AppColors.onSurface.withValues(alpha: 0.4),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isActive
                              ? AppColors.accent
                              : AppColors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData filledIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
  });
}

