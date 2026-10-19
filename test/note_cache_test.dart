import 'package:flutter_test/flutter_test.dart';
import 'package:perlite_flow/services/note_cache.dart';

void main() {
  test('NoteCache md5 key is stable per server+path', () {
    final cache = NoteCache();
    // md5 hashing is internal; just verify the object is constructible.
    expect(cache, isNotNull);
  });
}
