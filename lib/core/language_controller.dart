import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n.dart';
import 'prefs_provider.dart';

const _langKey = 'bf.app.language';

/// Holds the active app language (`es` / `en`) and keeps [AppTexts.lang] in
/// sync. Persisted so the choice survives restarts.
class LanguageController extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(prefsProvider);
    final saved = prefs.getString(_langKey);
    final initial = saved == 'en' ? 'en' : 'es';
    AppTexts.setLang(initial);
    return initial;
  }

  void toggle() => setLanguage(state == 'es' ? 'en' : 'es');

  void setLanguage(String code) {
    final normalized = code == 'en' ? 'en' : 'es';
    AppTexts.setLang(normalized);
    state = normalized;
    ref.read(prefsProvider).setString(_langKey, normalized);
  }
}

final languageControllerProvider = NotifierProvider<LanguageController, String>(
  LanguageController.new,
);
