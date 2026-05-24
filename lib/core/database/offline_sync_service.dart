import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Offline-First veri katmanı.
/// Firestore'dan gelen tarifleri / profilleri Hive'a cache'ler.
/// İnternet olmadığında Hive'dan okur (Stale-While-Revalidate).
class OfflineSyncService {
  static const String _recipeCacheBox = 'recipe_cache';
  static const String _profileCacheBox = 'profile_cache';
  static const String _feedCacheBox = 'feed_cache';

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'projeodevdb');

  /// Tüm offline kutuları başlatır.
  static Future<void> init() async {
    await Hive.openBox(_recipeCacheBox);
    await Hive.openBox(_profileCacheBox);
    await Hive.openBox(_feedCacheBox);
  }

  // ───────────── Feed (Social Posts) Cache ─────────────

  /// Social feed'i cache'e kaydeder.
  Future<void> cacheFeedPosts(List<Map<String, dynamic>> posts) async {
    try {
      final box = Hive.box(_feedCacheBox);
      await box.put('feed_posts', jsonEncode(posts));
      await box.put('feed_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('OfflineSync: Feed cache yazma hatası: $e');
    }
  }

  /// Cache'deki feed postlarını okur.
  List<Map<String, dynamic>> getCachedFeedPosts() {
    try {
      final box = Hive.box(_feedCacheBox);
      final raw = box.get('feed_posts');
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw as String);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('OfflineSync: Feed cache okuma hatası: $e');
      return [];
    }
  }

  /// Feed cache'inin tazeliğini kontrol eder (5 dakika).
  bool isFeedCacheFresh() {
    try {
      final box = Hive.box(_feedCacheBox);
      final ts = box.get('feed_timestamp') as int?;
      if (ts == null) return false;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      return age < 5 * 60 * 1000; // 5 dakika
    } catch (_) {
      return false;
    }
  }

  // ───────────── Profil Cache ─────────────

  /// Kullanıcı profilini cache'e yazar.
  Future<void> cacheUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      final box = Hive.box(_profileCacheBox);
      await box.put('profile_$userId', jsonEncode(data));
    } catch (e) {
      debugPrint('OfflineSync: Profil cache yazma hatası: $e');
    }
  }

  /// Kullanıcı profilini cache'den okur.
  Map<String, dynamic>? getCachedUserProfile(String userId) {
    try {
      final box = Hive.box(_profileCacheBox);
      final raw = box.get('profile_$userId');
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw as String));
    } catch (e) {
      debugPrint('OfflineSync: Profil cache okuma hatası: $e');
      return null;
    }
  }

  // ───────────── Tarif Cache ─────────────

  /// Kayıtlı tarifleri Hive'a yazar.
  Future<void> cacheSavedRecipes(
      String userId, List<Map<String, dynamic>> recipes) async {
    try {
      final box = Hive.box(_recipeCacheBox);
      await box.put('saved_$userId', jsonEncode(recipes));
    } catch (e) {
      debugPrint('OfflineSync: Tarif cache yazma hatası: $e');
    }
  }

  /// Kayıtlı tarifleri cache'den okur.
  List<Map<String, dynamic>> getCachedSavedRecipes(String userId) {
    try {
      final box = Hive.box(_recipeCacheBox);
      final raw = box.get('saved_$userId');
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw as String);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('OfflineSync: Tarif cache okuma hatası: $e');
      return [];
    }
  }

  // ───────────── My Recipes Cache ─────────────

  /// Kullanıcının kendi tariflerini cache'ler.
  Future<void> cacheMyRecipes(List<Map<String, dynamic>> recipes) async {
    try {
      final box = Hive.box(_recipeCacheBox);
      await box.put('my_recipes', jsonEncode(recipes));
    } catch (e) {
      debugPrint('OfflineSync: My recipes cache yazma hatası: $e');
    }
  }

  /// Kullanıcının kendi tariflerini cache'den okur.
  List<Map<String, dynamic>> getCachedMyRecipes() {
    try {
      final box = Hive.box(_recipeCacheBox);
      final raw = box.get('my_recipes');
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw as String);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('OfflineSync: My recipes cache okuma hatası: $e');
      return [];
    }
  }

  // ───────────── Genel ─────────────

  /// Tüm cache'i temizler.
  Future<void> clearAll() async {
    try {
      await Hive.box(_recipeCacheBox).clear();
      await Hive.box(_profileCacheBox).clear();
      await Hive.box(_feedCacheBox).clear();
    } catch (e) {
      debugPrint('OfflineSync: Cache temizleme hatası: $e');
    }
  }

  /// Firestore'dan social_posts'ları çekip cache'e yazar (arka plan senkronizasyonu).
  Future<void> syncFeedToCache() async {
    try {
      final snapshot = await _firestore
          .collection('social_posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        // Timestamp'i String'e dönüştür (JSON serialization için)
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        data['docId'] = doc.id;
        return data;
      }).toList();

      await cacheFeedPosts(posts);
      debugPrint('OfflineSync: ${posts.length} post cache\'e yazıldı.');
    } catch (e) {
      debugPrint('OfflineSync: Feed senkronizasyonu başarısız: $e');
    }
  }
}
