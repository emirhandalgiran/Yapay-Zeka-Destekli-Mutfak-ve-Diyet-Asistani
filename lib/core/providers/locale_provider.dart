import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../di/service_locator.dart';

final localeProvider = NotifierProvider<LocaleNotifier, String>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    _loadLocale();
    return 'tr'; // Varsayılan dil Türkçe
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? localLang = prefs.getString('app_language');

    // Eğer local kayıt yoksa, cihaz diline bak veya kullanıcı firestore'una bak
    if (localLang == null) {
      final user = ServiceLocator.auth.currentUser;
      if (user != null) {
        final profile = await ServiceLocator.profile.getUserProfile(user.uid);
        if (profile != null && profile['language'] != null) {
          localLang = profile['language'];
        }
      }
    }

    // Hala null ise cihaz dilini kontrol edebiliriz
    if (localLang == null) {
      final deviceLocale = PlatformDispatcher.instance.locale;
      localLang = deviceLocale.languageCode == 'en' ? 'en' : 'tr';
    }

    state = localLang;
    
    // Kaydet
    final prefsInstance = await SharedPreferences.getInstance();
    await prefsInstance.setString('app_language', localLang);
  }

  Future<void> setLocale(String lang) async {
    if (lang != 'tr' && lang != 'en') return;
    
    state = lang;

    // Local preferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);

    // Firebase'e kaydet (eğer giriş yapıldıysa)
    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      await ServiceLocator.profile.updateUserProfile(user.uid, {'language': lang});
    }
  }

  Future<void> syncWithFirebase(String firebaseLang) async {
    if (firebaseLang == 'tr' || firebaseLang == 'en') {
      if (state != firebaseLang) {
        state = firebaseLang;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_language', firebaseLang);
      }
    }
  }
}
