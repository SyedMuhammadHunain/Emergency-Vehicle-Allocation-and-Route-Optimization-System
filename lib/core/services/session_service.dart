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
  static const String _prefTokenKey = 'resq_auth_token';
  static const String _prefUserJsonKey = 'resq_user_json';
  static const String _prefUserIdKey = 'resq_user_id';
  static const String _prefIsDemoModeKey = 'resq_is_demo_mode';

  String? _role;
  String? _userName;
  String? _userEmail;
  String? _authToken;
  bool _isLoggedIn = false;
  bool _isBackendOnline = false;
  bool _isDemoMode = false;
  int? _userId;
  Map<String, dynamic>? _userJson;
  DemoUserAccount? _currentUser;

  // ---- getters ----
  String? get role => _role;
  String get userName => _userName ?? 'User';
  String get userEmail => _userEmail ?? '';
  String? get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isBackendOnline => _isBackendOnline;
  bool get isDemoMode => _isDemoMode;
  int? get userId => _userId;
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
      _role = prefs.getString(_prefRoleKey) ?? 'citizen';
      _userName = prefs.getString(_prefUserNameKey);
      _userEmail = prefs.getString(_prefUserEmailKey);
      _authToken = prefs.getString(_prefTokenKey);
      _userId = prefs.getInt(_prefUserIdKey);

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
            _applyUserData(meRes.data!);
            await _syncToPrefs();
          } else if (meRes.isUnauthorized) {
            // Token expired — clear session
            debugPrint('SessionService.restore: token expired on backend, clearing session');
            await _fullClear();
          } else {
            // Connection error — keep local data, mark backend offline
            _isBackendOnline = false;
            debugPrint('SessionService.restore: backend offline, using cached session');
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
  ]) async {
    final cleanEmail = email.trim().toLowerCase();
    final res = await ApiService.instance.login(cleanEmail, password);

    if (res.isSuccess && res.data != null) {
      final data = res.data!;
      _authToken = data['token'] as String?;
      _role = (data['role'] as String?)?.toLowerCase() ?? 'citizen';

      final userMap = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;

      _applyUserData(userMap);
      _isLoggedIn = true;
      _isBackendOnline = true;
      _isDemoMode = false;

      ApiService.instance.setAuthToken(_authToken);
      _rebuildCurrentUser();
      notifyListeners();
      await _syncToPrefs();

      return _currentUser;
    }

    // Backend actively rejected credentials (400, 401, 403)
    if (res.statusCode != null && res.statusCode! > 0) {
      throw Exception(res.error ?? 'Invalid email or password.');
    }

    // Backend is unreachable (connection error/timeout)
    // Only fall back to local mock repository if an explicit repo was provided (e.g. offline dev/testing)
    if (repo != null) {
      final mock = repo.authenticate(cleanEmail, password);
      if (mock != null) {
        _role = mock.role.toLowerCase();
        _userName = mock.name;
        _userEmail = mock.email;
        _authToken = null;
        _isLoggedIn = true;
        _isBackendOnline = false;
        _isDemoMode = true;
        _currentUser = mock;
        notifyListeners();
        await _syncToPrefs();
        return mock;
      }
    }

    throw Exception(res.error ?? 'Backend server unreachable. Please check connection.');
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
    final res = await ApiService.instance.register(
      name: name,
      email: cleanEmail,
      phone: phone,
      password: password,
    );

    if (res.isSuccess && res.data != null) {
      final data = res.data!;
      _authToken = data['token'] as String?;
      _role = (data['role'] as String?)?.toLowerCase() ?? 'citizen';

      final userMap = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;

      _applyUserData(userMap);
      _isLoggedIn = true;
      _isBackendOnline = true;
      _isDemoMode = false;

      ApiService.instance.setAuthToken(_authToken);
      _rebuildCurrentUser();
      notifyListeners();
      await _syncToPrefs();

      return _currentUser;
    }

    // Backend actively rejected registration (e.g. duplicate email, short password)
    if (res.statusCode != null && res.statusCode! > 0) {
      throw Exception(res.error ?? 'Registration failed.');
    }

    // Backend is unreachable: fallback to mock repo if provided
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

    throw Exception(res.error ?? 'Backend server unreachable.');
  }

  /// Automatically activates session for newly registered citizen (offline / mock)
  Future<void> loginAsRegisteredCitizen(DemoUserAccount account) async {
    _role = 'citizen';
    _userName = account.name;
    _userEmail = account.email;
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
    _userName = 'Demo ${_role![0].toUpperCase()}${_role!.substring(1)}';
    _userEmail = '$_role@resq.com';
    _authToken = null;
    _currentUser = DemoUserAccount(
      id: 'USR-${_role!.substring(0, 3).toUpperCase()}-001',
      name: _userName!,
      email: _userEmail!,
      password: '',
      role: _role!,
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
    await _fullClear();
    notifyListeners();
  }

  // ======================================================================
  // Internal helpers
  // ======================================================================

  void _applyUserData(Map<String, dynamic> user) {
    _userName = user['name'] as String? ??
        user['full_name'] as String? ??
        user['username'] as String? ??
        _userName;
    _userEmail = user['email'] as String? ?? _userEmail;
    _userId = user['id'] is int ? user['id'] as int : _userId;
    if (user['role'] is String) {
      _role = (user['role'] as String).toLowerCase();
    }
    _userJson = user;
    _rebuildCurrentUser();
  }

  void _rebuildCurrentUser() {
    if (_isLoggedIn) {
      _currentUser = DemoUserAccount(
        id: _userJson?['code'] ?? 'USR-${_userId ?? 0}',
        name: _userName ?? 'User',
        email: _userEmail ?? '',
        password: '',
        role: _role ?? 'citizen',
        phone: _userJson?['phone'] ?? '',
        isActive: _userJson?['is_active'] ?? true,
        createdAt: DateTime.tryParse(_userJson?['created_at'] ?? '') ?? DateTime.now(),
      );
    } else {
      _currentUser = null;
    }
  }

  void _clearLocal() {
    _role = null;
    _userName = null;
    _userEmail = null;
    _authToken = null;
    _userId = null;
    _userJson = null;
    _currentUser = null;
  }

  Future<void> _fullClear() async {
    _isLoggedIn = false;
    _isBackendOnline = false;
    _isDemoMode = false;
    _clearLocal();
    await _syncToPrefs();
  }

  Future<void> _syncToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoggedInKey, _isLoggedIn);
      await prefs.setBool(_prefIsDemoModeKey, _isDemoMode);

      if (_isLoggedIn) {
        if (_role != null) await prefs.setString(_prefRoleKey, _role!);
        if (_userName != null) await prefs.setString(_prefUserNameKey, _userName!);
        if (_userEmail != null) await prefs.setString(_prefUserEmailKey, _userEmail!);
        if (_authToken != null) {
          await prefs.setString(_prefTokenKey, _authToken!);
        } else {
          await prefs.remove(_prefTokenKey);
        }
        if (_userId != null) await prefs.setInt(_prefUserIdKey, _userId!);
        if (_userJson != null) {
          await prefs.setString(_prefUserJsonKey, jsonEncode(_userJson));
        }
      } else {
        await prefs.remove(_prefRoleKey);
        await prefs.remove(_prefUserNameKey);
        await prefs.remove(_prefUserEmailKey);
        await prefs.remove(_prefTokenKey);
        await prefs.remove(_prefUserIdKey);
        await prefs.remove(_prefUserJsonKey);
      }
    } catch (_) {}
  }
}
