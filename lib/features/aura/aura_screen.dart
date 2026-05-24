import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/components/aura_app_bar.dart';
import '../../core/constants/app_colors.dart';
import '../hydration/hydration_screen.dart';
import '../calorie_calculator/calorie_calculator_screen.dart';
import '../navigation/app_drawer.dart';
import '../../core/di/service_locator.dart';
import 'aura_chat_screen.dart';

class AuraScreen extends StatefulWidget {
  const AuraScreen({super.key});

  @override
  State<AuraScreen> createState() => _AuraScreenState();
}

class _AuraScreenState extends State<AuraScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: ServiceLocator.profile.getUserProfileStream(ServiceLocator.auth.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          final profileData = snapshot.data ?? {};
          
          final int waterGoalMl = profileData['waterGoalMl'] as int? ?? 2500;
          final int dailyWaterIntake = profileData['dailyWaterIntake'] as int? ?? 0;
          final String waterGoalStr = '${(waterGoalMl / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}L';
          final String waterIntakeStr = '${(dailyWaterIntake / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}L';

          final int calorieBudget = profileData['calorieBudget'] as int? ?? 2000;
          final int dailyCaloriesConsumed = profileData['dailyCaloriesConsumed'] as int? ?? 0;
          final int caloriesRemaining = calorieBudget - dailyCaloriesConsumed;
          final String calorieBudgetStr = calorieBudget.toString();
          final String caloriesRemainingStr = (caloriesRemaining > 0 ? caloriesRemaining : 0).toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 28),
                _buildChatBotCard(context),
                const SizedBox(height: 16),
                _buildToolCard(
                  context,
                  title: 'Akıllı Hidrasyon Takibi',
                  subtitle:
                      'Günlük su tüketiminizi takip edin, hedefinize ulaşın ve sağlıklı kalın.',
                  icon: Icons.water_drop_rounded,
                  accentColor: const Color(0xFF0EA5E9),
                  gradientColors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                    const Color(0xFF0EA5E9).withValues(alpha: 0.04),
                  ],
                  stat1Label: 'Hedef',
                  stat1Value: waterGoalStr,
                  stat2Label: 'Bugün',
                  stat2Value: waterIntakeStr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HydrationScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildToolCard(
                  context,
                  title: 'Kalori & Makro Hesaplayıcı',
                  subtitle:
                      'Günlük kalori ve makro besin değerlerinizi hesaplayın, öğünlerinizi kaydedin.',
                  icon: Icons.local_fire_department_rounded,
                  accentColor: AppColors.primary,
                  gradientColors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.accent.withValues(alpha: 0.04),
                  ],
                  stat1Label: 'Hedef',
                  stat1Value: calorieBudgetStr,
                  stat2Label: 'Kalan',
                  stat2Value: caloriesRemainingStr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CalorieCalculatorScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────── AppBar ─────────────
  PreferredSizeWidget _buildAppBar() {
    return AuraAppBar(
      scaffoldKey: _scaffoldKey,
      backgroundColor: AppColors.surfaceContainerLow,
    );
  }

  // ───────────── Başlık ─────────────
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ARAÇLAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.onTertiaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Aura\nAraçlarım',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sağlıklı yaşam hedeflerinize ulaşmanız için AI destekli araçlar.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ───────────── Araç Kartı ─────────────
  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required String stat1Label,
    required String stat1Value,
    required String stat2Label,
    required String stat2Value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır — ikon + ok
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 26, color: accentColor),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 16, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Başlık
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),

            // Alt yazı
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Mini istatistikler
            Row(
              children: [
                _buildMiniStat(stat1Label, stat1Value, accentColor),
                const SizedBox(width: 20),
                _buildMiniStat(stat2Label, stat2Value, accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── AI Sohbet Kartı ─────────────
  Widget _buildChatBotCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuraChatScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF006D37),
              Color(0xFF27AE60),
              Color(0xFF2ECC71),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 26, color: Colors.white),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Sohbet Başlat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Aura Şef',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'AI mutfak asistanınla sohbet et! Tarif sor, malzeme önerisi al, pişirme teknikleri öğren.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, duration: 500.ms, curve: Curves.easeOut);
  }
}

