import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'projeodevdb');

  // ───────────── Rozet Sistemi ─────────────
  static const Map<String, Map<String, String>> badgeData = {
    'ilk_adim': {'title': 'Mutfak Çırağı', 'desc': 'AuraCook dünyasına ilk adımını attın!', 'icon': '🎯'},
    'ilk_tarif': {'title': 'Tarif Kaşifi', 'desc': 'İlk tarifini toplulukla paylaştın.', 'icon': '🍳'},
    'usta_sef': {'title': 'Usta Şef', 'desc': '10 farklı tarif paylaşarak ustalığını kanıtladın.', 'icon': '👨‍🍳'},
    'sosyete_sefi': {'title': 'Sosyete Şefi', 'desc': 'Toplulukla etkileşime girip 10 yorum yaptın.', 'icon': '💬'},
    'populer_sef': {'title': 'Popüler Şef', 'desc': '10 takipçiye ulaştın, tariflerin çok seviliyor!', 'icon': '🌟'},
    'aura_asistani': {'title': 'Aura Ustası', 'desc': 'Aura AI ile yaratıcı tarifler oluşturdun.', 'icon': '🤖'},
    'su_ustasi': {'title': 'Su Ustası', 'desc': '7 gün üst üste su hedefini tamamladın!', 'icon': '💧'},
    'streak_3': {'title': 'Kararlı Şef', 'desc': '3 gün üst üste giriş yaptın.', 'icon': '🔥'},
    'streak_7': {'title': 'Azimli Şef', 'desc': '7 gün üst üste giriş yaptın!', 'icon': '⚡'},
  };

  static String getBadgeTitle(String badgeId, bool isTr) {
    switch (badgeId) {
      case 'ilk_adim': return isTr ? 'Mutfak Çırağı' : 'Kitchen Apprentice';
      case 'ilk_tarif': return isTr ? 'Tarif Kaşifi' : 'Recipe Explorer';
      case 'usta_sef': return isTr ? 'Usta Şef' : 'Master Chef';
      case 'sosyete_sefi': return isTr ? 'Sosyete Şefi' : 'Socialite Chef';
      case 'populer_sef': return isTr ? 'Popüler Şef' : 'Popular Chef';
      case 'aura_asistani': return isTr ? 'Aura Ustası' : 'Aura Master';
      case 'su_ustasi': return isTr ? 'Su Ustası' : 'Water Master';
      case 'streak_3': return isTr ? 'Kararlı Şef' : 'Determined Chef';
      case 'streak_7': return isTr ? 'Azimli Şef' : 'Persistent Chef';
      default: return isTr ? 'Bilinmeyen Rozet' : 'Unknown Badge';
    }
  }

  static String getBadgeDesc(String badgeId, bool isTr) {
    switch (badgeId) {
      case 'ilk_adim': return isTr ? 'AuraCook dünyasına ilk adımını attın!' : 'You took your first step into the AuraCook world!';
      case 'ilk_tarif': return isTr ? 'İlk tarifini toplulukla paylaştın.' : 'You shared your first recipe with the community.';
      case 'usta_sef': return isTr ? '10 farklı tarif paylaşarak ustalığını kanıtladın.' : 'You proved your mastery by sharing 10 different recipes.';
      case 'sosyete_sefi': return isTr ? 'Toplulukla etkileşime girip 10 yorum yaptın.' : 'You interacted with the community and made 10 comments.';
      case 'populer_sef': return isTr ? '10 takipçiye ulaştın, tariflerin çok seviliyor!' : 'You reached 10 followers, your recipes are loved!';
      case 'aura_asistani': return isTr ? 'Aura AI ile yaratıcı tarifler oluşturdun.' : 'You created creative recipes with Aura AI.';
      case 'su_ustasi': return isTr ? '7 gün üst üste su hedefini tamamladın!' : 'You completed your water goal 7 days in a row!';
      case 'streak_3': return isTr ? '3 gün üst üste giriş yaptın.' : 'You logged in 3 days in a row.';
      case 'streak_7': return isTr ? '7 gün üst üste giriş yaptın!' : 'You logged in 7 days in a row!';
      default: return '';
    }
  }

  Future<void> awardBadge(String userId, String badgeId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final doc = await userRef.get();
    
    List<String> currentBadges = [];
    if (doc.exists && doc.data()!.containsKey('badges')) {
      currentBadges = List<String>.from(doc.data()!['badges']);
    }

    if (!currentBadges.contains(badgeId)) {
      currentBadges.add(badgeId);
      await userRef.set({'badges': currentBadges}, SetOptions(merge: true));
    }
  }

  Future<void> incrementAction(String userId, String actionField) async {
    if (userId.isEmpty) return;
    final userRef = _firestore.collection('users').doc(userId);
    
    await userRef.set({actionField: FieldValue.increment(1)}, SetOptions(merge: true));

    final doc = await userRef.get();
    if (doc.exists) {
      final int count = doc.data()![actionField] ?? 0;
      
      switch (actionField) {
        case 'commentsCount':
          if (count >= 10) await awardBadge(userId, 'sosyete_sefi');
          break;
        case 'recipesPostedCount':
          if (count >= 1) await awardBadge(userId, 'ilk_tarif');
          if (count >= 10) await awardBadge(userId, 'usta_sef');
          break;
        case 'followersCount':
          if (count >= 10) await awardBadge(userId, 'populer_sef');
          break;
        case 'aiUsesCount':
          if (count >= 5) await awardBadge(userId, 'aura_asistani');
          break;
      }
    }
  }

  Stream<List<String>> getUserBadges(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data()!.containsKey('badges')) {
        return List<String>.from(doc.data()!['badges']);
      }
      return [];
    });
  }

  // ───────────── Liderlik Tablosu ─────────────

  /// Belirli bir alana göre en iyi kullanıcıları çeker.
  /// [field] = 'recipesPostedCount', 'followersCount', 'commentsCount' vb.
  Stream<List<Map<String, dynamic>>> getLeaderboard(String field, {int limit = 20}) {
    return _firestore
        .collection('users')
        .orderBy(field, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] ?? data['name'] ?? 'Anonim Şef',
          'photoURL': data['photoURL'] ?? data['photoUrl'] ?? '',
          'score': data[field] ?? 0,
          'badges': List<String>.from(data['badges'] ?? []),
        };
      }).toList();
    });
  }

  // ───────────── Günlük Görevler (Quests) ─────────────

  /// Varsayılan günlük görevleri döndürür.
  static List<Map<String, dynamic>> getDailyQuests() {
    return [
      {
        'id': 'quest_water',
        'title': 'Su hedefinin %50\'sine ulaş',
        'description': 'Günlük su hedefinin en az yarısını tamamla.',
        'icon': '💧',
        'xp': 10,
        'field': 'dailyWaterIntake',
        'type': 'percentage', // percentage / count
        'targetPercent': 50,
      },
      {
        'id': 'quest_recipe_view',
        'title': 'Bir tarif incele',
        'description': 'Topluluktan bir tarifin detaylarına bak.',
        'icon': '📖',
        'xp': 5,
        'field': 'dailyRecipeViews',
        'type': 'count',
        'target': 1,
      },
      {
        'id': 'quest_share',
        'title': 'Bir tarif paylaş',
        'description': 'Toplulukla yeni bir tarif paylaş.',
        'icon': '🍳',
        'xp': 25,
        'field': 'dailyRecipesShared',
        'type': 'count',
        'target': 1,
      },
      {
        'id': 'quest_comment',
        'title': 'Bir yorum yap',
        'description': 'Bir tarifin altına yorum bırak.',
        'icon': '💬',
        'xp': 10,
        'field': 'dailyComments',
        'type': 'count',
        'target': 1,
      },
      {
        'id': 'quest_ai_chat',
        'title': 'Aura Şef ile sohbet et',
        'description': 'AI mutfak asistanına bir soru sor.',
        'icon': '🤖',
        'xp': 10,
        'field': 'dailyAiChats',
        'type': 'count',
        'target': 1,
      },
    ];
  }

  /// Günlük streak bilgisini günceller.
  Future<void> recordDailyLogin(String userId) async {
    if (userId.isEmpty) return;
    final userRef = _firestore.collection('users').doc(userId);
    final doc = await userRef.get();

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (doc.exists) {
      final data = doc.data()!;
      final lastLogin = data['lastLoginDate'] as String? ?? '';
      int currentStreak = data['loginStreak'] as int? ?? 0;

      if (lastLogin == todayStr) return; // Bugün zaten giriş yapılmış

      // Dünkü tarihi hesapla
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      if (lastLogin == yesterdayStr) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }

      await userRef.set({
        'lastLoginDate': todayStr,
        'loginStreak': currentStreak,
        // Günlük sayaçları sıfırla
        'dailyRecipeViews': 0,
        'dailyRecipesShared': 0,
        'dailyComments': 0,
        'dailyAiChats': 0,
      }, SetOptions(merge: true));

      // Streak rozetleri
      if (currentStreak >= 3) await awardBadge(userId, 'streak_3');
      if (currentStreak >= 7) await awardBadge(userId, 'streak_7');
    } else {
      await userRef.set({
        'lastLoginDate': todayStr,
        'loginStreak': 1,
        'dailyRecipeViews': 0,
        'dailyRecipesShared': 0,
        'dailyComments': 0,
        'dailyAiChats': 0,
      }, SetOptions(merge: true));
    }
  }

  /// Günlük görev ilerlemesini arttırır.
  Future<void> incrementDailyQuest(String userId, String field, {int amount = 1}) async {
    if (userId.isEmpty) return;
    final userRef = _firestore.collection('users').doc(userId);
    await userRef.set({field: FieldValue.increment(amount)}, SetOptions(merge: true));
  }

  /// Kullanıcının günlük görev ilerlemesini stream olarak döndürür.
  Stream<Map<String, dynamic>> getUserQuestProgress(String userId) {
    if (userId.isEmpty) return Stream.value({});
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data()!;
      return {
        'dailyWaterIntake': data['dailyWaterIntake'] ?? 0,
        'waterGoalMl': data['waterGoalMl'] ?? 2500,
        'dailyRecipeViews': data['dailyRecipeViews'] ?? 0,
        'dailyRecipesShared': data['dailyRecipesShared'] ?? 0,
        'dailyComments': data['dailyComments'] ?? 0,
        'dailyAiChats': data['dailyAiChats'] ?? 0,
        'loginStreak': data['loginStreak'] ?? 0,
      };
    });
  }
}
