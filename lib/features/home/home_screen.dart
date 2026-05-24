import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/components/aura_app_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../navigation/app_drawer.dart';
import '../recipes/food_search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _ingredientController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Dinamik malzeme listesi (state)
  final List<String> _ingredients = [];

  // Autocomplete state
  List<String> _autocompleteSuggestions = [];
  bool _isAutocompleteLoading = false;
  bool _showAutocomplete = false;
  Timer? _debounceTimer;

  // 70 popüler malzeme — sabit, hiçbir şekilde değişmez
  static const List<Map<String, dynamic>> _quickAddItems = [
    {'name': 'Yumurta', 'emoji': '🥚'},
    {'name': 'Zeytinyağı', 'emoji': '🫒'},
    {'name': 'Tuz', 'emoji': '🧂'},
    {'name': 'Tereyağı', 'emoji': '🧈'},
    {'name': 'Sarımsak', 'emoji': '🧄'},
    {'name': 'Soğan', 'emoji': '🧅'},
    {'name': 'Domates', 'emoji': '🍅'},
    {'name': 'Patates', 'emoji': '🥔'},
    {'name': 'Havuç', 'emoji': '🥕'},
    {'name': 'Biber', 'emoji': '🌶️'},
    {'name': 'Limon', 'emoji': '🍋'},
    {'name': 'Maydanoz', 'emoji': '🌿'},
    {'name': 'Nane', 'emoji': '🌱'},
    {'name': 'Un', 'emoji': '🌾'},
    {'name': 'Şeker', 'emoji': '🍚'},
    {'name': 'Süt', 'emoji': '🥛'},
    {'name': 'Yoğurt', 'emoji': '🥣'},
    {'name': 'Peynir', 'emoji': '🧀'},
    {'name': 'Tavuk', 'emoji': '🍗'},
    {'name': 'Kıyma', 'emoji': '🥩'},
    {'name': 'Balık', 'emoji': '🐟'},
    {'name': 'Pirinç', 'emoji': '🍚'},
    {'name': 'Makarna', 'emoji': '🍝'},
    {'name': 'Ekmek', 'emoji': '🍞'},
    {'name': 'Bezelye', 'emoji': '🟢'},
    {'name': 'Ispanak', 'emoji': '🥬'},
    {'name': 'Kabak', 'emoji': '🥒'},
    {'name': 'Patlıcan', 'emoji': '🍆'},
    {'name': 'Biber (Yeşil)', 'emoji': '🫑'},
    {'name': 'Lahana', 'emoji': '🥦'},
    {'name': 'Brokoli', 'emoji': '🥦'},
    {'name': 'Mantar', 'emoji': '🍄'},
    {'name': 'Mısır', 'emoji': '🌽'},
    {'name': 'Fasulye', 'emoji': '🫘'},
    {'name': 'Mercimek', 'emoji': '🟤'},
    {'name': 'Nohut', 'emoji': '🟡'},
    {'name': 'Elma', 'emoji': '🍎'},
    {'name': 'Muz', 'emoji': '🍌'},
    {'name': 'Portakal', 'emoji': '🍊'},
    {'name': 'Çilek', 'emoji': '🍓'},
    {'name': 'Üzüm', 'emoji': '🍇'},
    {'name': 'Karpuz', 'emoji': '🍉'},
    {'name': 'Ceviz', 'emoji': '🫘'},
    {'name': 'Badem', 'emoji': '🥜'},
    {'name': 'Fıstık', 'emoji': '🥜'},
    {'name': 'Krema', 'emoji': '🥛'},
    {'name': 'Lor Peyniri', 'emoji': '🧀'},
    {'name': 'Mozzarella', 'emoji': '🧀'},
    {'name': 'Salam', 'emoji': '🍖'},
    {'name': 'Sucuk', 'emoji': '🌭'},
    {'name': 'Hindi', 'emoji': '🍗'},
    {'name': 'Karides', 'emoji': '🦐'},
    {'name': 'Ton Balığı', 'emoji': '🐟'},
    {'name': 'Soya Sosu', 'emoji': '🍶'},
    {'name': 'Sirke', 'emoji': '🫙'},
    {'name': 'Nar Ekşisi', 'emoji': '🫙'},
    {'name': 'Biber Salçası', 'emoji': '🥫'},
    {'name': 'Domates Salçası', 'emoji': '🥫'},
    {'name': 'Hardal', 'emoji': '🟡'},
    {'name': 'Mayonez', 'emoji': '🥄'},
    {'name': 'Ketçap', 'emoji': '🥫'},
    {'name': 'Kırmızı Pul Biber', 'emoji': '🌶️'},
    {'name': 'Karabiber', 'emoji': '⚫'},
    {'name': 'Kimyon', 'emoji': '🌿'},
    {'name': 'Pul Biber', 'emoji': '🌶️'},
    {'name': 'Tarçın', 'emoji': '🟤'},
    {'name': 'Zencefil', 'emoji': '🫚'},
    {'name': 'Zerdeçal', 'emoji': '🟡'},
    {'name': 'Kekik', 'emoji': '🌿'},
    {'name': 'Fesleğen', 'emoji': '🌿'},
    {'name': 'Biberiye', 'emoji': '🌿'},
    {'name': 'Defne Yaprağı', 'emoji': '🍃'},
    {'name': 'Soda', 'emoji': '💧'},
  ];

  @override
  void initState() {
    super.initState();
    _ingredientController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _ingredientController.text.trim();
    _debounceTimer?.cancel();
    if (text.length < 2) {
      setState(() {
        _autocompleteSuggestions = [];
        _showAutocomplete = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchAutocomplete(text);
    });
  }

  // Groq'tan gelen çevirileri de tutacak map: Orijinal -> Çeviri
  Map<String, String> _autocompleteTranslations = {};

  Future<void> _fetchAutocomplete(String query) async {
    setState(() => _isAutocompleteLoading = true);
    try {
      final response = await ServiceLocator.fatSecret.autocompleteFoods(
        expression: query,
        maxResults: 8,
      );
      final suggestions = response['suggestions'];
      if (suggestions != null) {
        final suggestionList = suggestions['suggestion'];
        if (suggestionList != null) {
          final list = suggestionList is List ? suggestionList : [suggestionList];
          final originalSuggestions = list
              .where((s) => s != null)
              .map((s) => s.toString())
              .toList();
          
          if (originalSuggestions.isNotEmpty) {
            final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
            final translatedSuggestions = await ServiceLocator.groqTranslation.translateTexts(
              originalSuggestions,
              isTurkish: isTr,
            );
            
            final Map<String, String> translationsMap = {};
            for (int i = 0; i < originalSuggestions.length; i++) {
              translationsMap[originalSuggestions[i]] = translatedSuggestions.length > i 
                  ? translatedSuggestions[i] 
                  : originalSuggestions[i];
            }

            setState(() {
              _autocompleteSuggestions = originalSuggestions;
              _autocompleteTranslations = translationsMap;
              _showAutocomplete = _autocompleteSuggestions.isNotEmpty;
            });
          } else {
            _clearAutocomplete();
          }
        } else {
          _clearAutocomplete();
        }
      } else {
        _clearAutocomplete();
      }
    } catch (_) {
      setState(() => _showAutocomplete = false);
    } finally {
      setState(() => _isAutocompleteLoading = false);
    }
  }

  void _clearAutocomplete() {
    setState(() {
        _autocompleteSuggestions = [];
        _autocompleteTranslations = {};
        _showAutocomplete = false;
    });
  }

  void _selectAutocompleteSuggestion(String originalSuggestion) {
    final translated = _autocompleteTranslations[originalSuggestion] ?? originalSuggestion;
    if (!_ingredients.contains(translated)) {
      setState(() => _ingredients.add(translated));
    }
    _ingredientController.clear();
    _clearAutocomplete();
    _focusNode.requestFocus();
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
      });
      _ingredientController.clear();
      _clearAutocomplete();
    }
    _focusNode.requestFocus();
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _quickAdd(String name) {
    if (_ingredients.contains(name)) {
      // İkinci tıklamada kaldır (toggle)
      setState(() => _ingredients.remove(name));
    } else {
      setState(() => _ingredients.add(name));
    }
  }

  void _viewRecipes() {
    if (_ingredients.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodSearchResultsScreen(ingredients: List.from(_ingredients)),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _ingredientController.removeListener(_onSearchChanged);
    _ingredientController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Scrollable content
          GestureDetector(
            onTap: () {
              _focusNode.unfocus();
              setState(() => _showAutocomplete = false);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık bölümü
                  _buildTitleSection(),
                  const SizedBox(height: 32),

                  // Malzeme ekleme input (autocomplete ile)
                  _buildIngredientInputWithAutocomplete(),
                  const SizedBox(height: 40),

                  // Mevcut Stok bölümü
                  _buildStockSection(),
                  const SizedBox(height: 48),

                  // Hızlı Ekle bölümü
                  _buildQuickAddSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Sabit CTA butonu
          _buildCTAButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AuraAppBar(scaffoldKey: _scaffoldKey);
  }

  Widget _buildTitleSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Malzemelerim',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tarifleri keşfetmek için malzeme ekleyin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, duration: 600.ms, curve: Curves.easeOut);
  }

  // ───────────── Autocomplete'li Malzeme Girişi ─────────────
  Widget _buildIngredientInputWithAutocomplete() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _addIngredient(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Malzeme ekleyin (örn. Chicken, Tomato)',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    suffixIcon: _isAutocompleteLoading
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _addIngredient,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.onPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Autocomplete önerileri
        if (_showAutocomplete && _autocompleteSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'ÖNERİLER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Öneri listesi
                  ..._autocompleteSuggestions.map((suggestion) {
                    final translated = _autocompleteTranslations[suggestion] ?? suggestion;
                    final isAlreadyAdded = _ingredients.contains(translated);
                    return InkWell(
                      onTap: isAlreadyAdded
                          ? null
                          : () => _selectAutocompleteSuggestion(suggestion),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.outlineVariant.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                              size: 18,
                              color: isAlreadyAdded ? AppColors.primary : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translated,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isAlreadyAdded
                                          ? AppColors.primary
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                  if (translated != suggestion)
                                    Text(
                                      suggestion,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık satırı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEVCUT STOK',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_ingredients.length} Ürün',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Malzeme chip'leri
        _ingredients.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.kitchen_outlined,
                        size: 48,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz malzeme eklenmedi',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_ingredients.length, (index) {
                  return _buildIngredientChip(index);
                }),
              ),
      ],
    );
  }

  Widget _buildIngredientChip(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _ingredients[index],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.chipText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeIngredient(index),
            child: Icon(
              Icons.close,
              size: 16,
              color: AppColors.chipText.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'HIZLI EKLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${_quickAddItems.length} malzeme',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAddItems.map((item) {
            final name = item['name'] as String;
            final emoji = item['emoji'] as String? ?? '🍽️';
            final isAdded = _ingredients.contains(name);

            return GestureDetector(
              onTap: () => _quickAdd(name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAdded
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAdded
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAdded ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    if (isAdded) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check, size: 13, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCTAButton() {
    return Positioned(
      bottom: 16,
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: _ingredients.isNotEmpty ? _viewRecipes : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: _ingredients.isNotEmpty
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _ingredients.isNotEmpty
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tarifleri Gör',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.restaurant_menu,
                color: AppColors.onPrimary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
