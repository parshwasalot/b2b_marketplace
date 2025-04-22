class UserModel {
  final String id;
  final String email;
  final String name;
  final String userType; // buyer or seller
  final String? phoneNumber;
  final String? address;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.phoneNumber,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      userType: json['userType'] ?? 'buyer',
      phoneNumber: json['phoneNumber'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}
