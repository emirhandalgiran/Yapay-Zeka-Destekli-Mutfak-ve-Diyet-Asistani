import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_preferences_provider.g.dart';

@riverpod
class UserPreferences extends _$UserPreferences {
  @override
  Map<String, dynamic> build() {
    return {
      'locale': 'tr',
      'theme': 'light',
    };
  }

  void setLocale(String languageCode) {
    state = {...state, 'locale': languageCode};
  }

  void toggleTheme() {
    final currentTheme = state['theme'] as String;
    state = {...state, 'theme': currentTheme == 'light' ? 'dark' : 'light'};
  }
}
