import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen>
    with SingleTickerProviderStateMixin {
  double _goalMl = 2500; // ml
  String get _userId => ServiceLocator.auth.currentUser?.uid ?? 'unknown';
  late AnimationController _pulseController;
  bool _isLoadingProfile = true;

  final List<int> _quickAddOptions = [150, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ServiceLocator.profile.getUserProfile(_userId);
      if (profile != null && mounted) {
        setState(() {
          _goalMl = (profile['goalMl'] ?? 2500).toDouble();
          _isLoadingProfile = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Progress calculation logic is moved into build method


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
          'Hidrasyon Takibi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Color(0xFF0EA5E9)),
            onPressed: () => _showCalculatorDialog(),
          ),
        ],
      ),
      body: _isLoadingProfile
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ServiceLocator.hydration.getDailyHydration(_userId, DateTime.now()),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final data = snapshot.data?.data() ?? {};
          final currentMl = (data['amountMl'] as num?)?.toDouble() ?? 0.0;
          final logsData = data['logs'] as List<dynamic>? ?? [];
          
          final List<_WaterEntry> todayLog = logsData.map((log) {
            final logMap = log as Map<String, dynamic>;
            return _WaterEntry(
              time: logMap['time'] as String? ?? '',
              ml: logMap['ml'] as int? ?? 0,
              icon: IconData(logMap['iconCode'] as int? ?? Icons.water_drop_outlined.codePoint, fontFamily: 'MaterialIcons'),
            );
          }).toList();
          
          // En yeni kayıtlar üstte görünsün diye ters çevir
          final reversedLogs = todayLog.reversed.toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              children: [
                _buildWaterGauge(currentMl),
                const SizedBox(height: 28),
                _buildQuickAddSection(),
                const SizedBox(height: 28),
                _buildTodayLogSection(reversedLogs),
                const SizedBox(height: 24),
                _buildTipsCard(),
              ],
            ),
          );
        }
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Dairesel Su Göstergesi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildWaterGauge(double currentMl) {
    final remaining = (_goalMl - currentMl).clamp(0, _goalMl);
    final progress = (currentMl / _goalMl).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0EA5E9).withValues(alpha: 0.06),
            const Color(0xFF0EA5E9).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arka halka
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 14,
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // İlerleme halkası
                SizedBox(
                  width: 200,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 14,
                        color: const Color(0xFF0EA5E9),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                // Ortadaki yazı
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Icon(
                          Icons.water_drop,
                          size: 32,
                          color: const Color(0xFF0EA5E9).withValues(
                              alpha: 0.5 + _pulseController.value * 0.5),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentMl.toInt()} ml',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '/ ${_goalMl.toInt()} ml',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kalan ${remaining.toInt()} ml ğŸ’§',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0EA5E9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '% ${(progress * 100).toInt()} tamamlandı',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Hızlı Ekleme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Ekle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: _quickAddOptions.map((ml) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: ml == _quickAddOptions.last ? 0 : 10),
                child: GestureDetector(
                  onTap: () async {
                    // Cihaz titresimi veya kisa optimistik UI guncellemesi eklenebilir
                    await ServiceLocator.hydration.logWaterIntake(_userId, ml, DateTime.now());
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 22,
                          color:
                              const Color(0xFF0EA5E9).withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+$ml',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'ml',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Günlük Kayıtlar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTodayLogSection(List<_WaterEntry> todayLog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bugünkü Kayıtlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${todayLog.length} kayıt',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(todayLog.length, (i) {
          final entry = todayLog[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(entry.icon, size: 18, color: const Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.ml} ml',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        entry.time,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle,
                    size: 20,
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.6)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ İpucu Kartı â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: Color(0xFF0EA5E9), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günlük İpucu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yemeklerden 30 dk önce su içmek sindirimi kolaylaştırır ve tokluk hissi verir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showCalculatorDialog() {
    double weight = 70.0;
    double activityLevel = 1.55; // Default Orta

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Su Hedefi Hesaplayıcı', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Kilo ve hareket durumunuza göre günlük su ihtiyacınızı hesaplayın.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: weight.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                      onChanged: (val) => weight = double.tryParse(val) ?? 70.0,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<double>(
                      initialValue: activityLevel,
                      decoration: const InputDecoration(labelText: 'Hareket Seviyesi'),
                      items: const [
                        DropdownMenuItem(value: 1.2, child: Text('Hareketsiz')),
                        DropdownMenuItem(value: 1.375, child: Text('Hafif Hareketli')),
                        DropdownMenuItem(value: 1.55, child: Text('Orta Hareketli')),
                        DropdownMenuItem(value: 1.725, child: Text('Çok Hareketli')),
                        DropdownMenuItem(value: 1.9, child: Text('Ekstra Hareketli')),
                      ],
                      onChanged: (val) => setModalState(() => activityLevel = val ?? 1.55),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          // Su Hesaplama: kilo x 35ml + Hareket Payı
                          double calculatedMl = weight * 35.0;
                          if (activityLevel >= 1.7) {
                            calculatedMl += 1000;
                          } else if (activityLevel >= 1.3) {
                            calculatedMl += 500;
                          }
                          
                          final int targetMl = calculatedMl.round();

                          setState(() {
                            _goalMl = targetMl.toDouble();
                          });

                          await ServiceLocator.profile.updateUserProfile(_userId, {
                            'goalMl': targetMl,
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Su hedefi güncellendi.')),
                            );
                          }
                        },
                        child: Text('Hesapla ve Kaydet', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _WaterEntry {
  final String time;
  final int ml;
  final IconData icon;
  _WaterEntry({required this.time, required this.ml, required this.icon});
}
