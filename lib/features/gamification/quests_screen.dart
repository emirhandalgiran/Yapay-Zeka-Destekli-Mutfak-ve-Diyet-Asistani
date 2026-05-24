import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import 'data/gamification_service.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  String get _userId => ServiceLocator.auth.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Günlük Görevler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: ServiceLocator.gamification.getUserQuestProgress(_userId),
        builder: (context, snapshot) {
          final progress = snapshot.data ?? {};
          final quests = GamificationService.getDailyQuests();
          final int streak = progress['loginStreak'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Kartı
                _buildStreakCard(streak),
                const SizedBox(height: 24),

                // Görev Başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bugünkü Görevler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_countCompleted(quests, progress)}/${quests.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Görev Listesi
                ...List.generate(quests.length, (index) {
                  final quest = quests[index];
                  final isCompleted = _isQuestCompleted(quest, progress);
                  final currentProgress = _getQuestProgress(quest, progress);

                  return _buildQuestTile(quest, isCompleted, currentProgress, index);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ───────────── Streak Kartı ─────────────
  Widget _buildStreakCard(int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.12),
            const Color(0xFFEF4444).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günlük Seri',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'gün',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Streak göstergesi (7 gün)
          Row(
            children: List.generate(7, (i) {
              final isActive = i < streak.clamp(0, 7);
              return Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Container(
                  width: 8,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  // ───────────── Görev Kartı ─────────────
  Widget _buildQuestTile(
    Map<String, dynamic> quest,
    bool isCompleted,
    double currentProgress,
    int index,
  ) {
    final int xp = quest['xp'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // İkon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                quest['icon'] ?? '🎯',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest['title'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+$xp XP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quest['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),

                // İlerleme Çubuğu
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentProgress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor:
                        AppColors.outlineVariant.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.primary : AppColors.accent,
                    ),
                  ),
                ),
                if (quest['id'] == 'quest_water' && !isCompleted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {
                         ServiceLocator.gamification.incrementDailyQuest(_userId, 'dailyWaterIntake', amount: 250);
                      },
                      icon: const Icon(Icons.water_drop, size: 16),
                      label: const Text('250ml Su İçtim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tamamlanma İkonu
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: isCompleted
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.3),
            size: 24,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 80 * index), duration: 400.ms)
        .slideX(begin: 0.05);
  }

  // ───────────── Yardımcı Fonksiyonlar ─────────────
  bool _isQuestCompleted(
      Map<String, dynamic> quest, Map<String, dynamic> progress) {
    final type = quest['type'] as String?;
    final field = quest['field'] as String?;
    if (field == null) return false;

    if (type == 'percentage') {
      final current = (progress[field] ?? 0) as num;
      final goal = (progress['waterGoalMl'] ?? 2500) as num;
      final targetPercent = (quest['targetPercent'] ?? 50) as num;
      return goal > 0 && (current / goal * 100) >= targetPercent;
    } else {
      final current = (progress[field] ?? 0) as num;
      final target = (quest['target'] ?? 1) as num;
      return current >= target;
    }
  }

  double _getQuestProgress(
      Map<String, dynamic> quest, Map<String, dynamic> progress) {
    final type = quest['type'] as String?;
    final field = quest['field'] as String?;
    if (field == null) return 0.0;

    if (type == 'percentage') {
      final current = (progress[field] ?? 0) as num;
      final goal = (progress['waterGoalMl'] ?? 2500) as num;
      final targetPercent = (quest['targetPercent'] ?? 50) as num;
      if (goal <= 0 || targetPercent <= 0) return 0.0;
      return (current / goal * 100) / targetPercent;
    } else {
      final current = (progress[field] ?? 0) as num;
      final target = (quest['target'] ?? 1) as num;
      if (target <= 0) return 0.0;
      return current / target;
    }
  }

  int _countCompleted(
      List<Map<String, dynamic>> quests, Map<String, dynamic> progress) {
    return quests.where((q) => _isQuestCompleted(q, progress)).length;
  }
}
