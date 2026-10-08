import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nurturio/app/nurturio_app.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';

void main(){
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('honey quest interaction, check and reward', (tester) async {
    final db=SaveDatabase.forTesting(NativeDatabase.memory());
    final c=AppController(await ContentLibrary.load(),db);c.settings['onboarded']=true;c.settings['motion']=false;c.settings['sound']=false;
    await tester.pumpWidget(ProviderScope(overrides:[controllerProvider.overrideWith((ref)=>c)],child:const NurturioApp()));
    await tester.pump(const Duration(milliseconds:500));
    await tester.tap(find.byTooltip('Continue learning'));await tester.pump(const Duration(milliseconds:500));
    await tester.scrollUntilVisible(find.text('Let’s try it'),150);await tester.ensureVisible(find.text('Let’s try it'));await tester.tap(find.text('Let’s try it'));await tester.pump();
    for(final answer in ['Egg laying','Nectar gathering','Male bee']){
      final control=find.widgetWithText(OutlinedButton,answer).first;
      await tester.scrollUntilVisible(control,150);await tester.ensureVisible(control);await tester.tap(control);await tester.pump();
    }
    await tester.scrollUntilVisible(find.widgetWithText(OutlinedButton,'Workers'),150);await tester.ensureVisible(find.text('Workers'));await tester.tap(find.text('Workers'));await tester.pump();
    expect(c.completed.contains('honey-1'),true);expect(c.coins,10);expect(find.text('A new discovery!'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());await c.flush();await db.close();
  });
}
