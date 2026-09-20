import 'package:flutter_test/flutter_test.dart';

import 'package:takhfid_client/app.dart';

void main() {
  testWidgets('Takhfid app renders', (tester) async {
    await tester.pumpWidget(const TakhfidApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TakhfidApp), findsOneWidget);
  });
}
