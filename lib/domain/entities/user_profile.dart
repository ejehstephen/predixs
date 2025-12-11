class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final int kycLevel;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.kycLevel,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'User',
      phone: json['phone'] ?? '',
      kycLevel: json['kyc_level'] ?? 0,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'kyc_level': kycLevel,
      'avatar_url': avatarUrl,
    };
  }
}
