import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock/demo_data.dart';
import '../mock/mock_repository.dart';
import 'api_service.dart';

class SessionService extends ChangeNotifier {
  // SharedPreferences keys
  static const String _prefRoleKey = 'resq_demo_role';
  static const String _prefLoggedInKey = 'resq_is_logged_in';
  static const String _prefUserNameKey = 'resq_user_name';
  static const String _prefUserEmailKey = 'resq_user_email';
  static const String _prefUserPhoneKey = 'resq_user_phone';
  static const String _prefTokenKey = 'resq_auth_token';
  static const String _prefUserJsonKey = 'resq_user_json';
  static const String _prefUserIdKey = 'resq_user_id';
  static const String _prefIsDemoModeKey = 'resq_is_demo_mode';

  String? _userId;
  String? _role;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _authToken;
  bool _isLoggedIn = false;
  bool _isBackendOnline = false;
  bool _isDemoMode = false;
  Map<String, dynamic>? _userJson;
  DemoUserAccount? _currentUser;

  // ---- getters ----
  String? get userId => _userId;
  int? get numericUserId =>
      int.tryParse(_userId?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
  String? get role => _role;
  String get userName => _userName ?? 'User';
  String get userEmail => _userEmail ?? '';
  String get userPhone => _userPhone ?? '';
  String? get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isBackendOnline => _isBackendOnline;
  bool get isDemoMode => _isDemoMode;
  Map<String, dynamic>? get userJson => _userJson;
  DemoUserAccount? get currentUser => _currentUser;

  // ======================================================================
  // Restore session from SharedPreferences
  // ======================================================================

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_prefLoggedInKey) ?? false;
      _isDemoMode = prefs.getBool(_prefIsDemoModeKey) ?? false;

      if (!_isLoggedIn) {
        _clearLocal();
        notifyListeners();
        return;
      }

      // Restore persisted fields
      _userId = prefs.getString(_prefUserIdKey);
      _role = prefs.getString(_prefRoleKey) ?? 'citizen';
      _userName = prefs.getString(_prefUserNameKey) ?? 'User';
      _userEmail = prefs.getString(_prefUserEmailKey) ?? '';
      _userPhone = prefs.getString(_prefUserPhoneKey) ?? '';
      _authToken = prefs.getString(_prefTokenKey);

      final userJsonStr = prefs.getString(_prefUserJsonKey);
      if (userJsonStr != null) {
        try {
          _userJson = jsonDecode(userJsonStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      // If we have a token, validate it against the backend
      if (_authToken != null && _authToken!.isNotEmpty) {
        ApiService.instance.setAuthToken(_authToken);

        try {
          final meRes = await ApiService.instance.getMe();

          if (meRes.isSuccess && meRes.data != null) {
            // Token is valid — refresh user info from backend
            _isBackendOnline = true;
            final acc = meRes.data!;
            _userName = acc.name;
            _userEmail = acc.email;
            _userPhone = acc.phone;
            _userId = acc.id;
            _role = acc.role;
            _currentUser = acc;
            await _syncToPrefs();
          } else if (meRes.isUnauthorized) {
            // Token expired — clear session
            debugPrint(
              'SessionService.restore: token expired on backend, clearing session',
            );
            await logout();
            return;
          } else {
            // Connection error — keep local data, mark backend offline
            _isBackendOnline = false;
            debugPrint(
              'SessionService.restore: backend offline, using cached session',
            );
          }
        } catch (e) {
          _isBackendOnline = false;
          debugPrint('SessionService.restore: error validating token ($e)');
        }
      }

      _rebuildCurrentUser();
      notifyListeners();
    } catch (_) {
      _isLoggedIn = false;
      _clearLocal();
    }
  }

  // ======================================================================
  // Login with email & password (against Django POST /api/auth/login/)
  // ======================================================================

  Future<DemoUserAccount?> loginWithCredentials(
    String email,
    String password, [
    MockRepository? repo,
    ApiService? apiService,
  ]) async {
    final api = apiService ?? ApiService.instance;
    final cleanEmail = email.trim().toLowerCase();

    final apiResponse = await api.login(cleanEmail, password, mockRepo: repo);
    final account = apiResponse.data;
    if (account == null) {
      return null;
    }

    _userId = account.id;
    _role = account.role.toLowerCase();
    _userName = account.name;
    _userEmail = account.email;
    _userPhone = account.phone;
    _authToken = api.authToken;
    _isLoggedIn = true;
    _isBackendOnline = !apiResponse.isFromFallback;
    _isDemoMode = apiResponse.isFromFallback;
    _currentUser = account;
    notifyListeners();
    await _syncToPrefs();

    return account;
  }

  // ======================================================================
  // Register citizen (against Django POST /api/auth/register/)
  // ======================================================================

  Future<DemoUserAccount?> registerCitizen({
    required String name,
    required String email,
    required String phone,
    required String password,
    MockRepository? repo,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final api = ApiService.instance;

    final res = await api.registerCitizen(
      name: name,
      email: cleanEmail,
      phone: phone,
      password: password,
      mockRepo: repo,
    );

    if (res.isSuccess && res.data != null) {
      final account = res.data!;
      _userId = account.id;
      _role = account.role.toLowerCase();
      _userName = account.name;
      _userEmail = account.email;
      _userPhone = account.phone;
      _authToken = api.authToken;
      _isLoggedIn = true;
      _isBackendOnline = !res.isFromFallback;
      _isDemoMode = res.isFromFallback;
      _currentUser = account;
      notifyListeners();
      await _syncToPrefs();
      return account;
    }

    if (res.error != null && !res.isFromFallback) {
      throw Exception(res.error);
    }

    if (repo != null) {
      final mock = repo.registerCitizen(
        name: name,
        email: cleanEmail,
        password: password,
        phone: phone,
      );
      await loginAsRegisteredCitizen(mock);
      return mock;
    }

    throw Exception(res.error ?? 'Registration failed.');
  }

  /// Automatically activates session for newly registered citizen (offline / mock)
  Future<void> loginAsRegisteredCitizen(DemoUserAccount account) async {
    _userId = account.id;
    _role = 'citizen';
    _userName = account.name;
    _userEmail = account.email;
    _userPhone = account.phone;
    _authToken = null;
    _isLoggedIn = true;
    _isDemoMode = true;
    _currentUser = account;
    notifyListeners();
    await _syncToPrefs();
  }

  /// Quick Demo Role Switcher
  Future<void> demoLogin(String targetRole) async {
    _role = targetRole.toLowerCase();
    _isLoggedIn = true;
    _isDemoMode = true;
    _userId = 'USR-${_role!.toUpperCase()}-DEMO';
    _userName = 'Demo ${_role![0].toUpperCase()}${_role!.substring(1)}';
    _userEmail = '$_role@resq.com';
    _userPhone = '03001234567';
    _authToken = null;
    _currentUser = DemoUserAccount(
      id: _userId!,
      name: _userName!,
      email: _userEmail!,
      password: '',
      role: _role!,
      phone: _userPhone!,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    await _syncToPrefs();
  }

  // ======================================================================
  // Logout (against Django POST /api/auth/logout/)
  // ======================================================================

  Future<void> logout() async {
    try {
      if (_authToken != null && _authToken!.isNotEmpty) {
        await ApiService.instance.logout();
      }
    } catch (_) {
      // Even if network fails, proceed with local logout
    }
    ApiService.instance.clearAuthToken();
    _isLoggedIn = false;
    _isBackendOnline = false;
    _isDemoMode = false;
    _clearLocal();
    notifyListeners();
    await _syncToPrefs();
  }

  // ======================================================================
  // Internal helpers
  // ======================================================================

  void _rebuildCurrentUser() {
    if (_isLoggedIn) {
      _currentUser = DemoUserAccount(
        id: _userId ?? _userJson?['code'] ?? 'USR-001',
        name: _userName ?? 'User',
        email: _userEmail ?? '',
        password: '',
        role: _role ?? 'citizen',
        phone: _userPhone ?? _userJson?['phone'] ?? '',
        isActive: _userJson?['is_active'] ?? true,
        createdAt:
            DateTime.tryParse(_userJson?['created_at'] ?? '') ?? DateTime.now(),
      );
    } else {
      _currentUser = null;
    }
  }

  void _clearLocal() {
    _userId = null;
    _role = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _authToken = null;
    _userJson = null;
    _currentUser = null;
  }

  Future<void> _syncToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, _isLoggedIn);
      await prefs.setBool(_prefIsDemoModeKey, _isDemoMode);

      if (_isLoggedIn) {
        if (_userId != null) {
          await prefs.setString(_prefUserIdKey, _userId!);
        }
        if (_role != null) {
          await prefs.setString(_prefRoleKey, _role!);
        }
        if (_userName != null) {
          await prefs.setString(_prefUserNameKey, _userName!);
        }
        if (_userEmail != null) {
          await prefs.setString(_prefUserEmailKey, _userEmail!);
        }
        if (_userPhone != null) {
          await prefs.setString(_prefUserPhoneKey, _userPhone!);
        }
        if (_authToken != null) {
          await prefs.setString(_prefTokenKey, _authToken!);
        } else {
          await prefs.remove(_prefTokenKey);
        }
        if (_userJson != null) {
          await prefs.setString(_prefUserJsonKey, jsonEncode(_userJson));
        }
      } else {
        await prefs.remove(_prefUserIdKey);
        await prefs.remove(_prefRoleKey);
        await prefs.remove(_prefUserNameKey);
        await prefs.remove(_prefUserEmailKey);
        await prefs.remove(_prefUserPhoneKey);
        await prefs.remove(_prefTokenKey);
        await prefs.remove(_prefUserJsonKey);
      }
    } catch (_) {}
  }
}
