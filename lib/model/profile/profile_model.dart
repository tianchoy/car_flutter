class UserModel {
  late final String username;
  late final String? avatar;
  late final String email;
  late final String phone;
  late final String address;

  UserModel({
    required this.username,
    this.avatar,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      avatar: json['avatar'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
    );
  }
}
