import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';

class ShoppingRepository extends DatabaseService {
  final String collectionPath = 'shopping_lists';
  final Box _box = Hive.box('shopping_list');

  Future<void> addShoppingItem(String userId, String itemName) async {
    try {
      final docRef = await firestore.collection(collectionPath).doc(userId).collection('items').add({
        'name': itemName,
        'isPurchased': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Save locally
      _box.put(docRef.id, {
        'id': docRef.id,
        'name': itemName,
        'isPurchased': false,
      });
    } catch (e) {
      // Offline fallback: save locally with pseudo id
      final pseudoId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _box.put(pseudoId, {
        'id': pseudoId,
        'name': itemName,
        'isPurchased': false,
        'pendingSync': true,
      });
    }
  }

  Future<void> updateItemStatus(String userId, String itemId, bool isPurchased) async {
    try {
      if (!itemId.startsWith('local_')) {
        await firestore.collection(collectionPath).doc(userId).collection('items').doc(itemId).update({
          'isPurchased': isPurchased,
        });
      }
      final item = _box.get(itemId);
      if (item != null) {
        final updatedItem = Map<String, dynamic>.from(item);
        updatedItem['isPurchased'] = isPurchased;
        _box.put(itemId, updatedItem);
      }
    } catch (e) {
      final item = _box.get(itemId);
      if (item != null) {
        final updatedItem = Map<String, dynamic>.from(item);
        updatedItem['isPurchased'] = isPurchased;
        _box.put(itemId, updatedItem);
      }
    }
  }

  Future<void> deleteItem(String userId, String itemId) async {
    try {
      if (!itemId.startsWith('local_')) {
        await firestore.collection(collectionPath).doc(userId).collection('items').doc(itemId).delete();
      }
      _box.delete(itemId);
    } catch (e) {
      _box.delete(itemId);
    }
  }

  Stream<List<Map<String, dynamic>>> getShoppingListStream(String userId) async* {
    // Initial emit from local Hive box
    final List<Map<String, dynamic>> localItems = _box.values.map((e) => Map<String, dynamic>.from(e)).toList();
    yield localItems;

    // Listen to remote changes
    yield* firestore.collection(collectionPath).doc(userId).collection('items')
        .orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      
      final remoteData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Clean timestamp for local storage
        data.remove('createdAt'); 
        _box.put(doc.id, data);
        return data;
      }).toList();

      // Find local-only items (pending sync)
      final pendingItems = _box.values
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'].toString().startsWith('local_'))
          .toList();

      return [...pendingItems, ...remoteData];
    });
  }
}
