class User {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String profilePicture;

  User({
    required this.id,
    required this.name,
    required this.userType,
    required this.email,
    required this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      userType: json['user_type'] as String,
      profilePicture: json['profile_picture'] ?? 'assets/images/default.jpg',
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'user_type': userType,
      };
}
