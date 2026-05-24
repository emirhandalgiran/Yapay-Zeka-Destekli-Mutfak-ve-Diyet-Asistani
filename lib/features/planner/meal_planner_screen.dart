import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'smart_shopping_list_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  int _selectedDayIndex = 0;
  final List<String> _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  
  // Mock veri: Hangi güne hangi tariflerin eklendiği.
  final Map<int, List<Map<String, dynamic>>> _plannedMeals = {
    0: [{'title': 'Fırında Somon', 'calories': '450 kcal', 'time': '30 dk'}],
    1: [{'title': 'Mercimek Çorbası', 'calories': '210 kcal', 'time': '40 dk'}, {'title': 'Tavuk Salata', 'calories': '320 kcal', 'time': '15 dk'}],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Haftalık Planlayıcı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SmartShoppingListScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Days List
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final isSelected = _selectedDayIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _days[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: _buildMealsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Burada tarif arama ekranına yönlendirilebilir
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu güne tarif eklemek için arama ekranına gidin.')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMealsList() {
    final meals = _plannedMeals[_selectedDayIndex] ?? [];
    
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: AppColors.onSurfaceVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'Bu güne planlanmış yemek yok.',
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.restaurant, color: AppColors.primary),
            ),
            title: Text(meal['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${meal['time']} • ${meal['calories']}'),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _plannedMeals[_selectedDayIndex]?.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}
