import 'package:akademihub_mob/features/nilai/domain/entities/nilai_entity.dart';
import 'package:akademihub_mob/features/nilai/presentation/pages/nilai_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = NilaiEntity(
    id: 1,
    siswaId: 2,
    siswaNama: 'Siti',
    ujianId: 3,
    ujianNama: 'UTS Matematika',
    nilai: 80,
  );

  testWidgets('validates score then returns edit value', (tester) async {
    NilaiFormValue? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<NilaiFormValue>(
                context: context,
                builder: (_) => NilaiFormSheet(items: [item], initial: item),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nilai_form_nilai')), '101');
    await tester.tap(find.byKey(const Key('nilai_form_submit')));
    await tester.pump();
    expect(find.text('Masukkan nilai 0 sampai 100'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('nilai_form_nilai')), '91.5');
    await tester.enterText(find.byKey(const Key('nilai_form_keterangan')), 'Direvisi');
    await tester.tap(find.byKey(const Key('nilai_form_submit')));
    await tester.pumpAndSettle();
    expect(result?.nilai, 91.5);
    expect(result?.keterangan, 'Direvisi');
  });
}
