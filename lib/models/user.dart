class User {
  final String id;
  final String username;
  final String name;
  final String? email;
  final String password;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    required this.password,
  });

  // Static user for testing or default user
  static final User defaultUser = User(
    id: '1',
    username: 'everett',
    name: 'Everett',
    email: 'everett@example.com',
    password: 'password123',
  );

  static final User blankUser = User(
    id: '',
    username: '',
    name: '',
    email: '',
    password: '',
  );

  bool compareTo(User other) {
    if (username == other.username && password == other.password) {
        return true;
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
    );
  }
}
