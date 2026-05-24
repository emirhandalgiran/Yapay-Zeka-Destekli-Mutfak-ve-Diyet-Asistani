import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/components/custom_user_avatar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../notifications/notifications_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  String get _userId => ServiceLocator.auth.currentUser?.uid ?? '';

  void _showAddItemDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Yeni Ürün Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Örn: 1 Litre Süt',
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty && _userId.isNotEmpty) {
              ServiceLocator.shopping.addShoppingItem(_userId, controller.text.trim());
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && _userId.isNotEmpty) {
                ServiceLocator.shopping.addShoppingItem(_userId, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: _userId.isEmpty 
          ? const Center(child: Text('Giriş yapmanız gerekiyor.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: ServiceLocator.shopping.getShoppingListStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Bir hata oluştu'));
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return _buildShimmerLoading();
                }

                final items = snapshot.data ?? [];
                final int totalItems = items.length;
                final int uncheckedCount = items.where((item) => item['isPurchased'] == false).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 28),
                      _buildStatsRow(totalItems, uncheckedCount),
                      const SizedBox(height: 32),
                      _buildItemsSection(items),
                    ],
                  ),
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLow,
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
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: CustomUserAvatar(radius: 15),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MUTFAK YÖNETİMİ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Akıllı Alışveriş\nListesi',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tariflerinizden eksik olan malzemeler otomatik olarak buraya eklenir. Sağlıklı bir mutfak, düzenli bir liste ile başlar.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showAddItemDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: AppColors.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Yeni Ürün Ekle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int totalItems, int uncheckedCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Toplam Ürün',
            value: totalItems.toString().padLeft(2, '0'),
            bgColor: AppColors.white,
            valueColor: AppColors.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Eksik Malzeme',
            value: uncheckedCount.toString().padLeft(2, '0'),
            bgColor: AppColors.primaryContainer.withValues(alpha: 0.3),
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alınan Ürün',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (totalItems - uncheckedCount).toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color bgColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Alışveriş listeniz şu an boş.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Alışveriş Listem',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              '${items.length} ÜRÜN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final String id = item['id'].toString();
          final bool isChecked = item['isPurchased'] == true;
          
          return _buildShoppingItemTile(
            name: item['name'] ?? 'İsimsiz Ürün',
            isChecked: isChecked,
            onToggle: () => ServiceLocator.shopping.updateItemStatus(_userId, id, !isChecked),
            onDelete: () => ServiceLocator.shopping.deleteItem(_userId, id),
          );
        }),
      ],
    );
  }

  Widget _buildShoppingItemTile({
    required String name,
    required bool isChecked,
    required VoidCallback onToggle,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isChecked
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isChecked ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isChecked ? AppColors.primary : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? Icon(Icons.check, color: AppColors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isChecked ? AppColors.primary : AppColors.onSurface,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceContainerHigh,
        highlightColor: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 28),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Items
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


