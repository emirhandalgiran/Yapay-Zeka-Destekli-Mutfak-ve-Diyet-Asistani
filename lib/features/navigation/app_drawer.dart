import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../planner/meal_planner_screen.dart';
import '../profile/about_screen.dart';
import '../health/health_dashboard_screen.dart';
import '../profile/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.calendar_month_outlined,
                      label: 'Haftalık Planlayıcı',
                      onTap: () => _navigateTo(
                        context,
                        const MealPlannerScreen(),
                      ),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'Hakkımızda & Sürdürülebilirlik',
                      onTap: () => _navigateTo(
                        context,
                        const AboutScreen(),
                      ),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.health_and_safety_outlined,
                      label: 'Sağlık ve Beslenme',
                      onTap: () => _navigateTo(
                        context,
                        const HealthDashboardScreen(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                        height: 1,
                      ),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_outlined,
                      label: 'Tercihler',
                      onTap: () {
                        _navigateTo(context, const ProfileScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Bottom spaced
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.restaurant,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'AuraCook',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
