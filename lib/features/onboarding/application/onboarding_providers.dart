import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_onboarding/pb_onboarding.dart';

import '../../../core/di/core_providers.dart';
import '../../../core/storage/key_value_store.dart';

/// Persists the onboarding flag in the app's key-value store.
class KeyValueOnboardingStore implements OnboardingCompletionStore {
  KeyValueOnboardingStore(this._store);

  static const key = 'onboarding.completed';
  final KeyValueStore _store;

  @override
  bool get isCompleted => _store.getBool(key) ?? false;

  @override
  Future<void> setCompleted(bool completed) => _store.setBool(key, completed);
}

/// Set to false in an app without an introduction; the router then never
/// redirects to onboarding.
final onboardingEnabledProvider = Provider<bool>((ref) => true);

final onboardingStoreProvider = Provider<OnboardingCompletionStore>(
  (ref) => KeyValueOnboardingStore(ref.watch(keyValueStoreProvider)),
);

/// App-wide so the router can listen to completion.
final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  final controller = OnboardingController(ref.watch(onboardingStoreProvider));
  ref.onDispose(controller.dispose);
  return controller;
});
