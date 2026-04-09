import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('Widok strony głównej', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomePage()),
    );

    expect(find.text('Panel główny'), findsOneWidget);
    expect(find.text('Lista materiałów'), findsOneWidget);
  });
}
