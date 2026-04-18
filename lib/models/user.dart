class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String role; // 'admin' or 'user'
  final String? fullName;
  final String? phone;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.fullName,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'full_name': fullName,
      'phone': phone,
    };
    // Chỉ thêm id vào map nếu nó khác null (dùng cho trường hợp update hoặc login)
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'] ?? '',
      password: map['password'],
      role: map['role'],
      fullName: map['full_name'],
      phone: map['phone'],
    );
  }
}
