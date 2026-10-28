import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/language_controller.dart';
import 'core/prefs_provider.dart';
import 'core/session_repository.dart';
import 'core/ui.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_screen.dart';
import 'features/shell/shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Localized date/time picker labels (ES + EN).
  await initializeDateFormatting();

  // Preload preferences and the persisted session before the first frame so
  // the network layer always has a valid token (or a clean signed-out state).
  final prefs = await SharedPreferences.getInstance();
  final sessionRepository = SessionRepository(prefs)..loadFromStorage();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
      ],
      child: const BuildingFexResidentApp(),
    ),
  );
}

class BuildingFexResidentApp extends ConsumerWidget {
  const BuildingFexResidentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageControllerProvider);
    return MaterialApp(
      title: 'BuildingFex Residente',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: Locale(language),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Root(),
    );
  }
}

/// Routes between the auth screen and the resident shell based on the session.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The auth controller owns the session lifecycle (login/logout), so we
    // watch it rather than the repository to react to sign-in state changes.
    final session =
        ref.watch(authControllerProvider.select((s) => s.session));
    if (session == null) return const AuthScreen();
    return const ResidentShell();
  }
}
