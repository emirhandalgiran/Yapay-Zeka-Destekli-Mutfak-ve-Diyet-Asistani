import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';

class ShareRecipeScreen extends StatefulWidget {
  const ShareRecipeScreen({super.key});

  @override
  State<ShareRecipeScreen> createState() => _ShareRecipeScreenState();
}

class _ShareRecipeScreenState extends State<ShareRecipeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  late final List<String> _ingredients;
  bool _ingredientsInitialized = false;

  int _selectedCategory = 0;
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  List<Map<String, dynamic>> _getCategoriesList(bool isTr) {
    return [
      {'label': isTr ? 'Kahvaltı' : 'Breakfast', 'icon': Icons.wb_sunny_outlined},
      {'label': isTr ? 'Akşam Yemeği' : 'Dinner', 'icon': Icons.restaurant_outlined},
      {'label': isTr ? 'Tatlılar' : 'Desserts', 'icon': Icons.cake_outlined},
      {'label': isTr ? 'Atıştırmalık' : 'Snacks', 'icon': Icons.local_cafe_outlined},
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ingredientsInitialized) {
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      _ingredients = isTr 
          ? ['2 Adet Yumurta', 'Sızma Zeytinyağı'] 
          : ['2 Eggs', 'Extra Virgin Olive Oil'];
      _ingredientsInitialized = true;
    }
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
      });
      _ingredientController.clear();
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File file = File(image.path);
      final int sizeInBytes = await file.length();
      final double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 10) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Fotoğraf boyutu 10MB\'dan küçük olmalıdır.' : 'Photo size must be less than 10MB.')),
        );
        return;
      }
      setState(() {
        _selectedImage = file;
      });
    }
  }

  Future<void> _submitRecipe() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final name = _nameController.text.trim();
    final steps = _stepsController.text.trim();

    if (name.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr ? 'Lütfen tarif ismini ve hazırlanışını giriniz.' : 'Please enter recipe name and instructions.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      String imageUrl = '';
      if (_selectedImage != null) {
        final uploadedPath = await ServiceLocator.social.uploadImage(user.uid, _selectedImage!);
        if (uploadedPath != null) {
          imageUrl = uploadedPath;
        } else {
          setState(() => _isUploading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isTr ? 'Hata: Fotoğraf yüklenemedi.' : 'Error: Photo could not be uploaded.')),
          );
          return;
        }
      }

      final category = _getCategoriesList(isTr)[_selectedCategory]['label'];
      
      final recipeData = {
        'name': name,
        'title': name,
        'instructions': steps,
        'ingredients': _ingredients,
        'category': category,
        'imageUrl': imageUrl,
      };

      try {
        await ServiceLocator.recipes.saveRecipe(user.uid, recipeData);
        await ServiceLocator.social.createPost(user.uid, {
          'title': name,
          'description': steps,
          'imageUrl': imageUrl,
          'authorName': user.displayName ?? (isTr ? 'AuraCook Şefi' : 'AuraCook Chef'),
          'authorLetter': (user.displayName ?? 'A').substring(0, 1).toUpperCase(),
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(isTr ? 'Hata: $e' : 'Error: $e'))
        );
        return;
      }
    }

    setState(() => _isUploading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTr ? 'Tarifiniz toplulukla paylaşıldı!' : 'Your recipe has been shared with the community!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSection(isTr),
            const SizedBox(height: 24),
            _buildPhotoUpload(isTr),
            const SizedBox(height: 28),
            _buildNameField(isTr),
            const SizedBox(height: 28),
            _buildIngredientsSection(isTr),
            const SizedBox(height: 28),
            _buildCategorySection(isTr),
            const SizedBox(height: 28),
            _buildStepsField(isTr),
            const SizedBox(height: 28),
            _buildSubmitButton(isTr),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'AuraCook',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              color: AppColors.onSurfaceVariant,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(bool isTr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'Tarif Paylaş' : 'Share Recipe',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTr ? 'Mutfağındaki sihirli dokunuşu toplulukla buluştur.' : 'Share your kitchen magic with the community.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload(bool isTr) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          image: _selectedImage != null 
             ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
             : null,
        ),
        child: _selectedImage == null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isTr ? 'Tarif Fotoğrafı Ekle' : 'Add Recipe Photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG (Max 10MB)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ) : Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(Icons.edit, color: AppColors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(bool isTr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'TARİF İSMİ' : 'RECIPE NAME',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: isTr ? 'Örn: Portakallı Ördek' : 'e.g., Orange Duck',
            hintStyle: TextStyle(
              color: AppColors.outlineVariant,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(bool isTr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'MALZEMELER' : 'INGREDIENTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(_ingredients.length, (index) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _ingredients[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeIngredient(index),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: () => _showAddIngredientDialog(isTr),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        isTr ? 'Ekle' : 'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddIngredientDialog(bool isTr) {
    _ingredientController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTr ? 'Malzeme Ekle' : 'Add Ingredient',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: _ingredientController,
          autofocus: true,
          onSubmitted: (_) {
            _addIngredient();
            Navigator.pop(ctx);
          },
          decoration: InputDecoration(
            hintText: isTr ? 'Örn: 200g Un' : 'e.g., 200g Flour',
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTr ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addIngredient();
              Navigator.pop(ctx);
            },
            child: Text(isTr ? 'Ekle' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(bool isTr) {
    final categories = _getCategoriesList(isTr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'KATEGORİ' : 'CATEGORY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedCategory == index;
            final cat = categories[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: isSelected
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepsField(bool isTr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'NASIL YAPILIR' : 'DIRECTIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _stepsController,
          maxLines: 6,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: isTr ? 'Adım adım tarifinizi buraya yazın...' : 'Write your recipe step-by-step here...',
            hintStyle: TextStyle(
              color: AppColors.outlineVariant,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isTr) {
    return GestureDetector(
      onTap: _isUploading ? null : _submitRecipe,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isUploading 
              ? [AppColors.outlineVariant, AppColors.outlineVariant]
              : [AppColors.primary, AppColors.primaryDim],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!_isUploading)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: _isUploading 
          ? Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)))
          : Text(
              isTr ? 'Toplulukla Paylaş' : 'Share with Community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
                letterSpacing: 0.3,
              ),
            ),
      ),
    );
  }
}
