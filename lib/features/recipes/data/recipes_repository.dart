import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/database_service.dart';
import 'dart:async';

class RecipesRepository extends DatabaseService {
  final String userRecipesCollection = 'user_recipes'; 
  final Box _savedBox = Hive.box('saved_recipes');
  final Box _myRecipesBox = Hive.box('my_recipes');
  final Box _viewedBox = Hive.box('viewed_recipes');

  // Kendi oluşturduğu tarifi ekleme
  Future<void> addCustomRecipe(String userId, Map<String, dynamic> recipeData) async {
    recipeData['authorId'] = userId;
    final localDateStr = DateTime.now().toIso8601String();
    
    try {
      recipeData['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await firestore.collection(userRecipesCollection).doc(userId).collection('created').add(recipeData);
      
      // Save locally
      recipeData['id'] = docRef.id;
      recipeData['createdAt'] = localDateStr;
      _myRecipesBox.put(docRef.id, recipeData);
    } catch (e) {
      // Offline fallback
      final pseudoId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      recipeData['id'] = pseudoId;
      recipeData['createdAt'] = localDateStr;
      recipeData['pendingSync'] = true;
      _myRecipesBox.put(pseudoId, recipeData);
    }
  }

  // Oluşturduğu tarifleri getirme
  Stream<List<Map<String, dynamic>>> getCustomRecipesStream(String userId) async* {
    // Initial emit from local
    final List<Map<String, dynamic>> localItems = _myRecipesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    localItems.sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
    yield localItems;

    // Stream from Remote
    yield* firestore.collection(userRecipesCollection).doc(userId).collection('created')
        .orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      
      final remoteData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        _myRecipesBox.put(doc.id, data);
        return data;
      }).toList();

      final pendingItems = _myRecipesBox.values
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'].toString().startsWith('local_'))
          .toList();

      final combined = [...pendingItems, ...remoteData];
      combined.sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
      return combined;
    });
  }

  // Başka tarifi kaydetme/favoriye alma
  Future<void> saveRecipe(String userId, Map<String, dynamic> recipeData) async {
    final String docId = recipeData['id']?.toString() ?? recipeData['title'].toString().replaceAll(' ', '_');
    final localDateStr = DateTime.now().toIso8601String();
    
    try {
      recipeData['savedAt'] = FieldValue.serverTimestamp();
      await firestore.collection(userRecipesCollection).doc(userId).collection('saved').doc(docId).set(recipeData);
      
      // Save locally
      recipeData['savedAt'] = localDateStr;
      _savedBox.put(docId, recipeData);
    } catch (e) {
      // Offline fallback
      recipeData['savedAt'] = localDateStr;
      recipeData['pendingSync'] = true;
      _savedBox.put(docId, recipeData);
    }
  }
  
  // Favorilerden çıkarma
  Future<void> removeSavedRecipe(String userId, String recipeId) async {
    try {
      await firestore.collection(userRecipesCollection).doc(userId).collection('saved').doc(recipeId).delete();
      _savedBox.delete(recipeId);
    } catch (e) {
      _savedBox.delete(recipeId);
    }
  }

  // Kaydettiği tarifleri getirme
  Stream<List<Map<String, dynamic>>> getSavedRecipesStream(String userId) async* {
    // Initial emit from local
    final List<Map<String, dynamic>> localItems = _savedBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    localItems.sort((a, b) => (b['savedAt']?.toString() ?? '').compareTo(a['savedAt']?.toString() ?? ''));
    yield localItems;

    // Stream from Remote
    yield* firestore.collection(userRecipesCollection).doc(userId).collection('saved')
        .orderBy('savedAt', descending: true).snapshots().map((snapshot) {
      
      final remoteData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['savedAt'] is Timestamp) {
            data['savedAt'] = (data['savedAt'] as Timestamp).toDate().toIso8601String();
        }
        _savedBox.put(doc.id, data);
        return data;
      }).toList();

      final pendingItems = _savedBox.values
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'].toString().startsWith('local_'))
          .toList();

      // Find deleted remote items
      final remoteIds = remoteData.map((e) => e['id']).toSet();
      final localIds = _savedBox.keys;
      for (var id in localIds) {
        if (!id.toString().startsWith('local_') && !remoteIds.contains(id)) {
          _savedBox.delete(id);
        }
      }

      final combined = [...pendingItems, ...remoteData];
      combined.sort((a, b) => (b['savedAt']?.toString() ?? '').compareTo(a['savedAt']?.toString() ?? ''));
      return combined;
    });
  }

  // Tarife bakıldığında geçmişe ekle
  Future<void> saveToHistory(String userId, Map<String, dynamic> recipeData) async {
    final String docId = recipeData['id']?.toString() ?? recipeData['title'].toString().replaceAll(' ', '_');
    final Map<String, dynamic> dataToSave = Map<String, dynamic>.from(recipeData);
    final localDateStr = DateTime.now().toIso8601String();
    
    try {
      dataToSave['viewedAt'] = FieldValue.serverTimestamp();
      await firestore.collection(userRecipesCollection).doc(userId).collection('history').doc(docId).set(dataToSave);
      
      // Save locally
      dataToSave['viewedAt'] = localDateStr;
      _viewedBox.put(docId, dataToSave);
    } catch (e) {
      // Offline fallback
      dataToSave['viewedAt'] = localDateStr;
      dataToSave['pendingSync'] = true;
      _viewedBox.put(docId, dataToSave);
    }
  }

  // Geçmiş tarifleri getirme
  Stream<List<Map<String, dynamic>>> getHistoryRecipesStream(String userId) async* {
    final List<Map<String, dynamic>> localItems = _viewedBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    localItems.sort((a, b) => (b['viewedAt']?.toString() ?? '').compareTo(a['viewedAt']?.toString() ?? ''));
    yield localItems;

    yield* firestore.collection(userRecipesCollection).doc(userId).collection('history')
        .orderBy('viewedAt', descending: true).snapshots().map((snapshot) {
      
      final remoteData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['viewedAt'] is Timestamp) {
            data['viewedAt'] = (data['viewedAt'] as Timestamp).toDate().toIso8601String();
        }
        _viewedBox.put(doc.id, data);
        return data;
      }).toList();

      return remoteData;
    });
  }

  // Tüm tarifleri (Favoriler + Geçmiş) getirme
  Stream<List<Map<String, dynamic>>> getAllRecipesStream(String userId) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    List<Map<String, dynamic>> saved = [];
    List<Map<String, dynamic>> history = [];

    void emitCombined() {
      // Merge unique by id
      final Map<String, Map<String, dynamic>> combined = {};
      for (var item in history) {
        combined[item['id'].toString()] = item;
      }
      for (var item in saved) {
        combined[item['id'].toString()] = item;
      }
      
      if (!controller.isClosed) {
        final list = combined.values.toList();
        list.sort((a, b) {
          final aDate = a['viewedAt'] ?? a['savedAt'] ?? a['createdAt'] ?? '';
          final bDate = b['viewedAt'] ?? b['savedAt'] ?? b['createdAt'] ?? '';
          return bDate.toString().compareTo(aDate.toString());
        });
        controller.add(list);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        sub1 = getSavedRecipesStream(userId).listen((data) {
          saved = data;
          emitCombined();
        });
        sub2 = getHistoryRecipesStream(userId).listen((data) {
          history = data;
          emitCombined();
        });
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }
}
