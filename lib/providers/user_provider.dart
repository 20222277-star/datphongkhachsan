import 'package:flutter/material.dart';
import 'dart:convert';
// Sử dụng conditional import để tránh lỗi trên các môi trường không phải web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; 

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
    if (!kIsWeb) {
      _isLoading = false;
      return;
    }

    try {
      final userData = html.window.localStorage['user_data'];
      if (userData != null) {
        _user = User.fromMap(json.decode(userData));
        print('DEBUG: Đã khôi phục tài khoản: ${_user?.username}');
      }
    } catch (e) {
      print('DEBUG: Lỗi load storage (không ảnh hưởng đến app): $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    if (kIsWeb) {
      try {
        html.window.localStorage['user_data'] = json.encode(user.toMap());
      } catch (e) {
        print('DEBUG: Lỗi save storage: $e');
      }
    }
    notifyListeners();
  }

  void logout() {
    _user = null;
    if (kIsWeb) {
      try {
        html.window.localStorage.remove('user_data');
      } catch (e) {
        print('DEBUG: Lỗi remove storage: $e');
      }
    }
    notifyListeners();
  }
}
