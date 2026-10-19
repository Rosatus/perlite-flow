/// Sanity test that bypasses Dio and goes straight to `dart:io`.
/// If this fails, the emulator's netd is broken for the app — not our code.
library;

import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('raw Dart InternetAddress.lookup resolves a real hostname',
      () async {
    try {
      final addrs = await InternetAddress.lookup('ob.rosata.cn')
          .timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('ob.rosata.cn -> ${addrs.map((a) => a.address).toList()}');
      expect(addrs, isNotEmpty);
    } catch (e) {
      // ignore: avoid_print
      print('lookup failed: $e');
      rethrow;
    }
  });

  test('raw Socket connect to https port works', () async {
    try {
      final sock = await Socket.connect('ob.rosata.cn', 443,
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
          .getUrl(Uri.parse('https://ob.rosata.cn/'))
          .timeout(const Duration(seconds: 15));
      req.headers.add('Authorization',
          'Basic ${base64Encode(utf8.encode('rosatus:79601522'))}');
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
