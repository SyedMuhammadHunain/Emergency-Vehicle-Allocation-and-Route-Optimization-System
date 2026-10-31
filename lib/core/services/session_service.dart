import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock/demo_data.dart';
import '../mock/mock_repository.dart';

class SessionService extends ChangeNotifier {
  static const String _prefRoleKey = 'resq_demo_role';
  static const String _prefLoggedInKey = 'resq_is_logged_in';
  static const String _prefUserNameKey = 'resq_user_name';
  static const String _prefUserEmailKey = 'resq_user_email';

  String? _role;
  String? _userName;
  String? _userEmail;
  bool _isLoggedIn = false;
  final bool _isDemoMode = true; // Prototype frontend demo mode

  String? get role => _role;
  String get userName => _userName ?? 'User';
  String get userEmail => _userEmail ?? '';
  bool get isLoggedIn => _isLoggedIn;
  bool get isDemoMode => _isDemoMode;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_prefLoggedInKey) ?? false;
      if (_isLoggedIn) {
        _role = prefs.getString(_prefRoleKey) ?? 'citizen';
        _userName = prefs.getString(_prefUserNameKey) ?? 'Demo ${_role![0].toUpperCase()}${_role!.substring(1)}';
        _userEmail = prefs.getString(_prefUserEmailKey) ?? '';
      } else {
        _role = null;
        _userName = null;
        _userEmail = null;
      }
      notifyListeners();
    } catch (_) {
      _isLoggedIn = false;
      _role = null;
    }
  }

  /// Authenticates using centralized MockRepository predefined/stored accounts
  Future<DemoUserAccount?> loginWithCredentials(
    String email,
    String password,
    MockRepository repo,
  ) async {
    final account = repo.authenticate(email, password);
    if (account == null) {
      return null;
    }

    _role = account.role.toLowerCase();
    _userName = account.name;
    _userEmail = account.email;
    _isLoggedIn = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, true);
      await prefs.setString(_prefRoleKey, _role!);
      await prefs.setString(_prefUserNameKey, _userName!);
      await prefs.setString(_prefUserEmailKey, _userEmail!);
    } catch (_) {}

    return account;
  }

  /// Automatically activates session for newly registered citizen
  Future<void> loginAsRegisteredCitizen(DemoUserAccount account) async {
    _role = 'citizen';
    _userName = account.name;
    _userEmail = account.email;
    _isLoggedIn = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, true);
      await prefs.setString(_prefRoleKey, _role!);
      await prefs.setString(_prefUserNameKey, _userName!);
      await prefs.setString(_prefUserEmailKey, _userEmail!);
    } catch (_) {}
  }

  /// Quick Demo Role Switcher (clearly labeled DEMO MODE)
  Future<void> demoLogin(String targetRole) async {
    _role = targetRole.toLowerCase();
    _isLoggedIn = true;
    _userName = 'Demo ${_role![0].toUpperCase()}${_role!.substring(1)}';
    _userEmail = '$_role@resq.com';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, true);
      await prefs.setString(_prefRoleKey, _role!);
      await prefs.setString(_prefUserNameKey, _userName!);
      await prefs.setString(_prefUserEmailKey, _userEmail!);
    } catch (_) {}
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _role = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, false);
      await prefs.remove(_prefRoleKey);
      await prefs.remove(_prefUserNameKey);
      await prefs.remove(_prefUserEmailKey);
    } catch (_) {}
  }
}
