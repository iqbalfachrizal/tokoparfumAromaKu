class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? photo; // NEW

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'photo': photo, // NEW
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      photo: map['photo'], // NEW
    );
  }
}
