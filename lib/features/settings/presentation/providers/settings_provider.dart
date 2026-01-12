import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/constants/app_constants.dart';

/// Settings state
class SettingsState {
  final ThemeMode themeMode;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.isLoading = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Settings notifier for managing app settings
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  /// Load settings from Hive
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    final box = HiveService.settingsBox;
    final themeModeIndex = box.get(AppConstants.themeKey, defaultValue: 0) as int;

    state = SettingsState(
      themeMode: ThemeMode.values[themeModeIndex],
      isLoading: false,
    );
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await HiveService.settingsBox.put(AppConstants.themeKey, mode.index);
  }

  /// Clear all app data
  Future<void> clearAllData() async {
    state = state.copyWith(isLoading: true);
    await HiveService.clearAll();
    state = state.copyWith(isLoading: false);
  }
}

/// Provider for settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Convenience provider for theme mode (used by MaterialApp)
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

