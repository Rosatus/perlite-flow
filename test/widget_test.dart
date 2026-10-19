import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perlite_flow/main.dart';

void main() {
  testWidgets('App boots into login when no server is configured',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PerliteFlowApp());
    await tester.pumpAndSettle();
    expect(find.text('Perlite Flow'), findsWidgets);
  });
}
