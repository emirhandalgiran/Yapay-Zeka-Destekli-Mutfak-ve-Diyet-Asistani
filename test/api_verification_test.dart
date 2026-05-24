import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aura_cook/core/api/fatsecret_service.dart';
import 'package:aura_cook/core/api/groq_translation_service.dart';

void main() {
  group('API Verification Tests', () {
    setUpAll(() async {
      // Ensure dotenv is fully loaded before any services are referenced or instantiated
      await dotenv.load(fileName: '.env');
    });

    test('FatSecret API Autocomplete should return results', () async {
      final fatSecret = FatSecretService();
      try {
        final result = await fatSecret.autocompleteFoods(expression: 'chicken', maxResults: 3);
        debugPrint('FatSecret Response: $result');
        expect(result, isNotNull);
        expect(result.containsKey('suggestions'), isTrue);
      } catch (e) {
        fail('FatSecret API failed: $e');
      }
    });

    test('Groq Translation API should translate text', () async {
      final groq = GroqTranslationService();
      try {
        final result = await groq.translateTexts(['apple', 'banana']);
        debugPrint('Groq Response: $result');
        expect(result.length, equals(2));
        expect(result[0].toLowerCase(), contains('elma'));
      } catch (e) {
        fail('Groq API failed: $e');
      }
    });
  });
}
