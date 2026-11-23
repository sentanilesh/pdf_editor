import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart' hide PdfDocument, PdfFormField;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' hide PdfAnnotation;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../models/annotation.dart';
import '../models/pdf_document_source.dart';
import '../models/pdf_form_field.dart';
import '../models/pdf_page_state.dart';
import '../rendering/annotation_painter.dart';
import '../services/pdf_form_service.dart';

/// Exports the edited PDF document with all annotations, rotations, and page operations.
/// Preserves native vector text, fonts, and interactive AcroForm fields by default.
class PdfExporter {
  /// Exports the given [source] with [annotations], [formFields], and [pageStates].
  ///
  /// - [preserveFormFields]: If true (default), interactive AcroForm fields are preserved
  ///   with updated user-entered values intact.
  /// - [flattenFormFields]: If true, flattens form field values permanently into the
  ///   visual page stream and removes interactive form field controls.
  /// - [removeFormFields]: If true, completely removes all form elements/fields from the PDF.
  /// - [rasterizePages]: If true, forces rasterizing pages to bitmap images at [dpi].
  ///   Defaults to false (preserves crisp vector text, hyperlinks, and small file sizes).
  /// - [dpi]: Resolution factor for rendering annotations or raster fallback (default 150 DPI).
  static Future<Uint8List> export({
    required PdfDocumentSource source,
    required Map<int, List<PdfAnnotation>> annotations,
    List<PdfFormField>? formFields,
    Map<int, PdfPageState>? pageStates,
    List<int>? pageOrder,
    double dpi = 150.0,
    bool preserveFormFields = true,
    bool flattenFormFields = false,
    bool removeFormFields = false,
    bool rasterizePages = false,
    PdfPasswordProvider? passwordProvider,
  }) async {
    final originalBytes = await source.loadBytes();
    final pwd = passwordProvider != null ? await passwordProvider() : null;

    final hasCustomReordering = pageOrder != null &&
        pageOrder.isNotEmpty &&
        !_isSequentialOrder(pageOrder);

    // If rasterizePages is explicitly requested or custom page reordering is needed,
    // use the raster-based export engine. Otherwise use vector-preserving Syncfusion engine.
    if (!rasterizePages && !hasCustomReordering) {
      try {
        return await _exportVectorSyncfusion(
          originalBytes: originalBytes,
          annotations: annotations,
          formFields: formFields,
          pageStates: pageStates,
          dpi: dpi,
          preserveFormFields: preserveFormFields,
          flattenFormFields: flattenFormFields,
          removeFormFields: removeFormFields,
          password: pwd,
        );
      } catch (e, st) {
        debugPrint('PdfExporter: Direct vector export failed ($e). Falling back to raster export: $st');
      }
    }

    return await _exportRasterized(
      originalBytes: originalBytes,
      annotations: annotations,
      formFields: formFields,
      pageStates: pageStates,
      pageOrder: pageOrder,
      dpi: dpi,
      removeFormFields: removeFormFields,
      flattenFormFields: flattenFormFields,
      passwordProvider: passwordProvider,
    );
  }

  /// High-fidelity direct export preserving vector text, original layout,
  /// and interactive AcroForm fields.
  static Future<Uint8List> _exportVectorSyncfusion({
    required Uint8List originalBytes,
    required Map<int, List<PdfAnnotation>> annotations,
    List<PdfFormField>? formFields,
    Map<int, PdfPageState>? pageStates,
    required double dpi,
    required bool preserveFormFields,
    required bool flattenFormFields,
    required bool removeFormFields,
    String? password,
  }) async {
    final doc = sf.PdfDocument(inputBytes: originalBytes, password: password);
    try {
      // 1. Form fields handling
      if (removeFormFields) {
        doc.form.fields.clear();
      } else {
        if (formFields != null && formFields.isNotEmpty) {
          PdfFormService.applyFormValuesToDocument(doc, formFields);
        }
        if (flattenFormFields) {
          doc.form.flattenAllFields();
        }
      }

      // 2. Overlay user-drawn annotations onto pages
      final scale = dpi / 72.0;
      for (int i = 0; i < doc.pages.count; i++) {
        final pageNumber = i + 1;
        final pageAnnotations = annotations[pageNumber] ?? [];
        if (pageAnnotations.isEmpty) continue;

        final page = doc.pages[i];
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
          final sfBitmap = sf.PdfBitmap(pngBytes);
          page.graphics.drawImage(
            sfBitmap,
            Rect.fromLTWH(0, 0, origW, origH),
          );
        }
      }

      // 3. Handle page rotations
      for (int i = 0; i < doc.pages.count; i++) {
        final pageNumber = i + 1;
        final state = pageStates?[pageNumber];
        if (state != null && state.rotation != 0) {
          final rot = ((state.rotation % 360) + 360) % 360;
          if (rot == 90) {
            doc.pages[i].rotation = sf.PdfPageRotateAngle.rotateAngle90;
          } else if (rot == 180) {
            doc.pages[i].rotation = sf.PdfPageRotateAngle.rotateAngle180;
          } else if (rot == 270) {
            doc.pages[i].rotation = sf.PdfPageRotateAngle.rotateAngle270;
          } else {
            doc.pages[i].rotation = sf.PdfPageRotateAngle.rotateAngle0;
          }
        }
      }

      // 4. Handle page deletions (in reverse order to preserve indexing)
      for (int i = doc.pages.count - 1; i >= 0; i--) {
        final pageNumber = i + 1;
        final state = pageStates?[pageNumber];
        if (state?.isDeleted == true) {
          doc.pages.removeAt(i);
        }
      }

      final bytes = doc.saveSync();
      return Uint8List.fromList(bytes);
    } finally {
      doc.dispose();
    }
  }

  /// Fallback raster-based export when full rasterization or page reordering is needed.
  static Future<Uint8List> _exportRasterized({
    required Uint8List originalBytes,
    required Map<int, List<PdfAnnotation>> annotations,
    List<PdfFormField>? formFields,
    Map<int, PdfPageState>? pageStates,
    List<int>? pageOrder,
    required double dpi,
    required bool removeFormFields,
    required bool flattenFormFields,
    PdfPasswordProvider? passwordProvider,
  }) async {
    var bytes = originalBytes;

    if (removeFormFields) {
      final pwd = passwordProvider != null ? await passwordProvider() : null;
      bytes = await PdfFormService.applyFormValues(
        bytes,
        formFields ?? [],
        password: pwd,
        removeFormFields: true,
      );
    } else if (formFields != null && formFields.isNotEmpty) {
      final pwd = passwordProvider != null ? await passwordProvider() : null;
      bytes = await PdfFormService.applyFormValues(
        bytes,
        formFields,
        password: pwd,
        flatten: flattenFormFields,
      );
    }

    final doc = await PdfDocument.openData(bytes, passwordProvider: passwordProvider);

    try {
      final pwDoc = pw.Document();
      final totalOriginalPages = doc.pages.length;

      // Determine effective page sequence
      final sequence = pageOrder ??
          List.generate(totalOriginalPages, (index) => index + 1);

      final scale = dpi / 72.0;

      for (final pageNumber in sequence) {
        final state = pageStates?[pageNumber];
        if (state?.isDeleted == true) {
          continue; // Skip deleted pages
        }

        final page = doc.pages[pageNumber - 1];
        final pageAnnotations = annotations[pageNumber] ?? [];

        final rotation = state?.rotation ?? 0;
        final isLandscape = (rotation == 90 || rotation == 270);

        final origW = page.width;
        final origH = page.height;

        final targetW = origW * scale;
        final targetH = origH * scale;

        // Render base PDF page
        final rendered = await page.render(
          fullWidth: targetW,
          fullHeight: targetH,
          width: targetW.round(),
          height: targetH.round(),
        );

        if (rendered == null) continue;

        final baseUiImage = await rendered.createImage();
        rendered.dispose();

        // Composite base image + annotations with PictureRecorder
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Draw original page
        canvas.drawImage(baseUiImage, Offset.zero, Paint());

        // Overlay annotations
        if (pageAnnotations.isNotEmpty) {
          final painter = AnnotationPainter(
            annotations: pageAnnotations,
            originalPageSize: Size(origW, origH),
          );
          painter.paint(canvas, Size(targetW, targetH));
        }

        final picture = recorder.endRecording();
        final composite =
            await picture.toImage(targetW.round(), targetH.round());
        baseUiImage.dispose();
        picture.dispose();

        final byteData =
            await composite.toByteData(format: ui.ImageByteFormat.png);
        composite.dispose();
        if (byteData == null) continue;

        final pngBytes = byteData.buffer.asUint8List();

        // Calculate PDF page size
        final pdfPageW = isLandscape ? origH : origW;
        final pdfPageH = isLandscape ? origW : origH;

        final pageFormat = PdfPageFormat(pdfPageW, pdfPageH,
            marginAll: 0.0);

        pwDoc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Transform.rotateBox(
                  angle: (rotation * 3.141592653589793 / 180.0),
                  child: pw.Image(
                    pw.MemoryImage(pngBytes),
                    fit: pw.BoxFit.fill,
                  ),
                ),
              );
            },
          ),
        );
      }

      return await pwDoc.save();
    } finally {
      await doc.dispose();
    }
  }

  static bool _isSequentialOrder(List<int> order) {
    for (int i = 0; i < order.length; i++) {
      if (order[i] != i + 1) return false;
    }
    return true;
  }
}
