import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/components/aura_app_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/api/wikipedia_image_service.dart';
import '../navigation/app_drawer.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedFilterIndex = 0;

  String get _userId => ServiceLocator.auth.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildFilterChips(),
            const SizedBox(height: 24),
            _buildRecipesStream(),
          ],
        ),
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

  // ───────────── Header (Badge + Başlık) ─────────────
  Widget _buildHeaderSection() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KOLEKSİYON badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isTr ? 'KOLEKSİYON' : 'COLLECTION',
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
              isTr ? 'Yaratıcı\nTariflerim' : 'My Creative\nRecipes',
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
              isTr
                  ? 'Dolabınızdaki malzemelerden AI\'ın sizin için önerdiği benzersiz tarifler.'
                  : 'Unique recipes suggested for you by AI from the ingredients in your fridge.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.05, duration: 500.ms, curve: Curves.easeOut);
  }

  // ───────────── Filtre Chipleri ─────────────
  Widget _buildFilterChips() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final filters = isTr ? const ['Hepsi', 'Favoriler', 'Geçmiş'] : const ['All', 'Favorites', 'History'];
    return Row(
      children: List.generate(filters.length, (index) {
        final isSelected = _selectedFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.chipBackground
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.chipText
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturedPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildFeaturedRecipeCard(Map<String, dynamic> data) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final title = data['title'] ?? data['name'] ?? (isTr ? 'İsimsiz Tarif' : 'Untitled Recipe');
    final category = data['category'] ?? (isTr ? 'Dünya Mutfağı' : 'World Cuisine');
    final prepTime = data['prepTime'] ?? (isTr ? '20 dk' : '20 min');
    final calories = data['calories'] ?? '350 kcal';
    final imageUrl = data['imageUrl'];
    final recipeId = data['id']?.toString() ?? title;
    final bool hasImage = imageUrl != null && imageUrl.toString().isNotEmpty && imageUrl.toString() != 'null';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeData: data),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surfaceContainerLow,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'recipe_img_$recipeId',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        )
                      : FutureBuilder<String?>(
                          future: WikipediaImageService.instance.findImageForFood(data['name'] ?? title),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                              return CachedNetworkImage(
                                imageUrl: snapshot.data!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => _buildFeaturedPlaceholder(),
                                errorWidget: (_, _, _) => _buildFeaturedPlaceholder(),
                              );
                            }
                            return _buildFeaturedPlaceholder();
                          },
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.onSurface.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 20,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildInfoChip(Icons.access_time, prepTime.toString()),
                      const SizedBox(width: 10),
                      _buildInfoChip(
                        Icons.local_fire_department,
                        calories.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Tarif Kartları Grid (Dinamik) ─────────────
  Widget _buildRecipesStream() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    if (_userId.isEmpty) {
      return Center(
        child: Text(
          isTr ? 'Tarifleri görmek için giriş yapmalısınız.' : 'You must log in to view recipes.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    final Stream<List<Map<String, dynamic>>> stream;
    if (_selectedFilterIndex == 0) {
      stream = ServiceLocator.recipes.getAllRecipesStream(_userId);
    } else if (_selectedFilterIndex == 1) {
      stream = ServiceLocator.recipes.getSavedRecipesStream(_userId);
    } else {
      stream = ServiceLocator.recipes.getHistoryRecipesStream(_userId);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(isTr ? 'Bir hata oluştu.' : 'An error occurred.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildShimmerLoading();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _selectedFilterIndex == 0
                    ? (isTr ? 'Burada favori ve geçmiş tarifleriniz görünecek.' : 'Your favorite and past recipes will appear here.')
                    : _selectedFilterIndex == 1
                        ? (isTr ? 'Henüz favoriye aldığınız tarif yok.' : 'No favorite recipes yet.')
                        : (isTr ? 'Henüz incelediğiniz bir tarif yok.' : 'No recently viewed recipes yet.'),
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final featuredItem = items.first;
        final listItems = items.length > 1
            ? items.sublist(1)
            : <Map<String, dynamic>>[];

        return Column(
          children: [
            _buildFeaturedRecipeCard(featuredItem),
            const SizedBox(height: 20),
            if (listItems.isNotEmpty) _buildRecipeGrid(listItems),
          ],
        );
      },
    );
  }

  Widget _buildRecipeGrid(List<Map<String, dynamic>> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: _buildSmallRecipeCard(
                    items[i],
                    items[i]['id'].toString(),
                  ),
                ),
                const SizedBox(width: 14),
                if (i + 1 < items.length)
                  Expanded(
                    child: _buildSmallRecipeCard(
                      items[i + 1],
                      items[i + 1]['id'].toString(),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.4),
            AppColors.primary.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 44,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildSmallRecipeCard(Map<String, dynamic> data, String docId) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final title = data['title'] ?? data['name'] ?? (isTr ? 'İsimsiz Tarif' : 'Untitled Recipe');
    final category = data['category'] ?? (isTr ? 'Dünya Mutfağı' : 'World Cuisine');
    final isFavorite =
        _selectedFilterIndex == 1 || (data['isFavorite'] == true);
    final imageUrl = data['imageUrl'];
    final bool hasImage = imageUrl != null && imageUrl.toString().isNotEmpty && imageUrl.toString() != 'null';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeData: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel alanı
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.4),
                    AppColors.primary.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'recipe_img_$docId',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                              )
                            : FutureBuilder<String?>(
                                future: WikipediaImageService.instance.findImageForFood(data['name'] ?? title),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                                    return CachedNetworkImage(
                                      imageUrl: snapshot.data!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => _buildSmallPlaceholder(),
                                      errorWidget: (_, _, _) => _buildSmallPlaceholder(),
                                    );
                                  }
                                  return _buildSmallPlaceholder();
                                },
                              ),
                      ),
                    ),
                  ),

                  // Yemek ikonu (Eğer resim yoksa)
                  if (!hasImage)
                    Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 44,
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),

                  // Favori ikonu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedFilterIndex == 1) {
                          // Favorilerden çıkar
                          ServiceLocator.recipes.removeSavedRecipe(
                            _userId,
                            docId,
                          );
                        } else {
                          // Favorilere ekle
                          data['id'] = docId;
                          ServiceLocator.recipes.saveRecipe(_userId, data);
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite
                              ? const Color(0xFFE74C3C)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceContainerHigh,
        highlightColor: AppColors.surface,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
