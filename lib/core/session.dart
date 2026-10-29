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
    this.dni,
    this.address,
    this.avatar,
  });

  final String id;
  final String name;
  final String? email;
  final String? role;
  final String? floor;
  final String? code;
  final String? ownerAdminId;
  final String? dni;
  final String? address;

  /// Profile icon: "preset|😀|#FF5722" or a "data:image/..." photo, else null.
  final String? avatar;

  bool get isResident => role == 'resident';

  /// Copy with the editable profile fields replaced (used after a profile
  /// update so the session reflects the new values without a re-login).
  UserProfile withProfile({
    required String name,
    String? dni,
    String? address,
    String? floor,
    String? email,
    String? avatar,
  }) =>
      UserProfile(
        id: id,
        name: name,
        email: email ?? this.email,
        role: role,
        floor: floor,
        code: code,
        ownerAdminId: ownerAdminId,
        dni: dni,
        address: address,
        avatar: avatar ?? this.avatar,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString(),
        role: json['role']?.toString(),
        floor: json['floor']?.toString(),
        code: json['code']?.toString(),
        ownerAdminId: json['ownerAdminId']?.toString(),
        dni: json['dni']?.toString(),
        address: json['address']?.toString(),
        avatar: json['avatar']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'floor': floor,
        'code': code,
        'ownerAdminId': ownerAdminId,
        'dni': dni,
        'address': address,
        'avatar': avatar,
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
