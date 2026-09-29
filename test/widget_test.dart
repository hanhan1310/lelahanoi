import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lelahanoi/main.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/view/Authentication/login/login_page.dart';

void main() {
  testWidgets('App boots to login when Firebase is not initialized in test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
