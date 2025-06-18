class User {
  final int id;
  final String username;

  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'], // Asume que el backend devuelve 'userId'
      username: json['username'],
    );
  }
}