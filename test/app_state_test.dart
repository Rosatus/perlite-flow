import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:perlite_flow/models/server_profile.dart';
import 'package:perlite_flow/services/credential_store.dart';
import 'package:perlite_flow/state/app_state.dart';

class _MemoryStore extends CredentialStore {
  List<ServerProfile> saved = [];
  final passwords = <String, String>{};

  @override
  Future<void> saveProfiles(List<ServerProfile> profiles) async {
    saved = List.of(profiles);
  }

  @override
  Future<void> saveActiveProfileId(String? id) async {}

  @override
  Future<void> savePassword(String profileId, String password) async {
    passwords[profileId] = password;
  }

  @override
  Future<void> deletePassword(String profileId) async {
    passwords.remove(profileId);
  }
}

void main() {
  test('reconnecting to the same server reuses its profile', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {
      request.response
        ..statusCode = 200
        ..write('ok')
        ..close();
    });

    final store = _MemoryStore();
    final app = AppState(store: store);
    final url = 'http://127.0.0.1:${server.port}/';
    app.profiles = [
      ServerProfile(
        id: 'existing',
        name: 'Vault',
        baseUrl: AppState.normalizeBaseUrl(url),
        username: '',
      ),
    ];

    final error = await app.login(
      baseUrl: url,
      username: '',
      password: '',
      savePassword: false,
      autoLogin: false,
    );

    expect(error, isNull);
    expect(store.saved, hasLength(1));
    expect(store.saved.single.id, 'existing');
  });
}
