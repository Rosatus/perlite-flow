import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_profile.dart';

/// Persists server profiles (SharedPreferences) and their passwords
/// (flutter_secure_storage) separately so secrets never sit in plain prefs.
class CredentialStore {
  static const _profilesKey = 'server_profiles';
  static const _activeKey = 'active_profile_id';
  static const _passwordPrefix = 'pwd_';

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  Future<List<ServerProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ServerProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProfiles(List<ServerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((e) => e.toJson()).toList()),
    );
  }

  Future<String?> loadActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  Future<void> saveActiveProfileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
  }

  Future<void> savePassword(String profileId, String password) {
    return _secure.write(key: '$_passwordPrefix$profileId', value: password);
  }

  Future<String?> readPassword(String profileId) {
    return _secure.read(key: '$_passwordPrefix$profileId');
  }

  Future<void> deletePassword(String profileId) {
    return _secure.delete(key: '$_passwordPrefix$profileId');
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilesKey);
    await prefs.remove(_activeKey);
    await _secure.deleteAll();
  }
}
