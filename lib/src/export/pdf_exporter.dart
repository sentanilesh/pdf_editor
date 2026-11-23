import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart' show PdfPasswordProvider;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../models/annotation.dart';
import '../models/pdf_document_source.dart';
import '../models/pdf_form_field.dart';
import '../models/pdf_page_state.dart';
import '../rendering/annotation_painter.dart';
import '../services/pdf_form_service.dart';

/// Exports the edited PDF document with all annotations, form field values,
/// and page operations. Interactive form elements (AcroForms) are preserved
/// in an editable state by default, while drawing/text/stamp/shape annotations
/// are composited as high-resolution overlays directly onto page graphics.
class PdfExporter {
  /// Exports the given [source] with [annotations], [formFields], and [pageStates].
  ///
  /// [flattenForms]: If false (default), interactive form fields remain editable
  /// and interactive in the exported PDF, with user modifications saved.
  /// If true, form fields are flattened into permanent non-interactive page graphics.
  ///
  /// [dpi]: Resolution factor for rendering overlay annotations (default 150 DPI).
  static Future<Uint8List> export({
    required PdfDocumentSource source,
    required Map<int, List<PdfAnnotation>> annotations,
    List<PdfFormField>? formFields,
    Map<int, PdfPageState>? pageStates,
    List<int>? pageOrder,
    double dpi = 150.0,
    bool flattenForms = false,
    PdfPasswordProvider? passwordProvider,
  }) async {
    final originalBytes = await source.loadBytes();
    final pwd = passwordProvider != null ? await passwordProvider() : null;

    final doc = sf.PdfDocument(inputBytes: originalBytes, password: pwd);

    try {
      // 1. Update interactive form field values
      if (formFields != null && formFields.isNotEmpty) {
        PdfFormService.applyFieldsToForm(
          doc.form,
          formFields,
          flatten: flattenForms,
        );
      } else if (flattenForms) {
        try {
          doc.form.flattenAllFields();
        } catch (e) {
          debugPrint('PdfExporter: flattenAllFields error: $e');
        }
      }

      final scale = dpi / 72.0;

      // 2. Overlay vector annotations onto pages
      for (int i = 0; i < doc.pages.count; i++) {
        final pageNumber = i + 1;
        final page = doc.pages[i];

        // Apply rotation if modified in pageStates
        final state = pageStates?[pageNumber];
        if (state != null && state.rotation != 0) {
          page.rotation = _toRotateAngle(state.rotation);
        }

        final pageAnnotations = annotations[pageNumber];
        if (pageAnnotations != null && pageAnnotations.isNotEmpty) {
          final origW = page.size.width;
          final origH = page.size.height;
          final targetW = origW * scale;
          final targetH = origH * scale;

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);

          final painter = AnnotationPainter(
            annotations: pageAnnotations,
            originalPageSize: Size(origW, origH),
          );
          painter.paint(canvas, Size(targetW, targetH));

          final picture = recorder.endRecording();
          final img = await picture.toImage(targetW.round(), targetH.round());
          final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          img.dispose();
          picture.dispose();

          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final pdfBitmap = sf.PdfBitmap(pngBytes);
            page.graphics.drawImage(
              pdfBitmap,
              Rect.fromLTWH(0, 0, origW, origH),
            );
          }
        }
      }

      // 3. Remove deleted pages (in reverse order to preserve indices)
      if (pageStates != null) {
        for (int i = doc.pages.count - 1; i >= 0; i--) {
          final pageNumber = i + 1;
          if (pageStates[pageNumber]?.isDeleted == true) {
            doc.pages.removeAt(i);
          }
        }
      }

      final bytes = doc.saveSync();
      return Uint8List.fromList(bytes);
    } finally {
      doc.dispose();
    }
  }

  static sf.PdfPageRotateAngle _toRotateAngle(int degrees) {
    switch ((degrees % 360 + 360) % 360) {
      case 90:
        return sf.PdfPageRotateAngle.rotateAngle90;
      case 180:
        return sf.PdfPageRotateAngle.rotateAngle180;
      case 270:
        return sf.PdfPageRotateAngle.rotateAngle270;
      default:
        return sf.PdfPageRotateAngle.rotateAngle0;
    }
  }
}
