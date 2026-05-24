import 'package:hive_flutter/hive_flutter.dart';

class OfflineRecipeService {
  static const String boxName = 'saved_recipes';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _box => Hive.box(boxName);

  static Future<void> saveRecipeConfig(Map<String, dynamic> recipe) async {
    final id = recipe['id']?.toString() ?? recipe['title'];
    await _box.put(id, recipe);
  }

  static Future<void> deleteRecipeConfig(String id) async {
    await _box.delete(id);
  }

  static List<Map<String, dynamic>> getAllSavedRecipes() {
    final List<Map<String, dynamic>> list = [];
    for (var key in _box.keys) {
      final val = _box.get(key);
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    return list;
  }

  static bool isRecipeSaved(String id) {
    return _box.containsKey(id);
  }
}
