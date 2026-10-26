import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The preloaded [SharedPreferences] instance, overridden in `main()`.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main().'),
);
