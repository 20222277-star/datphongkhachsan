import 'package:flutter/material.dart';
import 'dart:html' as html; // Thư viện có sẵn của Web, không cần cài thêm
import 'dart:convert';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    try {
      final userData = html.window.localStorage['user_data'];
      if (userData != null) {
        _user = User.fromMap(json.decode(userData));
      }
    } catch (e) {
      print('DEBUG: Lỗi load storage: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    try {
      html.window.localStorage['user_data'] = json.encode(user.toMap());
    } catch (e) {
      print('DEBUG: Lỗi save storage: $e');
    }
    notifyListeners();
  }

  void logout() {
    _user = null;
    try {
      html.window.localStorage.remove('user_data');
    } catch (e) {
      print('DEBUG: Lỗi remove storage: $e');
    }
    notifyListeners();
  }
}
