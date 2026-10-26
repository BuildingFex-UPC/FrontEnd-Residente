/// IAM ubiquitous language for the resident app: identity and session models.
library;

/// Public projection of a user row (mirrors `publicUser` in the web frontend).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.floor,
    this.code,
    this.ownerAdminId,
  });

  final String id;
  final String name;
  final String? email;
  final String? role;
  final String? floor;
  final String? code;
  final String? ownerAdminId;

  bool get isResident => role == 'resident';

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString(),
        role: json['role']?.toString(),
        floor: json['floor']?.toString(),
        code: json['code']?.toString(),
        ownerAdminId: json['ownerAdminId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'floor': floor,
        'code': code,
        'ownerAdminId': ownerAdminId,
      };
}

/// Authenticated session persisted across app restarts.
class Session {
  const Session({required this.profile, required this.token});

  final UserProfile profile;
  final String token;

  /// Multi-tenant scope for API queries: the admin that owns the building.
  String? get activeDataOwnerId =>
      profile.ownerAdminId?.trim().isNotEmpty == true ? profile.ownerAdminId : null;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        profile: UserProfile.fromJson(
          (json['profile'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        token: json['token']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'profile': profile.toJson(), 'token': token};
}
