import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({super.key});

  @override
  State<CalorieCalculatorScreen> createState() => _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  // â€”â€”â€” Hedefler â€”â€”â€”
  int _kaloriBudget = 2200;
  String get _userId => ServiceLocator.auth.currentUser?.uid ?? 'unknown';

  int _goalProtein = 140;
  int _goalCarb = 275;
  int _goalFat = 73;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ServiceLocator.profile.getUserProfile(_userId);
      if (profile != null && mounted) {
        setState(() {
          _kaloriBudget = profile['kaloriBudget'] ?? 2200;
          _goalProtein = profile['goalProtein'] ?? 140;
          _goalCarb = profile['goalCarb'] ?? 275;
          _goalFat = profile['goalFat'] ?? 73;
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
          'Kalori & Makro',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calculate_outlined, color: AppColors.primary),
            onPressed: () => _showCalculatorDialog(),
          ),
        ],
      ),
      body: _isLoadingProfile
        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ServiceLocator.calorie.getDailyMacros(_userId, DateTime.now()),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final data = snapshot.data?.data() ?? {};
          final kaloriUsed = data['usedCalories'] as int? ?? 0;
          
          final mealsData = data['meals'] as List<dynamic>? ?? [];
          final List<_MealEntry> meals = mealsData.map((m) {
            final mealMap = m as Map<String, dynamic>;
            return _MealEntry(
              name: mealMap['name'] as String? ?? 'Öğün',
              icon: IconData(mealMap['iconCode'] as int? ?? Icons.restaurant.codePoint, fontFamily: 'MaterialIcons'),
              calories: mealMap['calories'] as int? ?? 0,
              items: mealMap['items'] as String? ?? '',
            );
          }).toList();

          // Günlük toplam makroları hesapla
          int currentProtein = 0;
          int currentCarb = 0;
          int currentFat = 0;
          for (var m in mealsData) {
            currentProtein += (m['protein'] as int?) ?? 0;
            currentCarb += (m['carb'] as int?) ?? 0;
            currentFat += (m['fat'] as int?) ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalorieSummaryCard(kaloriUsed),
                const SizedBox(height: 24),
                _buildMacroBreakdown(currentProtein, currentCarb, currentFat),
                const SizedBox(height: 28),
                _buildMealLog(meals),
                const SizedBox(height: 24),
                _buildAddMealButton(),
              ],
            ),
          );
        }
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Kalori Özet Kartı â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCalorieSummaryCard(int kaloriUsed) {
    final remaining = (_kaloriBudget - kaloriUsed).clamp(0, _kaloriBudget);
    final progress = (kaloriUsed / _kaloriBudget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Dairesel gösterge
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                SizedBox(
                  width: 170,
                  height: 170,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'kcal kalan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Alt istatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                  'Hedef', '$_kaloriBudget', 'kcal', AppColors.primary),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              _buildStatItem(
                  'Tüketim', '$kaloriUsed', 'kcal', AppColors.accent),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              _buildStatItem(
                  'Kalan', '$remaining', 'kcal', const Color(0xFF0EA5E9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Makro Dağılımı â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMacroBreakdown(int currentProtein, int currentCarb, int currentFat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Makro Dağılımı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildMacroBar(_MacroGoal('Protein', _goalProtein, currentProtein, const Color(0xFFEF4444))),
        const SizedBox(height: 14),
        _buildMacroBar(_MacroGoal('Karbonhidrat', _goalCarb, currentCarb, const Color(0xFFF59E0B))),
        const SizedBox(height: 14),
        _buildMacroBar(_MacroGoal('Yağ', _goalFat, currentFat, const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildMacroBar(_MacroGoal macro) {
    final progress = (macro.current / macro.goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: macro.color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: macro.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    macro.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${macro.current}g / ${macro.goal}g',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: macro.color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(macro.color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Yemek Kaydı â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMealLog(List<_MealEntry> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bugünkü Öğünler',
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${meals.length} öğün',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(meals.length, (i) {
          final meal = meals[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(meal.icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meal.items,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${meal.calories} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Yemek Ekle Butonu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAddMealButton() {
    return GestureDetector(
      onTap: () => _showAddMealDialog(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'Öğün Ekle',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showAddMealDialog() {
    final nameCtrl = TextEditingController();
    final calsCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Öğün Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Öğün Adı (örn: Kahvaltı)')),
            TextField(controller: itemsCtrl, decoration: const InputDecoration(labelText: 'İçerik (örn: 2 Yumurta, Peynir)')),
            TextField(controller: calsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Toplam Kalori (kcal)')),
            Row(
              children: [
                Expanded(child: TextField(controller: proteinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Karb (g)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yağ (g)'))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final mealData = {
                    'name': nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Yeni Öğün',
                    'items': itemsCtrl.text,
                    'calories': int.tryParse(calsCtrl.text) ?? 500,
                    'protein': int.tryParse(proteinCtrl.text) ?? 0,
                    'carb': int.tryParse(carbCtrl.text) ?? 0,
                    'fat': int.tryParse(fatCtrl.text) ?? 0,
                    'iconCode': Icons.restaurant_menu.codePoint,
                  };
                  await ServiceLocator.calorie.logMeal(_userId, DateTime.now(), mealData);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text('Kaydet', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  void _showCalculatorDialog() {
    int age = 25;
    double weight = 70.0;
    double height = 175.0;
    String gender = 'Erkek'; // Erkek, Kadın
    double activityLevel = 1.55; // Default Orta Hareketli

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
                    const Text('Makro Hesaplayıcı', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Bilgilerinizi girerek günlük ihtiyacınızı hesaplayın.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          initialValue: age.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Yaş'),
                          onChanged: (val) => age = int.tryParse(val) ?? 25,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: DropdownButtonFormField<String>(
                          initialValue: gender,
                          decoration: const InputDecoration(labelText: 'Cinsiyet'),
                          items: ['Erkek', 'Kadın'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) => setModalState(() => gender = val ?? 'Erkek'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          initialValue: weight.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                          onChanged: (val) => weight = double.tryParse(val) ?? 70.0,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          initialValue: height.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Boy (cm)'),
                          onChanged: (val) => height = double.tryParse(val) ?? 175.0,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<double>(
                      initialValue: activityLevel,
                      decoration: const InputDecoration(labelText: 'Hareket'),
                      items: const [
                        DropdownMenuItem(value: 1.2, child: Text('Hareketsiz')),
                        DropdownMenuItem(value: 1.375, child: Text('Hafif')),
                        DropdownMenuItem(value: 1.55, child: Text('Orta')),
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
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          // BMR Hesaplama (Mifflin-St Jeor)
                          double bmr = (10 * weight) + (6.25 * height) - (5 * age);
                          bmr += (gender == 'Erkek') ? 5 : -161;
                          
                          final double tdee = bmr * activityLevel;
                          final int targetCal = tdee.round();
                          
                          // Makro dağılımı (30%P / 40%C / 30%Y)
                          final int targetProtein = ((targetCal * 0.30) / 4).round();
                          final int targetCarb = ((targetCal * 0.40) / 4).round();
                          final int targetFat = ((targetCal * 0.30) / 9).round();

                          setState(() {
                            _kaloriBudget = targetCal;
                            _goalProtein = targetProtein;
                            _goalCarb = targetCarb;
                            _goalFat = targetFat;
                          });

                          await ServiceLocator.profile.updateUserProfile(_userId, {
                            'kaloriBudget': targetCal,
                            'goalProtein': targetProtein,
                            'goalCarb': targetCarb,
                            'goalFat': targetFat,
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Makro hedefleri güncellendi.')),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Modeller â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MacroGoal {
  final String name;
  final int goal;
  final int current;
  final Color color;
  _MacroGoal(this.name, this.goal, this.current, this.color);
}

class _MealEntry {
  final String name;
  final IconData icon;
  final int calories;
  final String items;
  _MealEntry(
      {required this.name,
      required this.icon,
      required this.calories,
      required this.items});
}
