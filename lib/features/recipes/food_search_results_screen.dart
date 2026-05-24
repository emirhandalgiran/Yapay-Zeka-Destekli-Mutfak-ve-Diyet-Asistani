import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/api/wikipedia_image_service.dart';
import '../../core/utils/portion_parser.dart';
import 'data/models/food_item.dart';
import 'data/models/food_category.dart';

class FoodSearchResultsScreen extends StatefulWidget {
  final List<String> ingredients;

  const FoodSearchResultsScreen({super.key, required this.ingredients});

  @override
  State<FoodSearchResultsScreen> createState() => _FoodSearchResultsScreenState();
}

class _FoodSearchResultsScreenState extends State<FoodSearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<FoodItem> _foods = [];
  List<FoodCategory> _categories = [];
  FoodCategory? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isTranslating = false; // Çeviri devam ediyor mu
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 0;
  int _totalResults = 0;
  String _currentQuery = '';
  String _englishQuery = '';
  String? _foodTypeFilter; // null, 'Brand', 'Generic'

  int _getFoodPriority(FoodItem food) {
    final name = food.foodName.toLowerCase();
    final nameTr = food.foodNameTr.toLowerCase();
    final desc = food.foodDescription.toLowerCase();
    final descTr = food.foodDescriptionTr.toLowerCase();

    // 1. Çorbalar (Soups) -> Priority 2 (after cooked meals, before others)
    final isSoup = name.contains('soup') || 
                   nameTr.contains('çorba') || 
                   nameTr.contains('corba') ||
                   desc.contains('soup') || 
                   descTr.contains('çorba') ||
                   descTr.contains('corba');
    if (isSoup) {
      return 2;
    }

    // 2. Yemekler (Cooked Meals / Main Dishes) -> Priority 1
    // Turkish cooked meals indicators
    final mealKeywordsTr = [
      'yemeği', 'yemekleri', 'kebap', 'döner', 'doner', 'kavurma', 'kızartma', 'kizartma',
      'ızgara', 'izgara', 'köfte', 'kofte', 'makarna', 'pilav', 'dolma', 'sarma',
      'güveç', 'guvec', 'tava', 'sote', 'haşlama', 'haslama', 'burger', 'pizza',
      'sandviç', 'sandvic', 'lahmacun', 'pide', 'mantı', 'manti', 'börek', 'borek',
      'çörek', 'corek', 'erişte', 'eriste', 'güveci', 'guveci', 'sufle', 'kumpir',
      'fırında', 'firinda', 'tavuklu', 'etli', 'kıymalı', 'kiymali', 'sebzeli',
      'nohutlu', 'fasulyeli', 'mercimekli', 'türlü', 'turlu', 'musakka', 'karnıyarık',
      'karniyarik', 'güveçte', 'guvecte', 'buğulama', 'bugulama', 'kavurması', 'kavurmasi',
      'kızartması', 'kizartmasi', 'ızgarası', 'izgarasi', 'köftesi', 'koftesi',
      'makarnası', 'makarnasi', 'pilavı', 'pilavi', 'salatası', 'salatasi'
    ];
    
    // English cooked meals indicators
    final mealKeywordsEn = [
      'meal', 'dish', 'pasta', 'spaghetti', 'pizza', 'burger', 'sandwich', 'stew', 
      'curry', 'meatball', 'kebab', 'casserole', 'roast', 'grilled', 'fried', 'saute', 
      'baked', 'taco', 'fajita', 'wrap', 'lasagna', 'risotto', 'stir fry', 'noodles',
      'baked', 'roasted'
    ];

    // Check if the name or description contains any meal keyword
    final hasMealKeyword = mealKeywordsTr.any((keyword) => nameTr.contains(keyword)) ||
                           mealKeywordsEn.any((keyword) => name.contains(keyword));

    // Also let's check subcategories or types. If it's Fast Food, etc.
    final subCats = food.subCategories.map((c) => c.toLowerCase()).toList();
    final subCatsTr = food.subCategoriesTr.map((c) => c.toLowerCase()).toList();
    
    final isFastFood = subCats.any((c) => c.contains('fast food') || c.contains('prepared')) || 
                       subCatsTr.any((c) => c.contains('fast food') || c.contains('hazır yemek') || c.contains('hazir yemek'));

    if (hasMealKeyword || isFastFood) {
      return 1;
    }

    // 3. Diğerleri (Others / Fruits / Raw Ingredients / Sweets / Beverages) -> Priority 3
    final rawKeywordsTr = [
      'elma', 'muz', 'portakal', 'çilek', 'cilek', 'üzüm', 'uzum', 'karpuz', 'kavun',
      'armut', 'şeftali', 'seftali', 'erik', 'meyve', 'meyvesi', 'çiğ', 'taze',
      'domates', 'patates', 'soğan', 'sogan', 'sarımsak', 'sarimsak', 'biber',
      'ıspanak', 'ispanak', 'kabak', 'patlıcan', 'patlican', 'lahana', 'brokoli',
      'marul', 'maydanoz', 'dereotu', 'nane', 'kekik', 'tuz', 'şeker', 'seker',
      'yağ', 'yag', 'zeytinyağı', 'zeytinyagi', 'tereyağı', 'tereyagi', 'sıvıyağ',
      'siviyağ', 'sivi yag', 'süt', 'sut', 'yoğurt', 'yogurt', 'peynir', 'lor',
      'yumurta', 'un', 'nişasta', 'nisasta', 'maya', 'kabartma tozu', 'su', 'çay',
      'cay', 'kahve', 'meyve suyu', 'gazoz', 'soda', 'kola', 'içecek', 'icecek',
      'çikolata', 'cikolata', 'şekerleme', 'sekerleme', 'bisküvi', 'biskuvi',
      'gofret', 'cips', 'jelibon', 'sos', 'sosu', 'salça', 'salca', 'limon', 'sirke'
    ];

    final rawKeywordsEn = [
      'apple', 'banana', 'orange', 'strawberry', 'grape', 'watermelon', 'melon', 'peach',
      'plum', 'fruit', 'raw', 'fresh', 'tomato', 'potato', 'onion', 'garlic', 'pepper',
      'spinach', 'zucchini', 'eggplant', 'cabbage', 'broccoli', 'lettuce', 'parsley',
      'dill', 'mint', 'thyme', 'salt', 'sugar', 'oil', 'olive oil', 'butter', 'milk',
      'yogurt', 'cheese', 'egg', 'flour', 'starch', 'yeast', 'baking powder', 'water',
      'tea', 'coffee', 'juice', 'soda', 'coke', 'beverage', 'chocolate', 'candy',
      'biscuit', 'wafer', 'chips', 'jelly', 'sauce', 'paste', 'lemon', 'vinegar'
    ];

    final isOther = rawKeywordsTr.any((keyword) => nameTr.contains(keyword)) ||
                    rawKeywordsEn.any((keyword) => name.contains(keyword));

    if (isOther) {
      return 3;
    }

    final isFruitOrVeg = subCats.any((c) => c.contains('fruit') || c.contains('vegetable') || c.contains('berry') || c.contains('herb') || c.contains('spice')) ||
                         subCatsTr.any((c) => c.contains('meyve') || c.contains('sebze') || c.contains('baharat'));
    if (isFruitOrVeg) {
      return 3;
    }

    // Default fallback:
    // If it's a food item with a multi-word name (like "Sebzeli Pilav", "Tavuk Sote"), treat as meal (1).
    // If it's a single word name (like "Chicken", "Rice", "Meat"), it's likely a raw ingredient/other (3).
    final words = nameTr.split(' ').where((w) => w.isNotEmpty).length;
    if (words > 1) {
      return 1;
    }

    return 3;
  }

  List<FoodItem> get _filteredFoods {
    List<FoodItem> resultList;
    if (_selectedCategory == null) {
      resultList = List.from(_foods);
    } else {
      final categoryName = _selectedCategory!.categoryName.toLowerCase().trim();
      final categoryNameTr = _selectedCategory!.categoryNameTr.toLowerCase().trim();

      resultList = _foods.where((food) {
        final name = food.foodName.toLowerCase();
        final nameTr = food.foodNameTr.toLowerCase();

        // Broad matching for main categories
        
        // 1. Beverages / İçecekler
        if (categoryName.contains('beverage') || categoryNameTr.contains('içecek')) {
          if (name.contains('drink') || name.contains('juice') || name.contains('tea') || 
              name.contains('coffee') || name.contains('soda') || name.contains('water') || name.contains('milk') ||
              nameTr.contains('içecek') || nameTr.contains('meyve suyu') || nameTr.contains('çay') || 
              nameTr.contains('kahve') || nameTr.contains('gazoz') || nameTr.contains('su') || nameTr.contains('süt')) {
            return true;
          }
        }
        
        // 2. Fast Foods / Hazır Yemek
        if (categoryName.contains('fast food') || categoryNameTr.contains('fast food') || categoryNameTr.contains('hazır yemek') || categoryNameTr.contains('hazir yemek')) {
          if (name.contains('burger') || name.contains('pizza') || name.contains('fries') || 
              name.contains('sandwich') || name.contains('taco') || name.contains('hot dog') || name.contains('nugget') ||
              nameTr.contains('burger') || nameTr.contains('pizza') || nameTr.contains('patates kızartması') || 
              nameTr.contains('sandviç') || nameTr.contains('lahmacun') || nameTr.contains('döner') || nameTr.contains('kebap')) {
            return true;
          }
        }

        // 3. Dairy and Egg / Süt Ürünleri ve Yumurta
        if (categoryName.contains('dairy') || categoryName.contains('egg') || categoryNameTr.contains('süt') || categoryNameTr.contains('yumurta')) {
          if (name.contains('milk') || name.contains('cheese') || name.contains('egg') || 
              name.contains('yogurt') || name.contains('butter') || name.contains('cream') ||
              nameTr.contains('süt') || nameTr.contains('peynir') || nameTr.contains('yumurta') || 
              nameTr.contains('yoğurt') || nameTr.contains('tereyağ') || nameTr.contains('kaymak') || nameTr.contains('krema')) {
            return true;
          }
        }

        // 4. Meat, Poultry, Fish / Et, Tavuk, Balık
        if (categoryName.contains('meat') || categoryName.contains('poultry') || categoryName.contains('fish') || 
            categoryNameTr.contains('et') || categoryNameTr.contains('tavuk') || categoryNameTr.contains('balık') || categoryNameTr.contains('balik')) {
          if (name.contains('meat') || name.contains('poultry') || name.contains('fish') || name.contains('chicken') || 
              name.contains('beef') || name.contains('pork') || name.contains('turkey') || name.contains('salmon') || name.contains('tuna') ||
              nameTr.contains('et') || nameTr.contains('tavuk') || nameTr.contains('balık') || nameTr.contains('kıyma') || 
              nameTr.contains('bonfile') || nameTr.contains('hindi') || nameTr.contains('somon') || nameTr.contains('ton balığı')) {
            return true;
          }
        }

        // 5. Fruits / Meyveler
        if (categoryName.contains('fruit') || categoryNameTr.contains('meyve')) {
          if (name.contains('fruit') || name.contains('apple') || name.contains('banana') || name.contains('orange') || name.contains('strawberry') || name.contains('grape') ||
              nameTr.contains('meyve') || nameTr.contains('elma') || nameTr.contains('muz') || nameTr.contains('portakal') || nameTr.contains('çilek') || nameTr.contains('üzüm')) {
            return true;
          }
        }

        // 6. Vegetables / Sebzeler
        if (categoryName.contains('vegetable') || categoryNameTr.contains('sebze')) {
          if (name.contains('vegetable') || name.contains('tomato') || name.contains('potato') || name.contains('onion') || name.contains('garlic') || name.contains('pepper') || name.contains('spinach') ||
              nameTr.contains('sebze') || nameTr.contains('domates') || nameTr.contains('patates') || nameTr.contains('soğan') || nameTr.contains('sarımsak') || nameTr.contains('biber') || nameTr.contains('ıspanak')) {
            return true;
          }
        }

        // 7. Sweets / Tatlılar
        if (categoryName.contains('sweet') || categoryNameTr.contains('tatlı') || categoryNameTr.contains('tatli')) {
          if (name.contains('sweet') || name.contains('cake') || name.contains('cookie') || name.contains('chocolate') || name.contains('dessert') || name.contains('sugar') || name.contains('candy') ||
              nameTr.contains('tatlı') || nameTr.contains('pasta') || nameTr.contains('kurabiye') || nameTr.contains('çikolata') || nameTr.contains('şeker') || nameTr.contains('dondurma')) {
            return true;
          }
        }

        // 8. Baked Products / Unlu Mamüller
        if (categoryName.contains('bake') || categoryName.contains('bread') || categoryNameTr.contains('unlu') || categoryNameTr.contains('ekmek') || categoryNameTr.contains('fırın') || categoryNameTr.contains('firin')) {
          if (name.contains('bread') || name.contains('bake') || name.contains('flour') || name.contains('dough') || name.contains('pastry') || name.contains('croissant') ||
              nameTr.contains('ekmek') || nameTr.contains('unlu mam') || nameTr.contains('un') || nameTr.contains('hamur') || nameTr.contains('börek') || nameTr.contains('borek') || nameTr.contains('poğaça')) {
            return true;
          }
        }

        // General fallback using sub-categories
        final matchesSub = food.subCategories.any((sub) {
          final s = sub.toLowerCase();
          return s.contains(categoryName) || categoryName.contains(s);
        });
        final matchesSubTr = food.subCategoriesTr.any((subTr) {
          final s = subTr.toLowerCase();
          return s.contains(categoryNameTr) || categoryNameTr.contains(s);
        });

        return matchesSub || matchesSubTr;
      }).toList();
    }

    // Sort food items: Meals first, then soups, then others (fruits, basic ingredients, etc.)
    resultList.sort((a, b) {
      final priorityA = _getFoodPriority(a);
      final priorityB = _getFoodPriority(b);
      return priorityA.compareTo(priorityB);
    });

    return resultList;
  }

  @override
  void initState() {
    super.initState();
    // Filtrele: Arama kalitesini artırmak için yağ, su, tuz gibi yardımcı malzemeleri arama sorgusundan çıkaralım
    final substantialIngredients = widget.ingredients.where((ing) {
      final lower = ing.toLowerCase().trim();
      return !const [
        'zeytinyağı', 'zeytinyağ', 'sıvı yağ', 'sıvıyağ', 'tereyağı', 'margarin', 'yağ',
        'tuz', 'karabiber', 'pul biber', 'pulbiber', 'kekik', 'nane', 'baharat',
        'su', 'şeker',
        'olive oil', 'butter', 'oil', 'vegetable oil', 'salt', 'pepper', 'water', 'sugar'
      ].contains(lower);
    }).toList();

    // Eğer tüm malzemeler filtreye takıldıysa (örn. sadece yağ ve tuz seçtiyse), orijinal listeyi kullan
    _currentQuery = substantialIngredients.isNotEmpty 
        ? substantialIngredients.join(' ') 
        : widget.ingredients.join(' ');
        
    _searchController.text = _currentQuery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCategories();
        _searchFoods();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _foods.length < _totalResults) {
        _loadMoreFoods();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ServiceLocator.fatSecret.getFoodCategories();
      final categoriesData = response['food_categories']?['food_category'];
      if (categoriesData != null) {
        final list = categoriesData is List ? categoriesData : [categoriesData];
        final parsedCategories = list
            .where((c) => c != null)
            .map((c) => FoodCategory.fromJson(c as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _categories = parsedCategories;
          });
        }

        // Asenkron olarak kategorileri çevir (UI kitlenmesin diye arkada)
        final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
        await ServiceLocator.groqTranslation.translateCategories(parsedCategories, isTurkish: isTr);
        if (mounted) {
          setState(() {
            _categories = parsedCategories; // Translated categories will update the UI
          });
        }
      }
    } catch (_) {
      // Kategori yüklenemezse sessizce devam et
    }
  }

  Future<void> _searchFoods({bool reset = true}) async {
    if (_currentQuery.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      if (reset) {
        _currentPage = 0;
        _foods = [];
      }
    });

    try {
      final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
      if (reset) {
        if (isTr) {
          try {
            _englishQuery = await ServiceLocator.groqTranslation.translateToEnglish(_currentQuery);
          } catch (e) {
            _englishQuery = _currentQuery;
          }
        } else {
          _englishQuery = '';
        }
      }
      
      final response = await ServiceLocator.fatSecret.searchFoods(
        query: _englishQuery.isNotEmpty ? _englishQuery : _currentQuery,
        pageNumber: _currentPage,
        maxResults: 20,
        foodType: _foodTypeFilter,
      );

      final foodsSearch = response['foods_search'];
      if (foodsSearch != null) {
        _totalResults = int.tryParse(foodsSearch['total_results']?.toString() ?? '0') ?? 0;
        final results = foodsSearch['results']?['food'];
        if (results != null) {
          final list = results is List ? results : [results];
          final items = list
              .where((f) => f != null)
              .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
              .toList();

          // Arka planda değil, bekleyerek çevir (kullanıcıya İngilizce liste göstermemek için)
          try {
            await _translateAndRefresh(items);
          } catch (e) {
            // Ignore translation errors and just show the original language items
          }

          setState(() {
            if (reset) {
              _foods = items;
            } else {
              _foods.addAll(items);
            }
          });
          
          final userId = ServiceLocator.auth.currentUser?.uid;
          if (userId != null) {
            ServiceLocator.gamification.incrementAction(userId, 'aiUsesCount');
          }
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreFoods() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final response = await ServiceLocator.fatSecret.searchFoods(
        query: _englishQuery.isNotEmpty ? _englishQuery : _currentQuery,
        pageNumber: _currentPage,
        maxResults: 20,
        foodType: _foodTypeFilter,
      );

      final foodsSearch = response['foods_search'];
      if (foodsSearch != null) {
        final results = foodsSearch['results']?['food'];
        if (results != null) {
          final list = results is List ? results : [results];
          final items = list
              .where((f) => f != null)
              .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
              .toList();
              
          // İngilizce göstermeden önce çeviriyi bekle
          try {
            await _translateAndRefresh(items);
          } catch (e) {
            // Ignore
          }
          
          setState(() => _foods.addAll(items));
        }
      }
    } catch (_) {}
    setState(() => _isLoadingMore = false);
  }

  Future<void> _searchByBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _foods = [];
    });

    try {
      final response = await ServiceLocator.fatSecret.findFoodByBarcode(barcode: barcode);
      final foodId = response['food_id'];
      if (foodId != null) {
        // Barkoddan food_id bulunduysa, onu arayalım
        if (mounted) Navigator.of(context).pop(); // Bottom sheet kapat
        final barcodeQuery = foodId['value']?.toString() ?? foodId.toString();
        _currentQuery = barcodeQuery;
        _searchController.text = barcodeQuery;
        await _searchFoods(reset: true);
        return;
      } else {
        final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
        setState(() {
          _hasError = true;
          _errorMessage = isTr ? 'Bu barkoda ait ürün bulunamadı.' : 'No product found for this barcode.';
        });
      }
    } catch (e) {
      final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
      setState(() {
        _hasError = true;
        _errorMessage = isTr ? 'Barkod araması başarısız: $e' : 'Barcode search failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
    if (mounted) Navigator.of(context).pop(); // Bottom sheet kapat
  }

  Future<void> _translateAndRefresh(List<FoodItem> itemsToTranslate) async {
    if (itemsToTranslate.isEmpty) return;
    if (!mounted) return;
    setState(() => _isTranslating = true);
    try {
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      await ServiceLocator.groqTranslation.translateFoodItems(itemsToTranslate, isTurkish: isTr);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('_translateAndRefresh hata: $e');
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _showBarcodeDialog() {
    _barcodeController.clear();
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr ? 'Barkod ile Ara' : 'Search by Barcode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: isTr ? 'Barkod numarasını girin...' : 'Enter barcode number...',
                    hintStyle: TextStyle(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searchByBarcode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isTr ? 'Barkod ile Ara' : 'Search by Barcode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTr ? 'Besin Arama' : 'Food Search',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: _showBarcodeDialog,
            tooltip: isTr ? 'Barkod ile Ara' : 'Search by Barcode',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isTr),
          _buildFilterRow(isTr),
          Expanded(
            child: _isLoading || (_isTranslating && _foods.isEmpty)
                ? const _FunLoadingView()
                : _hasError
                    ? _buildError(isTr)
                    : _foods.isEmpty
                        ? _buildEmpty(isTr)
                        : _buildFoodList(),
          ),
        ],
      ),
    );
  }

  // ───────────── Arama Çubuğu ─────────────
  Widget _buildSearchBar(bool isTr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
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
                controller: _searchController,
                onSubmitted: (value) {
                  _currentQuery = value;
                  _searchFoods();
                },
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: isTr ? 'Besin arayın...' : 'Search food...',
                  hintStyle: TextStyle(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  _currentQuery = _searchController.text;
                  _searchFoods();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.search, color: AppColors.onPrimary, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── Filtre Satırı ─────────────
  Widget _buildFilterRow(bool isTr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          // Tür filtresi (Hepsi / Marka / Genel)
          Row(
            children: [
              _buildTypeChip(isTr ? 'Hepsi' : 'All', null),
              const SizedBox(width: 8),
              _buildTypeChip(isTr ? 'Genel' : 'Generic', 'Generic'),
              const SizedBox(width: 8),
              _buildTypeChip(isTr ? 'Marka' : 'Brand', 'Brand'),
              const Spacer(),
              // Sonuç sayısı
              if (!_isLoading && _totalResults > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isTr ? '$_totalResults sonuç' : '$_totalResults results',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          // Kategori filtresi
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip(null, isTr ? 'Tüm Kategoriler' : 'All Categories');
                  }
                  final cat = _categories[index - 1];
                  return _buildCategoryChip(cat, isTr ? cat.categoryNameTr : cat.categoryName);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String? type) {
    final isSelected = _foodTypeFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() => _foodTypeFilter = type);
        _searchFoods();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipBackground : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.chipText : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(FoodCategory? category, String label) {
    final isSelected = _selectedCategory?.categoryId == category?.categoryId;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        
        final text = _searchController.text.trim();
        if (category != null) {
          if (text.isEmpty) {
            // Arama barı boşsa kategori adıyla API araması yap
            _currentQuery = category.categoryNameTr.isNotEmpty ? category.categoryNameTr : category.categoryName;
            _searchFoods();
          } else {
            // Arama barı doluysa, aramayı etkileme, sadece yerel filtreleme tetikle
            setState(() {});
          }
        } else {
          // 'Tüm Kategoriler' seçildiyse yerel filtrelemeyi sıfırla
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tertiaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.onTertiaryContainer
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ───────────── Hata / Boş Durumlar ─────────────
  Widget _buildError(bool isTr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              isTr ? 'Bir hata oluştu' : 'An error occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _searchFoods,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(isTr ? 'Tekrar Dene' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isTr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              isTr ? 'Sonuç bulunamadı' : 'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTr ? 'Farklı bir arama ifadesi deneyin.' : 'Try a different search term.',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── Besin Kartları Listesi ─────────────
  Widget _buildFoodList() {
    final filtered = _filteredFoods;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    
    if (filtered.isEmpty && _foods.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_off, size: 56, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                isTr ? 'Bu kategoride sonuç bulunamadı' : 'No results in this category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTr ? 'Başka bir kategori seçmeyi deneyin.' : 'Try selecting another category.',
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return _buildEmpty(isTr);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          );
        }
        return _buildFoodCard(filtered[index]);
      },
    );
  }

  Widget _buildListEmoji(String name) {
    final n = name.toLowerCase();
    String emoji = '🍽️';
    if (n.contains('chicken') || n.contains('tavuk')) {
      emoji = '🍗';
    } else if (n.contains('beef') || n.contains('meat') || n.contains('et')) {
      emoji = '🥩';
    } else if (n.contains('fish') || n.contains('balık') || n.contains('salmon')) {
      emoji = '🐟';
    } else if (n.contains('egg') || n.contains('yumurta')) {
      emoji = '🥚';
    } else if (n.contains('milk') || n.contains('süt') || n.contains('dairy')) {
      emoji = '🥛';
    } else if (n.contains('bread') || n.contains('ekmek')) {
      emoji = '🍞';
    } else if (n.contains('rice') || n.contains('pirinç')) {
      emoji = '🍚';
    } else if (n.contains('pasta') || n.contains('makarna')) {
      emoji = '🍝';
    } else if (n.contains('salad') || n.contains('salata')) {
      emoji = '🥗';
    } else if (n.contains('soup') || n.contains('çorba')) {
      emoji = '🍲';
    } else if (n.contains('fruit') || n.contains('meyve') || n.contains('apple') || n.contains('elma')) {
      emoji = '🍎';
    } else if (n.contains('vegetable') || n.contains('sebze')) {
      emoji = '🥦';
    } else if (n.contains('butter') || n.contains('tereyağ')) {
      emoji = '🧈';
    } else if (n.contains('cheese') || n.contains('peynir')) {
      emoji = '🧀';
    } else if (n.contains('chocolate') || n.contains('çikolata')) {
      emoji = '🍫';
    } else if (n.contains('coffee') || n.contains('kahve')) {
      emoji = '☕';
    } else if (n.contains('cake') || n.contains('pasta') || n.contains('dessert')) {
      emoji = '🍰';
    }

    return Container(
      color: AppColors.surfaceContainerLow,
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildFoodCard(FoodItem food) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final name = isTr ? food.foodNameTr : food.foodName;
    final description = isTr ? food.foodDescriptionTr : food.foodDescription;
    final typeLabel = isTr ? food.foodTypeTr : food.foodType;
    final categories = isTr ? food.subCategoriesTr : food.subCategories;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showFoodDetail(food),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım: isim + tip badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yemek ikonu veya fotoğrafı
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: food.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: food.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => _buildListEmoji(name),
                              )
                            : FutureBuilder<String?>(
                                future: WikipediaImageService.instance.findImageForFood(food.foodName),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return CachedNetworkImage(
                                      imageUrl: snapshot.data!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => _buildListEmoji(name),
                                      errorWidget: (_, _, _) => _buildListEmoji(name),
                                    );
                                  }
                                  return _buildListEmoji(name);
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (food.brandName != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              food.brandName!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Tip badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: food.foodType.toLowerCase() == 'brand'
                            ? const Color(0xFFFFF3E0)
                            : AppColors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: food.foodType.toLowerCase() == 'brand'
                              ? const Color(0xFFE65100)
                              : AppColors.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Besin açıklaması
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Alt-kategoriler
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: categories.take(3).map((subTr) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subTr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── Besin Detay Bottom Sheet ─────────────
  void _showFoodDetail(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodDetailSheet(food: food),
    );
  }
}


class _NutritionRow {
  final String label;
  final String value;
  final String unit;
  _NutritionRow(this.label, this.value, this.unit);
}

// ─────────────────────────────────────────────────────────
// Besin Detay + Tarif Üretme Bottom Sheet
// ─────────────────────────────────────────────────────────
class _FoodDetailSheet extends StatefulWidget {
  final FoodItem food;
  const _FoodDetailSheet({required this.food});

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  String? _recipe;
  bool _isLoadingRecipe = false;
  String? _recipeError;
  bool _isTranslatingDetail = false;
  String? _wikipediaImageUrl;
  bool _isLoadingWikiImage = false;

  @override
  void initState() {
    super.initState();
    _translateDetailIfNeeded();
    if (widget.food.imageUrl == null) {
      _fetchWikipediaImage();
    } else {
      _saveToHistory();
    }
  }

  Future<void> _fetchWikipediaImage() async {
    setState(() => _isLoadingWikiImage = true);
    final url = await WikipediaImageService.instance.findImageForFood(widget.food.foodName);
    if (mounted) {
      setState(() {
        _wikipediaImageUrl = url;
        _isLoadingWikiImage = false;
      });
      _saveToHistory();
    }
  }

  void _saveToHistory() {
    final userId = ServiceLocator.auth.currentUser?.uid;
    if (userId != null) {
      final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
      final name = isTr ? widget.food.foodNameTr : widget.food.foodName;
      final typeLabel = isTr ? widget.food.foodTypeTr : widget.food.foodType;
      final description = isTr ? widget.food.foodDescriptionTr : widget.food.foodDescription;

      final historyMap = <String, dynamic>{
        'title': name,
        'name': widget.food.foodName,
        'category': typeLabel,
        'food_id': widget.food.foodId,
        'brand_name': widget.food.brandName,
        'description': description,
        'imageUrl': widget.food.imageUrl ?? _wikipediaImageUrl,
      };

      if (_recipe != null) {
        historyMap['recipe_text'] = _recipe;
        final parsed = PortionParser.parseMarkdownRecipe(_recipe!);
        historyMap.addAll(parsed);
      }

      ServiceLocator.recipes.saveToHistory(userId, historyMap);
    }
  }

  Future<void> _translateDetailIfNeeded() async {
    final food = widget.food;
    final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
    
    if (!isTr) {
      try {
        await ServiceLocator.groqTranslation.translateFoodDetail(food, isTurkish: false);
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Error translating food detail to English: $e');
      }
      return;
    }

    final needsDesc = food.foodDescriptionTr == food.foodDescription &&
        food.foodDescription.isNotEmpty;
    final needsAllergens = food.allergens.isNotEmpty &&
        food.allergensTr.isNotEmpty &&
        food.allergensTr.first == food.allergens.first;
    final needsServings = food.servings.any((s) =>
        s.servingDescriptionTr == s.servingDescription &&
        s.servingDescription.isNotEmpty);

    if (!needsDesc && !needsAllergens && !needsServings) return;

    if (mounted) setState(() => _isTranslatingDetail = true);
    try {
      await ServiceLocator.groqTranslation.translateFoodDetail(food, isTurkish: true);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error translating food detail: $e');
    } finally {
      if (mounted) setState(() => _isTranslatingDetail = false);
    }
  }

  Future<void> _generateRecipe() async {
    setState(() {
      _isLoadingRecipe = true;
      _recipeError = null;
      _recipe = null;
    });
    try {
      final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
      final foodName = isTr ? widget.food.foodNameTr : widget.food.foodName;
      final prompt = isTr
          ? 'Sen profesyonel, sürdürülebilir mutfak ve sıfır atık konusunda uzman bir şefsin. '
            'Lütfen "$foodName" için mükemmel kalitede, Markdown formatında, adım adım bir Türkçe tarif hazırla. '
            'Tarif şu bölümleri içermeli ve şık bir şekilde formatlanmalıdır:\n\n'
            '1. **🏷️ Tarif Adı**: Gösterişli ve iştah açıcı bir başlık (örn: H1 veya H2 boyutunda).\n'
            '2. **⏱️ Özet Bilgiler**: Hazırlık Süresi, Pişirme Süresi, Zorluk Derecesi (Kolay/Orta/Zor) ve Porsiyon (2-4 kişilik).\n'
            '3. **🛒 Malzemeler**: Tam ölçüleriyle düzenli bir liste. Gıda israfını önlemek için alternatif malzeme önerileri veya evde kalan malzemelerin nasıl değerlendirilebileceğine dair küçük notlar ekle.\n'
            '4. **👨‍🍳 Hazırlanışı**: Adım adım, anlaşılır ve numaralandırılmış pişirme talimatları. Önemli teknikleri ve süreleri kalın (bold) yaz.\n'
            '5. **💡 Şefin Sıfır Atık İpucu**: Bu tarif yapılırken mutfaktaki diğer malzemelerin israfını nasıl önleyeceğimize veya bu yemeğin artan kısımlarını nasıl değerlendirebileceğimize dair yaratıcı bir sürdürülebilirlik ipucu.\n\n'
            'Çıktının tamamen profesyonel, Markdown standartlarına uygun, temiz ve motive edici bir dilde olmasını sağla.'
          : 'You are a professional chef specializing in sustainable cooking and zero waste. '
            'Please prepare a high-quality, step-by-step recipe in English for "$foodName" in Markdown format. '
            'The recipe must include these sections and be stylishly formatted:\n\n'
            '1. **🏷️ Recipe Name**: An appealing and appetizing title (e.g., H1 or H2 size).\n'
            '2. **⏱️ Quick Info**: Prep Time, Cook Time, Difficulty (Easy/Medium/Hard), and Serving Size (2-4 people).\n'
            '3. **🛒 Ingredients**: A well-organized list with exact measurements. Include small tips on alternative ingredients or how to use leftover ingredients to avoid food waste.\n'
            '4. **👨‍🍳 Directions**: Step-by-step, clear, and numbered cooking instructions. Write important techniques and times in bold.\n'
            '5. **💡 Chef\'s Zero Waste Tip**: A creative sustainability tip on how to avoid wasting other ingredients in the kitchen while making this recipe or how to repurpose leftovers.\n\n'
            'Ensure the output is fully professional, adheres to Markdown standards, clean, and in an encouraging tone.';
      final result = await ServiceLocator.groqChat.sendMessage(prompt, isTurkish: isTr);
      setState(() => _recipe = result);
      _saveToHistory(); // Tarife ulaşıldığında geçmiş kaydını güncel tarife göre güncelle
    } catch (e) {
      final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
      setState(() => _recipeError = isTr ? 'Tarif alınamadı. Lütfen tekrar deneyin.' : 'Could not retrieve recipe. Please try again.');
    } finally {
      setState(() => _isLoadingRecipe = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final name = isTr ? food.foodNameTr : food.foodName;
    final description = isTr ? food.foodDescriptionTr : food.foodDescription;
    final typeLabel = isTr ? food.foodTypeTr : food.foodType;
    final allergens = isTr ? food.allergensTr : food.allergens;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            // Tutma çubuğu
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Yemek Fotoğrafı
            if (food.imageUrl != null || _wikipediaImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: food.imageUrl ?? _wikipediaImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    height: 200,
                    color: AppColors.surfaceContainerLow,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, _, _) => _buildImagePlaceholder(name),
                ),
              )
            else if (_isLoadingWikiImage)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
              )
            else
              _buildImagePlaceholder(name),
            const SizedBox(height: 20),

            // Başlık
            Text(
              name,
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: AppColors.onSurface, height: 1.2,
              ),
            ),
            if (food.brandName != null) ...[
              const SizedBox(height: 6),
              Text(food.brandName!,
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),

            // Tip badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.onTertiaryContainer),
              ),
            ),
            const SizedBox(height: 16),

            // Açıklama — sadece dolu ise göster
            if (_isTranslatingDetail || description.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isTranslatingDetail
                    ? Row(children: [
                        SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTr ? 'Türkçeye çevriliyor...' : 'Translating details...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ])
                    : Text(
                        description,
                        style: TextStyle(
                          fontSize: 13, color: AppColors.onSurface, height: 1.5),
                      ),
              ),
            const SizedBox(height: 20),

            // ── Tarif Butonu ──
            if (_recipe == null && !_isLoadingRecipe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateRecipe,
                  icon: const Text('🍳', style: TextStyle(fontSize: 18)),
                  label: Text(
                    isTr ? 'Aura Şef\'ten Tarif Al' : 'Get Recipe from Aura Chef',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

            // ── Tarif Yükleniyor ──
            if (_isLoadingRecipe)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(isTr ? 'Aura Şef tarif hazırlıyor...' : 'Aura Chef is preparing recipe...',
                      style: TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            // ── Tarif Hata ──
            if (_recipeError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_recipeError!,
                      style: TextStyle(color: AppColors.error, fontSize: 13))),
                    TextButton(onPressed: _generateRecipe, child: Text(isTr ? 'Tekrar' : 'Retry')),
                  ],
                ),
              ),

            // ── Tarif İçeriği ──
            if (_recipe != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🍳', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(isTr ? 'TARİF' : 'RECIPE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                            letterSpacing: 1.5, color: AppColors.primary)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _generateRecipe,
                          child: Icon(Icons.refresh, size: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: _recipe!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 14, height: 1.6, color: AppColors.onSurface),
                        strong: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.onSurface),
                        h2: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                          color: AppColors.onSurface),
                        h3: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.onSurface),
                        listBullet: TextStyle(color: AppColors.primary),
                      ),
                      shrinkWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Besin Değerleri ──
            if (food.servings.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(isTr ? 'BESİN DEĞERLERİ' : 'NUTRITIONAL VALUES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 10),
              _buildNutritionTable(food.servings.first, isTr),
            ],

            // ── Alerjenler ──
            if (allergens.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(isTr ? 'ALERJENLER' : 'ALLERGENS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: allergens.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.warning_amber, size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Text(a, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100))),
                  ]),
                )).toList(),
              ),
            ],

            // ── Favoriye Ekle ──
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final userId = ServiceLocator.auth.currentUser?.uid;
                  if (userId != null) {
                    final favMap = <String, dynamic>{
                      'title': name,
                      'name': food.foodName,
                      'category': typeLabel,
                      'food_id': food.foodId,
                      'brand_name': food.brandName,
                      'description': description,
                      'isFavorite': true,
                      'imageUrl': food.imageUrl ?? _wikipediaImageUrl,
                    };
                    if (_recipe != null) {
                      favMap['recipe_text'] = _recipe;
                      final parsed = PortionParser.parseMarkdownRecipe(_recipe!);
                      favMap.addAll(parsed);
                    }
                    ServiceLocator.recipes.saveRecipe(userId, favMap);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isTr ? '$name favorilere eklendi!' : '$name added to favorites!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                icon: const Icon(Icons.favorite_border, size: 18),
                label: Text(isTr ? 'Favorilere Ekle' : 'Add to Favorites',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String name) {
    // İsme göre uygun emoji seç
    final n = name.toLowerCase();
    String emoji = '🍽️';
    if (n.contains('chicken') || n.contains('tavuk')) {
      emoji = '🍗';
    } else if (n.contains('beef') || n.contains('meat') || n.contains('et')) {
      emoji = '🥩';
    } else if (n.contains('fish') || n.contains('balık') || n.contains('salmon')) {
      emoji = '🐟';
    } else if (n.contains('egg') || n.contains('yumurta')) {
      emoji = '🥚';
    } else if (n.contains('milk') || n.contains('süt') || n.contains('dairy')) {
      emoji = '🥛';
    } else if (n.contains('bread') || n.contains('ekmek')) {
      emoji = '🍞';
    } else if (n.contains('rice') || n.contains('pirinç')) {
      emoji = '🍚';
    } else if (n.contains('pasta') || n.contains('makarna')) {
      emoji = '🍝';
    } else if (n.contains('salad') || n.contains('salata')) {
      emoji = '🥗';
    } else if (n.contains('soup') || n.contains('çorba')) {
      emoji = '🍲';
    } else if (n.contains('fruit') || n.contains('meyve') || n.contains('apple') || n.contains('elma')) {
      emoji = '🍎';
    } else if (n.contains('vegetable') || n.contains('sebze')) {
      emoji = '🥦';
    } else if (n.contains('butter') || n.contains('tereyağ')) {
      emoji = '🧈';
    } else if (n.contains('cheese') || n.contains('peynir')) {
      emoji = '🧀';
    } else if (n.contains('chocolate') || n.contains('çikolata')) {
      emoji = '🍫';
    } else if (n.contains('coffee') || n.contains('kahve')) {
      emoji = '☕';
    } else if (n.contains('cake') || n.contains('pasta') || n.contains('dessert')) {
      emoji = '🍰';
    }

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.4),
            AppColors.tertiaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 72)),
      ),
    );
  }

  Widget _buildNutritionTable(FoodServing serving, bool isTr) {
    final servingDesc = isTr ? serving.servingDescriptionTr : serving.servingDescription;
    final items = [
      _NutritionRow(isTr ? 'Porsiyon' : 'Serving', servingDesc, ''),
      _NutritionRow(isTr ? 'Kalori' : 'Calories', serving.calories.toStringAsFixed(1), 'kcal'),
      _NutritionRow(isTr ? 'Toplam Yağ' : 'Total Fat', serving.fat.toStringAsFixed(1), 'g'),
      _NutritionRow(isTr ? 'Karbonhidrat' : 'Carbs', serving.carbohydrate.toStringAsFixed(1), 'g'),
      _NutritionRow(isTr ? 'Protein' : 'Protein', serving.protein.toStringAsFixed(1), 'g'),
      _NutritionRow(isTr ? 'Lif' : 'Fiber', serving.fiber.toStringAsFixed(1), 'g'),
      _NutritionRow(isTr ? 'Şeker' : 'Sugar', serving.sugar.toStringAsFixed(1), 'g'),
      _NutritionRow(isTr ? 'Sodyum' : 'Sodium', serving.sodium.toStringAsFixed(1), 'mg'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key; final row = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: i == 0 ? AppColors.primaryContainer.withValues(alpha: 0.25) : null,
              border: i < items.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.12)))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.label, style: TextStyle(
                  fontSize: 13, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.onSurface)),
                Text(row.unit.isNotEmpty ? '${row.value} ${row.unit}' : row.value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: i == 0 ? AppColors.primary : AppColors.onSurface)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FunLoadingView extends StatefulWidget {
  const _FunLoadingView();

  @override
  State<_FunLoadingView> createState() => _FunLoadingViewState();
}

class _FunLoadingViewState extends State<_FunLoadingView> {
  List<String> get _messages {
    final isTr = mounted ? Localizations.localeOf(context).languageCode == 'tr' : true;
    return isTr
        ? const [
            'Tarifleriniz özenle hazırlanıyor...',
            'Malzemeler mutfaktan seçiliyor...',
            'Aura Şef lezzet sırlarını ekliyor...',
            'Dünya mutfakları araştırılıyor...',
            'Sizin için en iyisi çevriliyor...',
            'Neredeyse hazır, son dokunuşlar...',
          ]
        : const [
            'Your recipes are being prepared carefully...',
            'Ingredients are being selected from the kitchen...',
            'Aura Chef is adding taste secrets...',
            'World cuisines are being researched...',
            'Translating the best for you...',
            'Almost ready, final touches...',
          ];
  }
  
  final List<String> _emojis = ['👨‍🍳', '🍳', '🍲', '🥗', '🥘', '🔪', '🧂', '🔥'];
  
  int _currentIndex = 0;
  int _emojiIndex = 0;
  late final Timer _timer;
  late final Timer _emojiTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
    _emojiTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _emojiIndex = (_emojiIndex + 1) % _emojis.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _emojiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
                  parent: animation, curve: Curves.elasticOut,
                )),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              _emojis[_emojiIndex],
              key: ValueKey<int>(_emojiIndex),
              style: const TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
            child: Text(
              _messages[_currentIndex],
              key: ValueKey<int>(_currentIndex),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
