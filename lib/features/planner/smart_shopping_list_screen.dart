import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SmartShoppingListScreen extends StatefulWidget {
  const SmartShoppingListScreen({super.key});

  @override
  State<SmartShoppingListScreen> createState() => _SmartShoppingListScreenState();
}

class _SmartShoppingListScreenState extends State<SmartShoppingListScreen> {
  // Mock veri: NLP veya parsing sonucu birleştirilmiş liste (Örn: 2 tarifte yumurta var)
  final List<Map<String, dynamic>> _shoppingItems = [
    {'name': 'Yumurta', 'amount': '5 Adet', 'isChecked': false},
    {'name': 'Un', 'amount': '500 gr', 'isChecked': false},
    {'name': 'Somon Fileto', 'amount': '2 Dilim', 'isChecked': false},
    {'name': 'Kırmızı Mercimek', 'amount': '1 Su Bardağı', 'isChecked': true},
    {'name': 'Süt', 'amount': '1 Litre', 'isChecked': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Akıllı Alışveriş Listesi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shoppingItems.length,
        itemBuilder: (context, index) {
          final item = _shoppingItems[index];
          return CheckboxListTile(
            title: Text(
              item['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: item['isChecked'] ? TextDecoration.lineThrough : null,
                color: item['isChecked'] ? AppColors.onSurfaceVariant : AppColors.onSurface,
              ),
            ),
            subtitle: Text(item['amount']),
            value: item['isChecked'],
            activeColor: AppColors.primary,
            onChanged: (bool? value) {
              setState(() {
                _shoppingItems[index]['isChecked'] = value ?? false;
              });
            },
            secondary: Icon(
              Icons.shopping_basket_outlined,
              color: item['isChecked'] ? AppColors.onSurfaceVariant.withValues(alpha: 0.5) : AppColors.primary,
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Liste temizlendi!')),
              );
              setState(() {
                _shoppingItems.removeWhere((element) => element['isChecked'] == true);
              });
            },
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label: const Text('Alınanları Temizle', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
