import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('PdfEditorDemoApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfEditorDemoApp());
    expect(find.text('PDF Editor & Viewer'), findsOneWidget);
  });
}
