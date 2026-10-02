import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言偏好：跟随系统 / 中文 / 英文。
///
/// 默认「跟随系统」，用户可在设置中手动固定，偏好持久化到
/// `shared_preferences`（键 `locale_preference`）。
enum LocalePreference {
  system('system', null),
  zh('zh', 'zh'),
  en('en', 'en');

  const LocalePreference(this.storageKey, this.languageCode);

  /// 持久化键值。
  final String storageKey;

  /// 语言代码；跟随系统时为 null。
  final String? languageCode;

  /// 对应的 [Locale]；跟随系统返回 null。
  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  static LocalePreference fromStorage(String? key) =>
      LocalePreference.values.firstWhere(
        (p) => p.storageKey == key,
        orElse: () => LocalePreference.system,
      );
}

/// 语言偏好的持久化读写。
class LocalePreferenceStore {
  static const _key = 'locale_preference';

  static Future<LocalePreference> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalePreference.fromStorage(prefs.getString(_key));
  }

  static Future<void> save(LocalePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preference.storageKey);
  }
}

/// 当前应用 locale（null 表示跟随系统）。
///
/// 启动时异步读取偏好并更新；设置中切换时同步更新 + 持久化。
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final pref = await LocalePreferenceStore.load();
    if (pref.locale != state) {
      state = pref.locale;
    }
  }

  Future<void> setPreference(LocalePreference preference) async {
    state = preference.locale;
    await LocalePreferenceStore.save(preference);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
