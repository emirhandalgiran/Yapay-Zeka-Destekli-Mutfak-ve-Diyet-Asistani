import '../../features/hydration/data/hydration_repository.dart';
import '../../features/calorie_calculator/data/calorie_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/social/data/social_repository.dart';
import '../../features/planner/data/shopping_repository.dart';
import '../../features/recipes/data/recipes_repository.dart';
import '../api/fatsecret_service.dart';
import '../api/groq_translation_service.dart';
import '../api/groq_chat_service.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/gamification/data/gamification_service.dart';
import '../database/offline_sync_service.dart';

/// Basit bir Service Locator (Dependency Injection alternatifi).
/// Projede herhangi bir paket kullanılmadığından global erişim için tasarlandı.
class ServiceLocator {
  ServiceLocator._();

  static final AuthRepository auth = AuthRepository();
  static final ProfileRepository profile = ProfileRepository();
  static final HydrationRepository hydration = HydrationRepository();
  static final CalorieRepository calorie = CalorieRepository();
  static final SocialRepository social = SocialRepository();
  static final ShoppingRepository shopping = ShoppingRepository();
  static final RecipesRepository recipes = RecipesRepository();
  static final FatSecretService fatSecret = FatSecretService();
  static final NotificationsRepository notifications = NotificationsRepository();
  static final GroqTranslationService groqTranslation = GroqTranslationService();
  static final GamificationService gamification = GamificationService();
  static final GroqChatService groqChat = GroqChatService();
  static final OfflineSyncService offlineSync = OfflineSyncService();
}
