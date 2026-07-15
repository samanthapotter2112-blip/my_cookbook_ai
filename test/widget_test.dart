import 'package:flutter_test/flutter_test.dart';
import 'package:my_cookbook_ai/main.dart';

void main() {
  testWidgets(
    'App starts successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MyCookbookApp(),
      );

      expect(
        find.text('My Cookbook AI'),
        findsNothing,
      );
    },
  );
}