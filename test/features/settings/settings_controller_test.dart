import 'package:flutter/material.dart';
import 'package:flutter_project_base/core/storage/key_value_store.dart';
import 'package:flutter_project_base/features/settings/application/settings_controller.dart';
import 'package:flutter_project_base/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  test('defaults to system theme and device locale', () {
    final container = createTestContainer();
    final settings = container.read(settingsControllerProvider);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.locale, isNull);
  });

  test('persists theme and locale and restores them on restart', () async {
    final store = InMemoryKeyValueStore();
    final first = createTestContainer(keyValueStore: store);
    final controller = first.read(settingsControllerProvider.notifier);
    await controller.setThemeMode(ThemeMode.dark);
    await controller.setLocale(const Locale('vi'));

    expect(store.getString(SettingsRepository.themeModeKey), 'dark');
    expect(store.getString(SettingsRepository.localeKey), 'vi');

    final second = createTestContainer(keyValueStore: store);
    final restored = second.read(settingsControllerProvider);
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.locale, const Locale('vi'));
  });

  test('clearing locale follows the device again', () async {
    final store = InMemoryKeyValueStore({SettingsRepository.localeKey: 'vi'});
    final container = createTestContainer(keyValueStore: store);
    await container.read(settingsControllerProvider.notifier).setLocale(null);
    expect(container.read(settingsControllerProvider).locale, isNull);
    expect(store.getString(SettingsRepository.localeKey), isNull);
  });

  test('ignores unknown stored values', () {
    final store = InMemoryKeyValueStore({
      SettingsRepository.themeModeKey: 'neon',
      SettingsRepository.localeKey: 'xx',
    });
    final settings = SettingsRepository(store).load();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.locale, isNull);
  });
}
