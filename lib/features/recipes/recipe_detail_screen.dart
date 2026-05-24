import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/portion_parser.dart';
import 'data/offline_recipe_service.dart';
import '../../core/di/service_locator.dart';
import '../../core/api/wikipedia_image_service.dart';
import 'hands_free_cooking_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const RecipeDetailScreen({super.key, required this.recipeData});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _servingCount = 2; // Varsayılan porsiyon sayısı (base=2 kabul edelim)
  final int _baseServing = 2;
  
  late List<String> _ingredients;
  Map<String, dynamic> _parsedRecipe = {};

  @override
  void initState() {
    super.initState();
    // Quest ve Geçmiş kaydı başlat
    final userId = ServiceLocator.auth.currentUser?.uid;
    if (userId != null) {
      ServiceLocator.gamification.incrementDailyQuest(userId, 'dailyRecipeViews');
      ServiceLocator.recipes.saveToHistory(userId, widget.recipeData);
    }
    // Parse recipe_text if available
    final recipeText = widget.recipeData['recipe_text'] as String?;
    if (recipeText != null && recipeText.isNotEmpty) {
      _parsedRecipe = PortionParser.parseMarkdownRecipe(recipeText);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    // Eğer veride malzeme varsa al, yoksa parse edilmiş veya yerelleştirilmiş mock veri göster (testing için)
    if (widget.recipeData['ingredients'] != null && widget.recipeData['ingredients'] is List && (widget.recipeData['ingredients'] as List).isNotEmpty) {
      _ingredients = List<String>.from(widget.recipeData['ingredients']);
    } else if (_parsedRecipe['ingredients'] != null && _parsedRecipe['ingredients'] is List && (_parsedRecipe['ingredients'] as List).isNotEmpty) {
      _ingredients = List<String>.from(_parsedRecipe['ingredients']);
    } else {
      _ingredients = isTr
          ? const [
              '2 su bardağı un',
              '1.5 çay kaşığı tuz',
              '3 adet yumurta',
              '1 bardak süt',
              '0.5 çay bardağı sıvı yağ'
            ]
          : const [
              '2 cups of flour',
              '1.5 teaspoons of salt',
              '3 eggs',
              '1 glass of milk',
              '0.5 small tea glass of vegetable oil'
            ];
    }
  }

  void _incrementServing() {
    setState(() {
      if (_servingCount < 20) _servingCount++;
    });
  }

  void _decrementServing() {
    setState(() {
      if (_servingCount > 1) _servingCount--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final title = widget.recipeData['title'] ?? widget.recipeData['name'] ?? _parsedRecipe['title'] ?? (isTr ? 'İsimsiz Tarif' : 'Untitled Recipe');
    final imageUrl = widget.recipeData['imageUrl'] as String?;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null';
    final prepTime = widget.recipeData['prepTime'] ?? _parsedRecipe['prepTime'] ?? (isTr ? '30 dk' : '30 min');
    final calories = widget.recipeData['calories'] ?? _parsedRecipe['calories'] ?? '350 kcal';
    final description = widget.recipeData['description'] ?? _parsedRecipe['description'] ?? (isTr ? 'Bu lezzetli tarifi kendi mutfağınızda hemen deneyin!' : 'Try this delicious recipe in your own kitchen now!');

    List<String> steps = [];
    if (widget.recipeData['instructions'] != null && widget.recipeData['instructions'] is List && (widget.recipeData['instructions'] as List).isNotEmpty) {
       steps = List<String>.from(widget.recipeData['instructions']);
    } else if (_parsedRecipe['instructions'] != null && _parsedRecipe['instructions'] is List && (_parsedRecipe['instructions'] as List).isNotEmpty) {
       steps = List<String>.from(_parsedRecipe['instructions']);
    } else {
       steps = isTr
           ? const [
               "Malzemeleri hazırlayın ve tezgaha dizin.",
               "Tencereyi ocağa alın ve yağı ısıtın.",
               "Ana malzemeleri ekleyip 5 dakika kavurun.",
               "Suyunu ekleyip kaynamaya bırakın.",
               "Kısık ateşte 20 dakika pişirin.",
               "Ocaktan alıp sıcak servis yapın."
             ]
           : const [
               "Prepare the ingredients and place them on the counter.",
               "Place the pot on the stove and heat the oil.",
               "Add main ingredients and sauté for 5 minutes.",
               "Add water and bring to a boil.",
               "Simmer on low heat for 20 minutes.",
               "Remove from heat and serve hot."
             ];
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HandsFreeCookingScreen(
                title: title,
                steps: steps,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: Text(isTr ? 'Şef Modu' : 'Chef Mode', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          // AppBar & Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            iconTheme: IconThemeData(color: AppColors.white),
            backgroundColor: AppColors.surfaceContainerLow,
            actions: [
              IconButton(
                icon: Icon(
                  OfflineRecipeService.isRecipeSaved(widget.recipeData['id']?.toString() ?? widget.recipeData['title'] ?? '')
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                onPressed: () {
                  final id = widget.recipeData['id']?.toString() ?? widget.recipeData['title'];
                  setState(() {
                    if (OfflineRecipeService.isRecipeSaved(id)) {
                      OfflineRecipeService.deleteRecipeConfig(id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTr ? 'Çevrimdışı kaydedilenlerden silindi.' : 'Removed from offline saved recipes.')));
                    } else {
                      OfflineRecipeService.saveRecipeConfig(widget.recipeData);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTr ? 'Çevrimdışı okumak için kaydedildi!' : 'Saved for offline reading!')));
                    }
                  });
                },
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              background: Hero(
                tag: 'recipe_img_${widget.recipeData['id']?.toString() ?? title}',
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                    : FutureBuilder<String?>(
                        future: WikipediaImageService.instance.findImageForFood(widget.recipeData['name'] ?? title),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                            return CachedNetworkImage(
                              imageUrl: snapshot.data!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _buildDetailPlaceholder(),
                              errorWidget: (_, _, _) => _buildDetailPlaceholder(),
                            );
                          }
                          return _buildDetailPlaceholder();
                        },
                      ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta bar
                  Row(
                    children: [
                      _buildMetaChip(Icons.timer, prepTime.toString()),
                      const SizedBox(width: 12),
                      _buildMetaChip(Icons.local_fire_department, calories.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    description.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Akıllı Porsiyon Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTr ? 'Malzemeler' : 'Ingredients',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      
                      // Porsiyon Seçici
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _decrementServing,
                              child: Icon(Icons.remove, size: 20, color: _servingCount > 1 ? AppColors.primary : AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isTr ? '$_servingCount Kişilik' : '$_servingCount Portions',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _incrementServing,
                              child: Icon(Icons.add, size: 20, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Dinamik Malzemeler Listesi
                  ..._ingredients.map((ingredient) {
                    final scaledIngredient = PortionParser.scaleIngredient(ingredient, _baseServing, _servingCount);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 12),
                            child: Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                          ),
                          Expanded(
                            child: Text(
                              scaledIngredient,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 32),
                  
                  // Hazırlanışı / Preparation Başlığı
                  Text(
                    isTr ? 'Hazırlanışı' : 'Preparation',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Adım Adım Hazırlanışı Listesi
                  if (steps.isEmpty)
                    Text(
                      isTr ? 'Bu tarif için hazırlık adımı bulunmuyor.' : 'No preparation steps found for this recipe.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  else
                    ...steps.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 12),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.4),
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.white),
      ),
    );
  }
}
