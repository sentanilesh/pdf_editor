# pdf_editor

[![pub package](https://img.shields.io/badge/pub-v1.0.0-blue.svg)](https://pub.dev/packages/pdf_editor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A feature-rich, high-performance Flutter PDF viewer and editor for **all 6 platforms**: **Android, iOS, Web, Windows, macOS, and Linux**.

Supports reading, multi-page continuous scrolling, zooming, in-document text search, page thumbnails, drawing, highlighting, text boxes, shapes, handwritten signatures, document stamps, redaction boxes, page rotation & reordering, undo/redo history, and high-fidelity PDF export and printing.

---

## 🚀 Platform Support

| Platform | Viewing & Zoom | Annotations & Drawing | Full-text Search | PDF Export | Direct Printing |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Android** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **iOS** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Web** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Windows** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **macOS** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Linux** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## ✨ Features

- **Document Sources**:
  - `PdfDocumentSource.bytes(Uint8List bytes)`: Memory bytes.
  - `PdfDocumentSource.file(File file)`: Local file system.
  - `PdfDocumentSource.asset(String assetName)`: Bundled Flutter asset.
  - `PdfDocumentSource.network(String url)`: Remote URL with optional HTTP headers.
- **Viewing & Navigation**:
  - Smooth pinch-to-zoom, pan, double-tap zoom, mouse wheel zoom.
  - Continuous vertical multi-page scrolling.
  - Page navigation controls (Previous, Next, Jump to page).
  - Page thumbnails drawer with live visual representation.
  - In-document full-text search with highlight matches and next/prev navigation.
- **Editing & Annotation Tools**:
  - ✏️ **Freehand Drawing / Pen**: Custom stroke width, color palette, opacity.
  - 🖍️ **Highlighter**: Semi-transparent marker for highlighting text and diagrams.
  - 🔤 **Text Annotations**: Add text boxes anywhere on pages with custom font sizes, colors, borders, and backgrounds.
  - 📐 **Shapes**: Straight lines, directional arrows, rectangles, and ellipses/circles.
  - ✍️ **Digital Signatures**: Dedicated smooth signature pad with ink colors; place anywhere, move, and resize.
  - 🏷️ **Document Stamps**: Pre-built stamps (`APPROVED`, `CONFIDENTIAL`, `DRAFT`, `REJECTED`, `URGENT`, `COMPLETED`, `VOID`) or custom text stamps.
  - ⬛ **Redaction Boxes**: Conceal sensitive areas with solid blackout boxes.
  - 🧽 **Eraser**: Tap to delete individual annotations or strokes.
  - 👆 **Select & Move**: Select any annotation, drag to reposition, or change properties.
- **Page Management**:
  - Rotate any individual page by 90°, 180°, or 270°.
  - Reorder pages.
  - Delete pages.
- **History & Persistence**:
  - Full **Undo** and **Redo** stack for all annotation and page operations.
  - **JSON Serialization**: Export all annotations to JSON or restore them from database/backend (`controller.exportAnnotationsJson()` / `controller.importAnnotationsJson()`).
- **Export & Print**:
  - Flatten all annotations into a clean, universal PDF file (`controller.exportPdf()`).
  - Print directly to connected printers on all platforms using `controller.printPdf()`.

---

## 📦 Installation

Add `pdf_editor` to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_editor: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🛠️ Quick Start

### 1. Complete Turnkey PDF Editor

Use `PdfEditor` for an out-of-the-box editor with toolbars, color pickers, thumbnail sidebar, and search:

```dart
import 'package:flutter/material.dart';
import 'package:pdf_editor/pdf_editor.dart';

class MyPdfScreen extends StatelessWidget {
  const MyPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Editor')),
      body: PdfEditor(
        source: PdfDocumentSource.network(
          'https://example.com/sample.pdf',
        ),
        onSave: (exportedBytes) {
          // Handle exported PDF bytes (save to disk, upload, etc.)
          print('Saved PDF: ${exportedBytes.lengthInBytes} bytes');
        },
      ),
    );
  }
}
```

### 2. Loading from Memory Bytes

```dart
final sampleBytes = await PdfGeneratorHelper.generateSampleDocument();

PdfEditor(
  source: PdfDocumentSource.bytes(
    sampleBytes,
    name: 'Agreement.pdf',
  ),
  onSave: (bytes) {
    // Process edited PDF
  },
);
```

### 3. Loading from Local File

```dart
import 'dart:io';

PdfEditor(
  source: PdfDocumentSource.file(
    File('/path/to/document.pdf'),
  ),
);
```

### 4. Read-Only Viewer Mode

If you only need viewing, zooming, and text search without editing toolbars, use `PdfViewerWidget`:

```dart
PdfViewerWidget(
  source: PdfDocumentSource.asset('assets/document.pdf'),
  onPageChanged: (pageNumber) {
    print('Current page: $pageNumber');
  },
);
```

---

## 🎮 Programmatic Control with `PdfEditorController`

You can control all editor capabilities programmatically:

```dart
final controller = PdfEditorController();

// Select active tool
controller.setTool(PdfToolType.draw);
controller.setColor(Colors.red);
controller.setStrokeWidth(4.0);

// Page navigation
await controller.jumpToPage(3);
await controller.nextPage();

// Undo / Redo
if (controller.canUndo) controller.undo();
if (controller.canRedo) controller.redo();

// Page manipulations
controller.rotatePage(1, degrees: 90);
controller.deletePage(2);

// In-document search
controller.toggleSearch();
controller.textSearcher.startTextSearch('Agreement');

// Export & Print
final Uint8List pdfBytes = await controller.exportPdf(dpi: 150.0);
await controller.printPdf();

// Persist annotations to JSON
final String jsonString = controller.exportAnnotationsJson();

// Restore annotations from JSON
controller.importAnnotationsJson(jsonString);
```

---

## 🧩 Architecture

```
lib/
├── pdf_editor.dart                     # Main package exports
└── src/
    ├── models/
    │   ├── annotation.dart             # Base PdfAnnotation model
    │   ├── drawing_annotation.dart     # Pen and highlighter strokes
    │   ├── text_annotation.dart        # Styled text boxes
    │   ├── shape_annotation.dart       # Line, arrow, rectangle, circle
    │   ├── signature_annotation.dart   # Handwritten vector signatures
    │   ├── stamp_annotation.dart       # Badged document stamps
    │   ├── redaction_annotation.dart   # Blackout redaction boxes
    │   ├── pdf_document_source.dart    # Bytes, File, Asset, Network sources
    │   ├── pdf_page_state.dart         # Per-page rotation and deletion state
    │   ├── history_action.dart         # Undoable / Redoable actions
    │   └── tool_type.dart              # Tool and stamp enums
    ├── controller/
    │   └── pdf_editor_controller.dart  # Central state and business logic
    ├── rendering/
    │   └── annotation_painter.dart     # Resolution-independent canvas painter
    ├── widgets/
    │   ├── pdf_editor.dart             # Turnkey full editor widget
    │   ├── pdf_viewer_widget.dart      # Lightweight read-only viewer widget
    │   ├── annotation_canvas.dart      # Interactive gesture overlay per page
    │   ├── editor_toolbar.dart         # Responsive action toolbar
    │   ├── color_stroke_picker.dart    # Colors, strokes, and font controls
    │   ├── signature_dialog.dart       # Interactive signature pad
    │   ├── stamp_picker_dialog.dart    # Preset & custom stamp selector
    │   ├── thumbnail_drawer.dart       # Reorderable page thumbnails
    │   └── search_overlay.dart         # In-document search card
    ├── export/
    │   └── pdf_exporter.dart           # High-DPI PDF flattening engine
    └── utils/
        └── pdf_generator_helper.dart   # Sample PDF generator utility
```

---

## 📄 License

This package is licensed under the [MIT License](LICENSE).
