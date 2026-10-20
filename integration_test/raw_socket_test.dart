/// Sanity test that bypasses Dio and goes straight to `dart:io`.
/// If this fails, the emulator's netd is broken for the app — not our code.
library;

import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment(
    'PERLITE_URL',
    defaultValue: 'https://ob.rosata.cn',
  );
  const user = String.fromEnvironment('PERLITE_USER');
  const pass = String.fromEnvironment('PERLITE_PASSWORD');
  final host = Uri.parse(baseUrl).host;

  test('raw Dart InternetAddress.lookup resolves a real hostname',
      () async {
    try {
      final addrs = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('$host -> ${addrs.map((a) => a.address).toList()}');
      expect(addrs, isNotEmpty);
    } catch (e) {
      // ignore: avoid_print
      print('lookup failed: $e');
      rethrow;
    }
  });

  test('raw Socket connect to https port works', () async {
    try {
      final sock = await Socket.connect(host, 443,
              timeout: const Duration(seconds: 10))
          .timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('socket connected to ${sock.remoteAddress.address}:443');
      await sock.close();
      expect(sock, isNotNull);
    } catch (e) {
      // ignore: avoid_print
      print('socket failed: $e');
      rethrow;
    }
  });

  test('HttpClient can fetch a real HTTPS page', () async {
    try {
      final client = HttpClient();
      final req = await client
          .getUrl(Uri.parse(baseUrl).resolve('/'))
          .timeout(const Duration(seconds: 15));
      if (user.isNotEmpty) {
        req.headers.add('Authorization',
            'Basic ${base64Encode(utf8.encode('$user:$pass'))}');
      }
      final res = await req.close().timeout(const Duration(seconds: 15));
      // ignore: avoid_print
      print('https GET / -> ${res.statusCode}');
      await res.drain();
      client.close();
      expect(res.statusCode, lessThan(500));
    } catch (e) {
      // ignore: avoid_print
      print('http failed: $e');
      rethrow;
    }
  });
}
