import 'package:flutter/foundation.dart';

import '../models/server_profile.dart';
import '../services/credential_store.dart';
import '../services/note_cache.dart';
import '../services/perlite_client.dart';

enum AppPhase { loading, onboarding, ready }

class AppState extends ChangeNotifier {
  final CredentialStore store;
  final NoteCache cache;

  AppPhase phase = AppPhase.loading;
  List<ServerProfile> profiles = [];
  ServerProfile? active;
  String? _activePassword;
  PerliteClient? client;

  String? lastAuthError;

  AppState({CredentialStore? store, NoteCache? cache})
      : store = store ?? CredentialStore(),
        cache = cache ?? NoteCache();

  Future<void> init() async {
    profiles = await store.loadProfiles();
    final activeId = await store.loadActiveProfileId();
    if (activeId != null) {
      final match = profiles.where((p) => p.id == activeId);
      if (match.isNotEmpty) {
        final p = match.first;
        final pwd = await store.readPassword(p.id);
        if (p.autoLogin && (p.username.isEmpty || pwd != null || !p.savePassword)) {
          await loginWithProfile(p, password: pwd, persist: false);
          return;
        }
      }
    }
    phase = AppPhase.onboarding;
    notifyListeners();
  }

  PerliteClient buildClient(ServerProfile p, {String? password}) =>
      PerliteClient(
        baseUrl: p.baseUrl,
        username: p.username.isEmpty ? null : p.username,
        password: password,
      );

  /// Validates credentials by probing `content.php?about` and, on success,
  /// persists the profile + optional password.
  Future<String?> login({
    required String baseUrl,
    required String username,
    required String password,
    required bool savePassword,
    required bool autoLogin,
    String? profileId,
    String? name,
  }) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final profile = ServerProfile(
      id: profileId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name ?? Uri.parse(normalized).host,
      baseUrl: normalized,
      username: username,
      savePassword: savePassword,
      autoLogin: autoLogin,
    );

    final probeClient = buildClient(profile, password: password);
    final err = await probeClient.probe();
    if (err != null) {
      lastAuthError = err;
      notifyListeners();
      return err;
    }

    await _persistLogin(profile, password);
    return null;
  }

  Future<void> loginWithProfile(
    ServerProfile p, {
    String? password,
    bool persist = true,
  }) async {
    active = p;
    _activePassword = password;
    client = buildClient(p, password: password);
    phase = AppPhase.ready;
    lastAuthError = null;
    if (persist) {
      await _persistProfileOnly(p);
    }
    notifyListeners();
  }

  Future<void> _persistLogin(ServerProfile p, String password) async {
    if (p.savePassword) {
      await store.savePassword(p.id, password);
    } else {
      await store.deletePassword(p.id);
    }
    _activePassword = p.savePassword ? password : null;
    await _persistProfileOnly(p);
    active = p;
    client = buildClient(p, password: password);
    phase = AppPhase.ready;
    lastAuthError = null;
    notifyListeners();
  }

  Future<void> _persistProfileOnly(ServerProfile p) async {
    final idx = profiles.indexWhere((e) => e.id == p.id);
    if (idx >= 0) {
      profiles[idx] = p;
    } else {
      profiles.add(p);
    }
    await store.saveProfiles(profiles);
    await store.saveActiveProfileId(p.id);
  }

  /// Password for the active session (from memory or secure storage).
  Future<String?> activePassword() async {
    if (_activePassword != null) return _activePassword;
    final p = active;
    if (p == null) return null;
    _activePassword = await store.readPassword(p.id);
    return _activePassword;
  }

  Future<void> logout() async {
    active = null;
    _activePassword = null;
    client = null;
    await store.saveActiveProfileId(null);
    phase = AppPhase.onboarding;
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    profiles.removeWhere((p) => p.id == id);
    await store.saveProfiles(profiles);
    await store.deletePassword(id);
    notifyListeners();
  }

  static String normalizeBaseUrl(String input) {
    var s = input.trim();
    if (s.isEmpty) return s;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
