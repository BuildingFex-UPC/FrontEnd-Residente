import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../core/session.dart';

/// Credentials returned by the sign-in / set-credentials endpoints.
class AuthResult {
  const AuthResult({required this.profile, required this.token});

  final UserProfile profile;
  final String token;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        profile: UserProfile.fromJson(
          (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        token: json['token']?.toString() ?? '',
      );
}

/// Public projection of a resident looked up by invitation code.
class ResidentInvite {
  const ResidentInvite({
    required this.id,
    required this.name,
    this.code,
    this.floor,
    this.email,
  });

  final String id;
  final String name;
  final String? code;
  final String? floor;
  final String? email;

  factory ResidentInvite.fromJson(Map<String, dynamic> json) => ResidentInvite(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        code: json['code']?.toString(),
        floor: json['floor']?.toString(),
        email: json['email']?.toString(),
      );
}

/// IAM bounded-context endpoints and repository (resident side).
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String email) => _emailRe.hasMatch(email.trim());

  /// `POST /api/v1/authentication/sign-in`
  Future<AuthResult> login(String email, String password) => apiCall(() async {
        final response = await _api.dio.post<dynamic>(
          'api/v1/authentication/sign-in',
          data: {'email': email, 'password': password},
        );
        return AuthResult.fromJson(_asMap(response.data));
      });

  /// `GET /api/v1/authentication/check-email?email=`
  Future<bool> isEmailRegistered(String email) => apiCall(() async {
        final response = await _api.dio.get<dynamic>(
          'api/v1/authentication/check-email',
          queryParameters: {'email': email},
        );
        return (_asMap(response.data)['exists'] as bool?) ?? false;
      });

  /// `GET /api/v1/authentication/residents/invite?code=` (public, not scoped).
  Future<ResidentInvite> findResidentByInviteCode(String code) =>
      apiCall(() async {
        final response = await _api.dio.get<dynamic>(
          'api/v1/authentication/residents/invite',
          queryParameters: {'code': code},
        );
        return ResidentInvite.fromJson(_asMap(response.data));
      });

  /// `POST /api/v1/authentication/residents/set-credentials`
  Future<AuthResult> setResidentCredentials(
    String code,
    String email,
    String password,
  ) =>
      apiCall(() async {
        final response = await _api.dio.post<dynamic>(
          'api/v1/authentication/residents/set-credentials',
          data: {'code': code, 'email': email, 'password': password},
        );
        return AuthResult.fromJson(_asMap(response.data));
      });

  /// `PATCH /users/{id}/profile` — updates the editable profile fields
  /// (name, DNI, address, department code+floor, email and avatar). The
  /// department code is editable here so the resident can change apartment.
  Future<UserProfile> updateProfile({
    required String id,
    required String name,
    String? dni,
    String? address,
    String? floor,
    String? email,
    String? avatar,
    String? code,
  }) =>
      apiCall(() async {
        final response = await _api.dio.patch<dynamic>(
          'users/$id/profile',
          data: {
            'name': name,
            'dni': dni,
            'address': address,
            'floor': floor,
            'email': email,
            'avatar': avatar,
            'code': code,
          },
        );
        return UserProfile.fromJson(_asMap(response.data));
      });

  /// `PATCH /users/{id}` — changes the password. The backend requires the
  /// current email, so it is passed through unchanged (email stays fixed).
  Future<void> changePassword({
    required String id,
    required String email,
    required String newPassword,
  }) =>
      apiCall(() async {
        await _api.dio.patch<dynamic>(
          'users/$id',
          data: {'email': email, 'password': newPassword},
        );
      });
}

Map<String, dynamic> _asMap(dynamic value) =>
    (value as Map?)?.cast<String, dynamic>() ?? const {};

/// Guards the resident-only boundary: an admin session must not be created
/// here (admins use the Jetpack Compose app instead).
void ensureResidentRole(UserProfile profile) {
  if (!profile.isResident) {
    throw AppException('ADMIN_LOGIN_BLOCKED', '');
  }
}
