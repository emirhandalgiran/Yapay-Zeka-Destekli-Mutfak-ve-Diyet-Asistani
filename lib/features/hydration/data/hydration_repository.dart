import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';

class HydrationRepository extends DatabaseService {
  final String collectionPath = 'hydration_logs';

  // Log water intake
  Future<void> logWaterIntake(String userId, int amountMl, DateTime date) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final docPath = '$collectionPath/${userId}_$dateString';
    
    final doc = await getDocument(path: docPath);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    final logEntry = {
      'time': timeStr,
      'ml': amountMl,
      'iconCode': Icons.water_drop_outlined.codePoint,
    };

    if (doc.exists) {
      final currentAmount = doc.data()?['amountMl'] ?? 0;
      await updateDocument(
        path: docPath, 
        data: {
          'amountMl': currentAmount + amountMl,
          'lastUpdated': FieldValue.serverTimestamp(),
          'logs': FieldValue.arrayUnion([logEntry]),
        }
      );
    } else {
      await setDocument(
        path: docPath, 
        data: {
          'userId': userId,
          'date': dateString,
          'amountMl': amountMl,
          'logs': [logEntry],
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      );
    }
  }

  // Get daily hydration stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDailyHydration(String userId, DateTime date) {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return documentStream(path: '$collectionPath/${userId}_$dateString');
  }

  // Get hydration history
  Stream<QuerySnapshot<Map<String, dynamic>>> getHydrationHistory(String userId) {
    return collectionStream(
      path: collectionPath,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId).orderBy('date', descending: true),
    );
  }
}
