import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// İnternet bağlantı durumunu periyodik olarak kontrol eder.
/// connectivity_plus paketi eklemeden, basit DNS lookup ile çalışır.
@riverpod
class Connectivity extends _$Connectivity {
  Timer? _timer;

  @override
  bool build() {
    // Başlangıçta bağlı kabul et, arka planda periyodik kontrol yap
    _startPeriodicCheck();
    ref.onDispose(() => _timer?.cancel());
    return true;
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final isOnline = await _checkConnection();
      if (state != isOnline) {
        state = isOnline;
      }
    });
    // İlk kontrolü hemen yap
    _checkConnection().then((isOnline) {
      if (state != isOnline) {
        state = isOnline;
      }
    });
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Manuel olarak bağlantıyı kontrol ettirmek için.
  Future<void> refresh() async {
    final isOnline = await _checkConnection();
    state = isOnline;
  }
}
