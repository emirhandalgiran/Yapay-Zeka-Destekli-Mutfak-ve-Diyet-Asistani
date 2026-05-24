import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../di/service_locator.dart';

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Initial state is false, but we load from preferences asynchronously
    _loadTheme();
    return false;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Use saved local preference, default to false
    final isDark = prefs.getBool('isDarkMode') ?? false;
    AppColors.isDarkMode = isDark;
    state = isDark;
  }

  Future<void> toggleTheme(bool isDark) async {
    // Update local state
    AppColors.isDarkMode = isDark;
    state = isDark;
    
    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);

    // Save to Firestore if user is logged in
    final user = ServiceLocator.auth.currentUser;
    if (user != null) {
      await ServiceLocator.profile.updateUserProfile(
          user.uid, {'darkModeEnabled': isDark});
    }
  }

  Future<void> syncWithFirebase(bool firebaseIsDark) async {
    if (state != firebaseIsDark) {
      AppColors.isDarkMode = firebaseIsDark;
      state = firebaseIsDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', firebaseIsDark);
    }
  }
}
