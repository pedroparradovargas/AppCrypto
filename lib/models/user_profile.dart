/// Modelo de perfil de usuario almacenado en Firestore
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool biometricRegistered;
  final DateTime createdAt;
  final DateTime lastLogin;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.biometricRegistered = false,
    required this.createdAt,
    required this.lastLogin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      biometricRegistered: json['biometricRegistered'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'biometricRegistered': biometricRegistered,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    bool? biometricRegistered,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      biometricRegistered: biometricRegistered ?? this.biometricRegistered,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
