import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/providers/locale_provider.dart';

class AllergyEditBottomSheet extends ConsumerStatefulWidget {
  final List<String> currentAllergies;

  const AllergyEditBottomSheet({super.key, required this.currentAllergies});

  @override
  ConsumerState<AllergyEditBottomSheet> createState() => _AllergyEditBottomSheetState();
}

class _AllergyEditBottomSheetState extends ConsumerState<AllergyEditBottomSheet> {
  late List<String> _allergies;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allergies = List.from(widget.currentAllergies);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAllergy() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _controller.clear();
      });
    }
  }

  void _removeAllergy(String item) {
    setState(() {
      _allergies.remove(item);
    });
  }

  Future<void> _save() async {
    final userId = ServiceLocator.auth.currentUser?.uid;
    if (userId != null) {
      await ServiceLocator.profile.updateUserProfile(userId, {
        'kitchenPreferences.allergies': _allergies,
      });
    }
    if (mounted) {
      Navigator.pop(context, _allergies);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = ref.watch(localeProvider) == 'tr';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTr ? 'Alerjileri Düzenle' : 'Edit Allergies',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _addAllergy(),
                  decoration: InputDecoration(
                    hintText: isTr ? 'Alerjen ekle (örn: Fıstık, Süt)' : 'Add allergen (e.g. Peanut, Milk)',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addAllergy,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.add, color: AppColors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies.map((item) {
              return Chip(
                label: Text(
                  item,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.surfaceContainerHigh,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeAllergy(item),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.black.withValues(alpha: 0.05)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isTr ? 'KAYDET' : 'SAVE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
