import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/database/database_service.dart';

class CalorieRepository extends DatabaseService {
  final String collectionPath = 'calorie_logs';

  // Log an individual meal
  Future<void> logMeal(String userId, DateTime date, Map<String, dynamic> mealData) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final docPath = '$collectionPath/${userId}_$dateString';
    
    final doc = await getDocument(path: docPath);
    final foodCalories = mealData['calories'] as int? ?? 0;

    if (doc.exists) {
      final currentCals = doc.data()?['usedCalories'] ?? 0;
      await updateDocument(
        path: docPath, 
        data: {
          'usedCalories': currentCals + foodCalories,
          'lastUpdated': FieldValue.serverTimestamp(),
          'meals': FieldValue.arrayUnion([mealData]),
        }
      );
    } else {
      await setDocument(
        path: docPath, 
        data: {
          'userId': userId,
          'date': dateString,
          'usedCalories': foodCalories,
          'meals': [mealData],
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      );
    }
  }

  // Set macro goals
  Future<void> setMacroGoals(String userId, DateTime date, Map<String, dynamic> goals) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final docPath = '$collectionPath/${userId}_$dateString';
    
    await setDocument(
      path: docPath, 
      data: {
        'userId': userId,
        'date': dateString,
        'goals': goals,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  // Get daily macros
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDailyMacros(String userId, DateTime date) {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return documentStream(path: '$collectionPath/${userId}_$dateString');
  }

  // Get macro history
  Stream<QuerySnapshot<Map<String, dynamic>>> getMacroHistory(String userId) {
    return collectionStream(
      path: collectionPath,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId).orderBy('date', descending: true),
    );
  }
}
