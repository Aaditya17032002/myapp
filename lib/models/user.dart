class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String role;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  // Converts a User object into a Map to insert into the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  // Converts a Map retrieved from the database into a User object
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
    );
  }
}
