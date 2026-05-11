class UserModel {
  final String username;
  final String? avatar;
  final String email;
  final String phone;
  final String address;

  UserModel({
    required this.username,
    this.avatar,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}
