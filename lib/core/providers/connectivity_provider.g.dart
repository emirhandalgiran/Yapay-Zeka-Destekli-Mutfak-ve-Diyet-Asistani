// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// İnternet bağlantı durumunu periyodik olarak kontrol eder.
/// connectivity_plus paketi eklemeden, basit DNS lookup ile çalışır.

@ProviderFor(Connectivity)
final connectivityProvider = ConnectivityProvider._();

/// İnternet bağlantı durumunu periyodik olarak kontrol eder.
/// connectivity_plus paketi eklemeden, basit DNS lookup ile çalışır.
final class ConnectivityProvider extends $NotifierProvider<Connectivity, bool> {
  /// İnternet bağlantı durumunu periyodik olarak kontrol eder.
  /// connectivity_plus paketi eklemeden, basit DNS lookup ile çalışır.
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  Connectivity create() => Connectivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$connectivityHash() => r'7db4c7ab29f30634cf6794f32c5e5e1cf30f80ad';

/// İnternet bağlantı durumunu periyodik olarak kontrol eder.
/// connectivity_plus paketi eklemeden, basit DNS lookup ile çalışır.

abstract class _$Connectivity extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
