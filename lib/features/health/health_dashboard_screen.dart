import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  // Mock Data: Günlük hedefler ve alınanlar
  final int _targetCalories = 2200;
  final int _currentCalories = 1450;

  final Map<String, Map<String, dynamic>> _macros = {
    'Protein': {'current': 90, 'target': 150, 'color': Colors.redAccent, 'unit': 'g'},
    'Karbonhidrat': {'current': 180, 'target': 250, 'color': Colors.orangeAccent, 'unit': 'g'},
    'Yağ': {'current': 45, 'target': 70, 'color': Colors.blueAccent, 'unit': 'g'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Sağlık ve Beslenme', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünkü Tüketim',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
            const SizedBox(height: 24),
            
            // Circular Calorie Indicator
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _currentCalories / _targetCalories,
                      strokeWidth: 16,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      color: AppColors.primary,
                      strokeCap: StrokeCap.round,
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_currentCalories',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      Text(
                        '/ $_targetCalories kcal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Macros Linear Indicators
            Text(
              'Makro Dağılımı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),
            ..._macros.entries.map((entry) {
              final val = entry.value;
              final double ratio = val['current'] / val['target'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                        ),
                        Text(
                          '${val['current']} / ${val['target']} ${val['unit']}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 12,
                        backgroundColor: val['color'].withValues(alpha: 0.2),
                        color: val['color'],
                      ),
                    ).animate().slideX(duration: 800.ms, begin: -1, end: 0, curve: Curves.easeOutQuint),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 24),
            // "Bugün Yediklerim" list mockup
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bugün Yenilenler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.restaurant_menu, color: AppColors.primary),
                    title: const Text('Mercimek Çorbası', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Text('210 kcal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.restaurant_menu, color: AppColors.primary),
                    title: const Text('Fırında Somon', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Text('450 kcal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
