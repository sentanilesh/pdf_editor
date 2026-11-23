import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' hide PdfDocument, PdfFormField;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' hide PdfAnnotation;

import '../models/annotation.dart';
import '../models/pdf_document_source.dart';
import '../models/pdf_form_field.dart';
import '../models/pdf_page_state.dart';
import '../rendering/annotation_painter.dart';
import '../services/pdf_form_service.dart';

/// Exports the edited PDF document with all annotations, rotations, and page operations
/// flattened into high-resolution, universal PDF bytes.
class PdfExporter {
  /// Exports the given [source] or [document] with [annotations] and [pageStates].
  ///
  /// [dpi]: Resolution factor for rendering (default 150 DPI, ideal balance between
  /// fidelity and speed). 200 or 300 can be used for print-ready quality.
  static Future<Uint8List> export({
    required PdfDocumentSource source,
    required Map<int, List<PdfAnnotation>> annotations,
    List<PdfFormField>? formFields,
    Map<int, PdfPageState>? pageStates,
    List<int>? pageOrder,
    double dpi = 150.0,
    PdfPasswordProvider? passwordProvider,
  }) async {
    var bytes = await source.loadBytes();

    // 1. Bake in interactive form field values (flattened into the PDF)
    if (formFields != null && formFields.isNotEmpty) {
      final pwd = passwordProvider != null ? await passwordProvider() : null;
      bytes = await PdfFormService.applyFormValues(
        bytes,
        formFields,
        password: pwd,
        flatten: true,
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
}
