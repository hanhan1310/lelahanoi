import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/main.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('App boots to login when Firebase is not initialized in test', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LanguageCubit>(
        create: (_) => LanguageCubit(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
