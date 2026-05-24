import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import 'allergy_edit_bottom_sheet.dart';

class KitchenPreferencesScreen extends StatefulWidget {
  const KitchenPreferencesScreen({super.key});

  @override
  State<KitchenPreferencesScreen> createState() =>
      _KitchenPreferencesScreenState();
}

class _KitchenPreferencesScreenState extends State<KitchenPreferencesScreen> {
  // ── Beslenme Düzeni State ──
  final List<String> _allDiets = [
    'Vegan',
    'Gluten-Free',
    'Keto',
    'Paleo',
    'Vejetaryen',
    'Pesketaryen',
    'Düşük Karbonhidrat',
  ];
  Set<String> _selectedDiets = {'Vegan', 'Gluten-Free'};

  // ── İstenmeyen Malzemeler State ──
  List<String> _unwantedIngredients = [
    'Patlıcan',
    'Süt Ürünleri',
    'Yer Fıstığı',
  ];
  List<String> _allergies = [];
  final TextEditingController _ingredientController = TextEditingController();

  // ── Pişirme Seviyesi State ──
  final List<String> _cookingLevels = ['Başlangıç', 'Orta Seviye', 'İleri'];
  String _selectedLevel = 'Orta Seviye';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = ServiceLocator.auth.currentUser?.uid;
    if (userId != null) {
      final doc = await ServiceLocator.profile.getUserProfile(userId);
      if (doc != null && doc.containsKey('kitchenPreferences')) {
        final prefs = Map<String, dynamic>.from(doc['kitchenPreferences'] as Map);
        setState(() {
          if (prefs['diets'] != null) {
            _selectedDiets = Set<String>.from((prefs['diets'] as List).map((e) => e.toString()));
          } else {
            _selectedDiets = {};
          }
          if (prefs['unwantedIngredients'] != null) {
            _unwantedIngredients = List<String>.from((prefs['unwantedIngredients'] as List).map((e) => e.toString()));
          } else {
            _unwantedIngredients = [];
          }
          if (prefs['allergies'] != null) {
            _allergies = List<String>.from((prefs['allergies'] as List).map((e) => e.toString()));
          } else {
            _allergies = [];
          }
          _selectedLevel = prefs['cookingLevel']?.toString() ?? 'Orta Seviye';
        });
      } else {
        setState(() {
          _selectedDiets = {};
          _unwantedIngredients = [];
          _allergies = [];
          _selectedLevel = 'Orta Seviye';
        });
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
     final userId = ServiceLocator.auth.currentUser?.uid;
     if (userId == null) return;
     
     await ServiceLocator.profile.updateUserProfile(userId, {
        'kitchenPreferences': {
           'diets': _selectedDiets.toList(),
           'unwantedIngredients': _unwantedIngredients,
           'allergies': _allergies,
           'cookingLevel': _selectedLevel,
        }
     });
     
     if (mounted) {
       final isTr = Localizations.localeOf(context).languageCode == 'tr';
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(isTr ? 'Tercihler kaydedildi!' : 'Preferences saved!'),
           backgroundColor: AppColors.primary,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
         ),
       );
     }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty && !_unwantedIngredients.contains(text)) {
      setState(() {
        _unwantedIngredients.add(text);
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(String item) {
    setState(() => _unwantedIngredients.remove(item));
  }

  void _editAllergies() async {
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => AllergyEditBottomSheet(
        currentAllergies: _allergies,
      ),
    );
    if (updated != null) {
      setState(() {
        _allergies = updated;
      });
    }
  }

  String _translateDiet(String diet, bool isTr) {
    if (isTr) {
      switch (diet) {
        case 'Vegan': return 'Vegan';
        case 'Gluten-Free': return 'Gluten-Free';
        case 'Keto': return 'Keto';
        case 'Paleo': return 'Paleo';
        case 'Vegetarian':
        case 'Vejetaryen': return 'Vejetaryen';
        case 'Pescatarian':
        case 'Pesketaryen': return 'Pesketaryen';
        case 'Low Carb':
        case 'Düşük Karbonhidrat': return 'Düşük Karbonhidrat';
        default: return diet;
      }
    } else {
      switch (diet) {
        case 'Vegan': return 'Vegan';
        case 'Gluten-Free': return 'Gluten-Free';
        case 'Keto': return 'Keto';
        case 'Paleo': return 'Paleo';
        case 'Vejetaryen':
        case 'Vegetarian': return 'Vegetarian';
        case 'Pesketaryen':
        case 'Pescatarian': return 'Pescatarian';
        case 'Düşük Karbonhidrat':
        case 'Low Carb': return 'Low Carb';
        default: return diet;
      }
    }
  }

  String _translateCookingLevel(String level, bool isTr) {
    if (isTr) {
      switch (level) {
        case 'Beginner':
        case 'Başlangıç': return 'Başlangıç';
        case 'Intermediate':
        case 'Orta Seviye': return 'Orta Seviye';
        case 'Advanced':
        case 'İleri': return 'İleri';
        default: return level;
      }
    } else {
      switch (level) {
        case 'Başlangıç':
        case 'Beginner': return 'Beginner';
        case 'Orta Seviye':
        case 'Intermediate': return 'Intermediate';
        case 'İleri':
        case 'Advanced': return 'Advanced';
        default: return level;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Stack(
            children: [
          // ── Scrollable Content ──
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── AppBar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'AuraCook',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isTr ? 'Mutfak Tercihleri' : 'Kitchen Preferences',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hero Section ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTr ? 'Mutfak Tercihleri' : 'Kitchen Preferences',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isTr 
                            ? 'Yemek deneyiminizi kişiselleştirin. Seçtiğiniz tercihler doğrultusunda tarifleriniz ve önerileriniz otomatik olarak güncellenecektir.'
                            : 'Personalize your kitchen experience. Your recipes and recommendations will be automatically updated based on your chosen preferences.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Beslenme Düzeni ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(isTr ? 'BESLENME DÜZENİ' : 'DIET PREFERENCES'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _allDiets.map((diet) {
                            final isSelected = _selectedDiets.contains(diet);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedDiets.remove(diet);
                                  } else {
                                    _selectedDiets.add(diet);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      _translateDiet(diet, isTr),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── İstenmeyen Malzemeler ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(isTr ? 'İSTENMEYEN MALZEMELER' : 'UNWANTED INGREDIENTS'),
                        const SizedBox(height: 16),

                        // Input area
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTr 
                                  ? 'Tariflerinizde asla görmek istemediğiniz malzemeleri ekleyin.'
                                  : 'Add ingredients that you never want to see in your recipes.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _ingredientController,
                                      onSubmitted: (_) => _addIngredient(),
                                      decoration: InputDecoration(
                                        hintText: isTr
                                            ? 'Malzeme adı girin (örn: Kişniş)'
                                            : 'Enter ingredient name (e.g. Cilantro)',
                                        hintStyle: TextStyle(
                                          color: AppColors.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          fontSize: 14,
                                        ),
                                        filled: true,
                                        fillColor:
                                            AppColors.surfaceContainerHigh,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _addIngredient,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: AppColors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Tags
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _unwantedIngredients.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeIngredient(item),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Alerjiler & Pişirme Seviyesi Cards ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                    child: Column(
                      children: [
                        // Alerjiler Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              // Background icon
                              Positioned(
                                bottom: -20,
                                right: -20,
                                child: Icon(
                                  Icons.warning_rounded,
                                  size: 100,
                                  color: AppColors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTr ? 'Alerjiler' : 'Allergies',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isTr 
                                      ? 'Kritik sağlık uyarıları için profilinizi güncel tutun.'
                                      : 'Keep your profile updated for critical health warnings.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          AppColors.white.withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: _editAllergies,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        isTr ? 'Alerji Listesini Düzenle' : 'Edit Allergy List',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Pişirme Seviyesi Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTr ? 'Pişirme Seviyesi' : 'Cooking Level',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isTr 
                                  ? 'Size en uygun zorluk derecesindeki tarifleri getirelim.'
                                  : 'Let us recommend recipes at the most suitable difficulty level for you.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                children: _cookingLevels.map((level) {
                                  final isSel = _selectedLevel == level;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(
                                          () => _selectedLevel = level);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? AppColors.primaryContainer
                                            : AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        _translateCookingLevel(level, isTr),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSel
                                              ? AppColors.onPrimaryContainer
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding for floating button
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),

          // ── Floating Save Button ──
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: GestureDetector(
              onTap: _savePreferences,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: AppColors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isTr ? 'TERCİHLERİ KAYDET' : 'SAVE PREFERENCES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            height: 1,
            color: AppColors.black.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
