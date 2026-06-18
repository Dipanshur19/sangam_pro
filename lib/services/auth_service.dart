import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/app_user.dart';

/// Thrown when trying to create a user whose username already exists.
class DuplicateUsernameException implements Exception {
  final String username;
  DuplicateUsernameException(this.username);
  @override
  String toString() => 'Username "$username" is already taken';
}

/// Local, offline multi-user auth. Stores accounts (with salted SHA-256 password
/// hashes) and the current session in SharedPreferences. Designed so a single
/// shop device can host an owner (admin) plus staff accounts created by the owner.
class AuthService {
  static const _usersKey   = 'sangam_users_v1';
  static const _sessionKey = 'sangam_session_uid';
  static const _uuid = Uuid();
  static final _rng = Random.secure();

  SharedPreferences? _p;
  Future<SharedPreferences> get _prefs async => _p ??= await SharedPreferences.getInstance();

  // ── internal storage helpers ──
  Future<List<Map<String, dynamic>>> _loadRaw() async {
    final p = await _prefs;
    final raw = p.getString(_usersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _saveRaw(List<Map<String, dynamic>> list) async {
    final p = await _prefs;
    await p.setString(_usersKey, jsonEncode(list));
  }

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  String _normalize(String username) => username.trim().toLowerCase();

  // ── queries ──
  Future<List<AppUser>> getUsers() async =>
      (await _loadRaw()).map((m) => AppUser.fromMap(m)).toList();

  Future<bool> hasAdmin() async =>
      (await _loadRaw()).any((m) => (m['role'] as String?) == 'admin');

  Future<bool> usernameExists(String username) async {
    final n = _normalize(username);
    return (await _loadRaw()).any((m) => _normalize(m['username'] as String) == n);
  }

  // ── mutations ──
  Future<AppUser> createAdmin({required String name, required String username, required String password}) async {
    final list = await _loadRaw();
    if (list.any((m) => _normalize(m['username'] as String) == _normalize(username))) {
      throw DuplicateUsernameException(username);
    }
    final salt = _newSalt();
    final user = AppUser(id: _uuid.v4(), name: name.trim(), username: _normalize(username), role: UserRole.admin, canEdit: true);
    list.add({...user.toMap(), 'hash': _hash(password, salt), 'salt': salt});
    await _saveRaw(list);
    return user;
  }

  Future<AppUser> addStaff({required String name, required String username, required String password, bool canEdit = true}) async {
    final list = await _loadRaw();
    if (list.any((m) => _normalize(m['username'] as String) == _normalize(username))) {
      throw DuplicateUsernameException(username);
    }
    final salt = _newSalt();
    final user = AppUser(id: _uuid.v4(), name: name.trim(), username: _normalize(username), role: UserRole.staff, canEdit: canEdit);
    list.add({...user.toMap(), 'hash': _hash(password, salt), 'salt': salt});
    await _saveRaw(list);
    return user;
  }

  Future<void> removeUser(String id) async {
    final list = await _loadRaw();
    list.removeWhere((m) => m['id'] == id);
    await _saveRaw(list);
  }

  Future<void> updateStaff(String id, {String? name, bool? canEdit}) async {
    final list = await _loadRaw();
    final idx = list.indexWhere((m) => m['id'] == id);
    if (idx < 0) return;
    if (name != null) list[idx]['name'] = name.trim();
    if (canEdit != null) list[idx]['canEdit'] = canEdit;
    await _saveRaw(list);
  }

  Future<void> setPassword(String id, String password) async {
    final list = await _loadRaw();
    final idx = list.indexWhere((m) => m['id'] == id);
    if (idx < 0) return;
    final salt = _newSalt();
    list[idx]['salt'] = salt;
    list[idx]['hash'] = _hash(password, salt);
    await _saveRaw(list);
  }

  /// Returns the matching user if credentials are valid, else null.
  Future<AppUser?> verify({required String username, required String password, UserRole? role}) async {
    final n = _normalize(username);
    final list = await _loadRaw();
    for (final m in list) {
      if (_normalize(m['username'] as String) != n) continue;
      if (role != null && (m['role'] as String?) != role.key) continue;
      final salt = m['salt'] as String? ?? '';
      if (_hash(password, salt) == (m['hash'] as String?)) {
        return AppUser.fromMap(m);
      }
      return null; // username matched but wrong password
    }
    return null;
  }

  // ── session ──
  Future<AppUser?> getSessionUser() async {
    final p = await _prefs;
    final id = p.getString(_sessionKey);
    if (id == null) return null;
    final list = await _loadRaw();
    for (final m in list) {
      if (m['id'] == id) return AppUser.fromMap(m);
    }
    return null;
  }

  Future<void> setSession(String id) async {
    final p = await _prefs;
    await p.setString(_sessionKey, id);
  }

  Future<void> clearSession() async {
    final p = await _prefs;
    await p.remove(_sessionKey);
  }
}
