import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'session_repository.dart';
import '../features/dashboard/dashboard_repository.dart';
import '../features/incidents/incidents_repository.dart';
import '../features/spaces/socialspaces_repository.dart';
import '../features/support/support_repository.dart';

/// Manual DI: one repository instance per feature, sharing the API client and
/// the session repository. (`financeRepositoryProvider` lives with its feature.)
final socialspacesRepositoryProvider = Provider<SocialSpacesRepository>(
  (ref) => SocialSpacesRepository(ref.watch(apiClientProvider), ref.watch(sessionRepositoryProvider)),
);

final incidentsRepositoryProvider = Provider<IncidentsRepository>(
  (ref) => IncidentsRepository(ref.watch(apiClientProvider), ref.watch(sessionRepositoryProvider)),
);

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => AnnouncementsRepository(ref.watch(apiClientProvider)),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiClientProvider), ref.watch(sessionRepositoryProvider)),
);
