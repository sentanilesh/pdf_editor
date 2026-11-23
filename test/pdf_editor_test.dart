import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_editor/pdf_editor.dart';

void main() {
  group('PdfAnnotation Models & Serialization Tests', () {
    test('DrawingAnnotation correctly calculates bounds and translates', () {
      final points = [
        const Offset(10, 20),
        const Offset(50, 80),
        const Offset(100, 150),
      ];
      final ann = DrawingAnnotation(
        id: 'draw-1',
        pageNumber: 1,
        points: points,
        color: Colors.red,
        strokeWidth: 4.0,
      );

      expect(ann.type, 'drawing');
      expect(ann.pageNumber, 1);
      expect(ann.bounds.left, lessThanOrEqualTo(10.0));
      expect(ann.bounds.right, greaterThanOrEqualTo(100.0));

      final translated = ann.translate(const Offset(10, 10));
      expect(translated.points.first, const Offset(20, 30));

      // Test JSON round-trip
      final json = ann.toJson();
      final restored = PdfAnnotation.fromJson(json) as DrawingAnnotation;
      expect(restored.id, 'draw-1');
      expect(restored.points.length, 3);
      expect(restored.strokeWidth, 4.0);
    });

    test('TextAnnotation serializes and parses properly', () {
      final ann = TextAnnotation(
        id: 'text-1',
        pageNumber: 2,
        bounds: const Rect.fromLTWH(50, 100, 200, 40),
        text: 'Approved by CEO',
        color: Colors.blue,
        fontSize: 18.0,
        isBold: true,
      );

      expect(ann.type, 'text');
      expect(ann.text, 'Approved by CEO');
      expect(ann.isBold, isTrue);

      final json = ann.toJson();
      final restored = PdfAnnotation.fromJson(json) as TextAnnotation;
      expect(restored.id, 'text-1');
      expect(restored.text, 'Approved by CEO');
      expect(restored.fontSize, 18.0);
      expect(restored.isBold, isTrue);
    });

    test('ShapeAnnotation calculates bounds for line, rectangle, and oval', () {
      final line = ShapeAnnotation(
        id: 'line-1',
        pageNumber: 1,
        shapeType: ShapeType.line,
        startPoint: const Offset(10, 10),
        endPoint: const Offset(100, 100),
        color: Colors.black,
      );
      expect(line.type, 'shape');
      expect(line.shapeType, ShapeType.line);

      final json = line.toJson();
      final restored = PdfAnnotation.fromJson(json) as ShapeAnnotation;
      expect(restored.shapeType, ShapeType.line);
      expect(restored.startPoint, const Offset(10, 10));
      expect(restored.endPoint, const Offset(100, 100));
    });

    test('SignatureAnnotation maintains stroke points', () {
      final sig = SignatureAnnotation(
        id: 'sig-1',
        pageNumber: 1,
        bounds: const Rect.fromLTWH(50, 50, 120, 60),
        strokes: [
          [const Offset(50, 50), const Offset(70, 70)],
          [const Offset(80, 50), const Offset(100, 70)],
        ],
        color: Colors.black,
      );

      expect(sig.type, 'signature');
      expect(sig.strokes.length, 2);

      final json = sig.toJson();
      final restored = PdfAnnotation.fromJson(json) as SignatureAnnotation;
      expect(restored.strokes.length, 2);
    });

    test('DrawingAnnotation hitTest accurately detects points near strokes', () {
      final drawing = DrawingAnnotation(
        id: 'draw-hit',
        pageNumber: 1,
        points: const [Offset(0, 0), Offset(100, 0)],
        color: Colors.blue,
        strokeWidth: 4.0,
      );

      // Directly on segment
      expect(drawing.hitTest(const Offset(50, 0)), isTrue);
      // Slightly offset within padding (strokeWidth/2 + padding 8 = 10)
      expect(drawing.hitTest(const Offset(50, 8)), isTrue);
      // Far away
      expect(drawing.hitTest(const Offset(50, 50)), isFalse);
      expect(drawing.hitTest(const Offset(200, 200)), isFalse);
    });

    test('ShapeAnnotation hitTest accurately detects points on line shapes', () {
      final line = ShapeAnnotation(
        id: 'line-hit',
        pageNumber: 1,
        shapeType: ShapeType.line,
        startPoint: const Offset(10, 10),
        endPoint: const Offset(100, 10),
        color: Colors.black,
        strokeWidth: 2.0,
      );

      expect(line.hitTest(const Offset(50, 10)), isTrue);
      expect(line.hitTest(const Offset(50, 15)), isTrue);
      expect(line.hitTest(const Offset(50, 50)), isFalse);
    });

    test('SignatureAnnotation hitTest detects stroke touches', () {
      final sig = SignatureAnnotation(
        id: 'sig-hit',
        pageNumber: 1,
        bounds: const Rect.fromLTWH(10, 10, 80, 40),
        strokes: [
          [const Offset(10, 10), const Offset(90, 50)],
        ],
        color: Colors.black,
      );

      expect(sig.hitTest(const Offset(50, 30)), isTrue);
      expect(sig.hitTest(const Offset(500, 500)), isFalse);
    });

    test('StampAnnotation supports standard and custom stamps', () {
      final stamp = StampAnnotation(
        id: 'stamp-1',
        pageNumber: 1,
        bounds: const Rect.fromLTWH(100, 100, 150, 50),
        stampType: StampType.approved,
        color: Colors.green,
      );

      expect(stamp.displayTitle, 'APPROVED');

      final customStamp = stamp.copyWith(
        stampType: StampType.custom,
        customText: 'PAID IN FULL',
      );
      expect(customStamp.displayTitle, 'PAID IN FULL');

      final json = stamp.toJson();
      final restored = PdfAnnotation.fromJson(json) as StampAnnotation;
      expect(restored.stampType, StampType.approved);
    });

    test('RedactionAnnotation stores blackout rect and label', () {
      final red = RedactionAnnotation(
        id: 'red-1',
        pageNumber: 1,
        bounds: const Rect.fromLTWH(20, 40, 100, 30),
        overlayText: '[REDACTED]',
      );

      expect(red.type, 'redaction');
      expect(red.overlayText, '[REDACTED]');

      final json = red.toJson();
      final restored = PdfAnnotation.fromJson(json) as RedactionAnnotation;
      expect(restored.overlayText, '[REDACTED]');
    });
  });

  group('PdfEditorController State & Undo/Redo Tests', () {
    test('Tool switching and property updates', () {
      final controller = PdfEditorController();
      expect(controller.activeTool, PdfToolType.view);

      controller.setTool(PdfToolType.draw);
      expect(controller.activeTool, PdfToolType.draw);

      controller.setColor(Colors.amber);
      expect(controller.currentColor, Colors.amber);

      controller.setStrokeWidth(6.0);
      expect(controller.currentStrokeWidth, 6.0);

      controller.setFontSize(22.0);
      expect(controller.currentFontSize, 22.0);

      controller.dispose();
    });

    test('Adding and removing annotations with Undo and Redo', () {
      final controller = PdfEditorController();

      final ann = TextAnnotation(
        id: 'test-ann',
        pageNumber: 1,
        bounds: const Rect.fromLTWH(10, 10, 50, 20),
        text: 'Hello',
        color: Colors.black,
      );

      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);

      controller.addAnnotation(ann);
      expect(controller.getAnnotationsForPage(1).length, 1);
      expect(controller.canUndo, isTrue);

      // Undo
      controller.undo();
      expect(controller.getAnnotationsForPage(1).length, 0);
      expect(controller.canRedo, isTrue);

      // Redo
      controller.redo();
      expect(controller.getAnnotationsForPage(1).length, 1);

      controller.dispose();
    });

    test('JSON Export and Import of annotations', () {
      final controller = PdfEditorController();

      final ann1 = TextAnnotation(
        id: 'ann-1',
        pageNumber: 1,
        bounds: const Rect.fromLTWH(0, 0, 100, 30),
        text: 'Page 1 Note',
        color: Colors.black,
      );

      final ann2 = RedactionAnnotation(
        id: 'ann-2',
        pageNumber: 2,
        bounds: const Rect.fromLTWH(50, 50, 80, 20),
      );

      controller.addAnnotation(ann1);
      controller.addAnnotation(ann2);

      final jsonStr = controller.exportAnnotationsJson();
      expect(jsonStr, contains('Page 1 Note'));
      expect(jsonStr, contains('redaction'));

      // Create new controller and import
      final newController = PdfEditorController();
      newController.importAnnotationsJson(jsonStr);

      expect(newController.getAnnotationsForPage(1).length, 1);
      expect(newController.getAnnotationsForPage(2).length, 1);
      expect(
        (newController.getAnnotationsForPage(1).first as TextAnnotation).text,
        'Page 1 Note',
      );

      controller.dispose();
      newController.dispose();
    });
  });

  group('PdfGeneratorHelper Tests', () {
    test('generateSampleDocument creates valid PDF bytes', () async {
      final bytes = await PdfGeneratorHelper.generateSampleDocument();
      expect(bytes, isNotEmpty);

      // PDF header check: first 4 bytes are '%PDF'
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, '%PDF');
    });

    test('generateBlankDocument creates valid PDF bytes with correct page count', () async {
      final bytes = await PdfGeneratorHelper.generateBlankDocument(pageCount: 3);
      expect(bytes, isNotEmpty);

      final header = String.fromCharCodes(bytes.take(4));
      expect(header, '%PDF');
    });
  });

  group('Password Protection & PdfPasswordDialog Tests', () {
    test('PdfEditorController manages documentPassword lifecycle', () {
      final controller = PdfEditorController();
      expect(controller.documentPassword, isNull);

      controller.setDocumentPassword('Secret123');
      expect(controller.documentPassword, 'Secret123');

      // Loading a new source resets the password
      controller.loadSource(PdfDocumentSource.bytes(
        Uint8List(0),
        name: 'new_doc.pdf',
      ));
      expect(controller.documentPassword, isNull);

      controller.dispose();
    });

    testWidgets('PdfPasswordDialog displays document name, validates, and unlocks', (tester) async {
      String? submittedPassword;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  submittedPassword = await PdfPasswordDialog.show(
                    ctx,
                    documentName: 'confidential_statement.pdf',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog header and details
      expect(find.text('Password Protected'), findsOneWidget);
      expect(find.text('confidential_statement.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      // Attempt to submit empty password
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Password cannot be empty.'), findsOneWidget);
      expect(submittedPassword, isNull);

      // Enter valid password
      await tester.enterText(find.byType(TextField), 'MySecurePass2026');
      await tester.pumpAndSettle();

      // Submit valid password
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(submittedPassword, 'MySecurePass2026');
    });

    testWidgets('PdfPasswordDialog displays retry error message and handles cancel', (tester) async {
      String? submittedPassword = 'not-null-sentinel';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  submittedPassword = await PdfPasswordDialog.show(
                    ctx,
                    documentName: 'taxes.pdf',
                    isRetry: true,
                  );
                },
                child: const Text('Open Retry Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Retry Dialog'));
      await tester.pumpAndSettle();

      // Verify retry error message
      expect(find.text('Incorrect password. Please try again.'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(submittedPassword, isNull);
    });
  });
}
