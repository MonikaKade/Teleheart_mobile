
import 'package:flutter_test/flutter_test.dart';
import 'package:teleheart_mobile/main.dart';

void main() {
  testWidgets('TeleHeart Splash Screen tampil',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TeleHeartApp());

    expect(find.text('TeleHeart'), findsOneWidget);
    expect(
      find.text('Pendamping Kesehatan Jantung Anda'),
      findsOneWidget,
    );
    expect(find.text('Mulai'), findsOneWidget);
  });
}
