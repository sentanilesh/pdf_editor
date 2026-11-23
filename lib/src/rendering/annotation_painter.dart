import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/annotation.dart';
import '../models/drawing_annotation.dart';
import '../models/redaction_annotation.dart';
import '../models/shape_annotation.dart';
import '../models/signature_annotation.dart';
import '../models/stamp_annotation.dart';
import '../models/text_annotation.dart';
import '../models/tool_type.dart';
import 'font_helper.dart';

/// CustomPainter that renders all annotations for a given PDF page.
/// Automatically transforms PDF coordinates (PDF points) into canvas coordinates.
class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required this.annotations,
    required this.originalPageSize,
    this.selectedAnnotation,
    this.liveAnnotation,
  });

  /// The list of finalized annotations for this page.
  final List<PdfAnnotation> annotations;

  /// Original PDF page size in points (e.g. 595 x 842).
  final Size originalPageSize;

  /// The annotation currently selected (to render selection border & handles).
  final PdfAnnotation? selectedAnnotation;

  /// Ongoing live annotation being drawn (live pen stroke, preview shape, etc.).
  final PdfAnnotation? liveAnnotation;

  @override
  void paint(Canvas canvas, Size size) {
    if (originalPageSize.width <= 0 || originalPageSize.height <= 0) return;

    final scaleX = size.width / originalPageSize.width;
    final scaleY = size.height / originalPageSize.height;

    // Draw all finalized annotations
    for (final annotation in annotations) {
      paintAnnotation(canvas, annotation, scaleX, scaleY);
    }

    // Draw live annotation if any
    if (liveAnnotation != null) {
      paintAnnotation(canvas, liveAnnotation!, scaleX, scaleY);
    }

    // Draw selection handles on selected annotation
    if (selectedAnnotation != null) {
      _paintSelectionHandles(canvas, selectedAnnotation!, scaleX, scaleY);
    }
  }

  static void paintAnnotation(
    Canvas canvas,
    PdfAnnotation annotation,
    double scaleX,
    double scaleY,
  ) {
    if (annotation is DrawingAnnotation) {
      _paintDrawing(canvas, annotation, scaleX, scaleY);
    } else if (annotation is TextAnnotation) {
      _paintText(canvas, annotation, scaleX, scaleY);
    } else if (annotation is ShapeAnnotation) {
      _paintShape(canvas, annotation, scaleX, scaleY);
    } else if (annotation is SignatureAnnotation) {
      _paintSignature(canvas, annotation, scaleX, scaleY);
    } else if (annotation is StampAnnotation) {
      _paintStamp(canvas, annotation, scaleX, scaleY);
    } else if (annotation is RedactionAnnotation) {
      _paintRedaction(canvas, annotation, scaleX, scaleY);
    }
  }

  static void _paintDrawing(
    Canvas canvas,
    DrawingAnnotation drawing,
    double scaleX,
    double scaleY,
  ) {
    if (drawing.points.length < 2) return;

    final paint = Paint()
      ..color = drawing.isHighlighter
          ? drawing.color.withOpacity(0.38 * drawing.opacity)
          : drawing.color.withOpacity(drawing.opacity)
      ..strokeWidth = drawing.strokeWidth * ((scaleX + scaleY) / 2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final first = Offset(drawing.points[0].dx * scaleX, drawing.points[0].dy * scaleY);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < drawing.points.length; i++) {
      final pt = Offset(drawing.points[i].dx * scaleX, drawing.points[i].dy * scaleY);
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, paint);
  }

  static void _paintText(
    Canvas canvas,
    TextAnnotation textAnn,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTRB(
      textAnn.bounds.left * scaleX,
      textAnn.bounds.top * scaleY,
      textAnn.bounds.right * scaleX,
      textAnn.bounds.bottom * scaleY,
    );

    if (textAnn.backgroundColor != null) {
      final bgPaint = Paint()
        ..color = textAnn.backgroundColor!.withOpacity(textAnn.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
    }

    if (textAnn.borderColor != null) {
      final borderPaint = Paint()
        ..color = textAnn.borderColor!.withOpacity(textAnn.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = textAnn.borderWidth * ((scaleX + scaleY) / 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
    }

    final avgScale = (scaleX + scaleY) / 2;
    final textStyle = PdfFontHelper.resolveTextStyle(
      fontFamily: textAnn.fontFamily,
      fontSize: textAnn.fontSize * avgScale,
      color: textAnn.color,
      isBold: textAnn.isBold,
      isItalic: textAnn.isItalic,
      opacity: textAnn.opacity,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: textAnn.text,
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: rect.width > 0 ? rect.width : double.infinity);
    textPainter.paint(canvas, Offset(rect.left + 4 * scaleX, rect.top + 4 * scaleY));
  }

  static void _paintShape(
    Canvas canvas,
    ShapeAnnotation shape,
    double scaleX,
    double scaleY,
  ) {
    final start = Offset(shape.startPoint.dx * scaleX, shape.startPoint.dy * scaleY);
    final end = Offset(shape.endPoint.dx * scaleX, shape.endPoint.dy * scaleY);
    final avgScale = (scaleX + scaleY) / 2;

    final strokePaint = Paint()
      ..color = shape.color.withOpacity(shape.opacity)
      ..strokeWidth = shape.strokeWidth * avgScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = shape.fillColor != null
        ? (Paint()
          ..color = shape.fillColor!.withOpacity(shape.opacity)
          ..style = PaintingStyle.fill)
        : null;

    switch (shape.shapeType) {
      case ShapeType.line:
        canvas.drawLine(start, end, strokePaint);
        break;

      case ShapeType.arrow:
        canvas.drawLine(start, end, strokePaint);
        _paintArrowHead(canvas, start, end, strokePaint, avgScale);
        break;

      case ShapeType.rectangle:
        final rect = Rect.fromPoints(start, end);
        if (fillPaint != null) canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        break;

      case ShapeType.circle:
        final rect = Rect.fromPoints(start, end);
        if (fillPaint != null) canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
        break;
    }
  }

  static void _paintArrowHead(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double scale,
  ) {
    final headLength = 14.0 * scale;
    final headAngle = math.pi / 6;

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

    final arrowP1 = Offset(
      end.dx - headLength * math.cos(angle - headAngle),
      end.dy - headLength * math.sin(angle - headAngle),
    );
    final arrowP2 = Offset(
      end.dx - headLength * math.cos(angle + headAngle),
      end.dy - headLength * math.sin(angle + headAngle),
    );

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowP1.dx, arrowP1.dy)
      ..lineTo(arrowP2.dx, arrowP2.dy)
      ..close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  static void _paintSignature(
    Canvas canvas,
    SignatureAnnotation sig,
    double scaleX,
    double scaleY,
  ) {
    final avgScale = (scaleX + scaleY) / 2;
    final paint = Paint()
      ..color = sig.color.withOpacity(sig.opacity)
      ..strokeWidth = sig.strokeWidth * avgScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in sig.strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();
      path.moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
      }
      canvas.drawPath(path, paint);
    }
  }

  static void _paintStamp(
    Canvas canvas,
    StampAnnotation stamp,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTRB(
      stamp.bounds.left * scaleX,
      stamp.bounds.top * scaleY,
      stamp.bounds.right * scaleX,
      stamp.bounds.bottom * scaleY,
    );

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(stamp.rotationAngle);
    final localRect = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );

    final avgScale = (scaleX + scaleY) / 2;
    final borderPaint = Paint()
      ..color = stamp.color.withOpacity(stamp.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * avgScale;

    // Double border stamp look
    final rrectOuter = RRect.fromRectAndRadius(localRect, Radius.circular(8 * avgScale));
    canvas.drawRRect(rrectOuter, borderPaint);

    final innerRect = localRect.deflate(4 * avgScale);
    final rrectInner = RRect.fromRectAndRadius(innerRect, Radius.circular(5 * avgScale));
    canvas.drawRRect(rrectInner, borderPaint..strokeWidth = 1.5 * avgScale);

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: stamp.displayTitle,
        style: TextStyle(
          color: stamp.color.withOpacity(stamp.opacity),
          fontSize: 16.0 * avgScale,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(-titlePainter.width / 2, -titlePainter.height / 2 - 6 * avgScale),
    );

    // Optional date subtitle
    if (stamp.date != null) {
      final dateStr =
          '${stamp.date!.year}-${stamp.date!.month.toString().padLeft(2, '0')}-${stamp.date!.day.toString().padLeft(2, '0')}';
      final datePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: TextStyle(
            color: stamp.color.withOpacity(stamp.opacity * 0.8),
            fontSize: 10.0 * avgScale,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      datePainter.layout();
      datePainter.paint(
        canvas,
        Offset(-datePainter.width / 2, 4 * avgScale),
      );
    }

    canvas.restore();
  }

  static void _paintRedaction(
    Canvas canvas,
    RedactionAnnotation red,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTRB(
      red.bounds.left * scaleX,
      red.bounds.top * scaleY,
      red.bounds.right * scaleX,
      red.bounds.bottom * scaleY,
    );

    final fillPaint = Paint()
      ..color = red.color.withOpacity(red.opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    if (red.overlayText != null && red.overlayText!.isNotEmpty) {
      final avgScale = (scaleX + scaleY) / 2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: red.overlayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.0 * avgScale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  static void _paintSelectionHandles(
    Canvas canvas,
    PdfAnnotation annotation,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTRB(
      annotation.bounds.left * scaleX,
      annotation.bounds.top * scaleY,
      annotation.bounds.right * scaleX,
      annotation.bounds.bottom * scaleY,
    ).inflate(4.0);

    // Blue bounding box
    final boxPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, boxPaint);

    // Corner handle circles
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, 5.0, handlePaint);
      canvas.drawCircle(corner, 5.0, handleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        selectedAnnotation != oldDelegate.selectedAnnotation ||
        liveAnnotation != oldDelegate.liveAnnotation ||
        originalPageSize != oldDelegate.originalPageSize;
  }
}

/// Lightweight painter for the live interactive layer (active stroke, shape preview, or resize/drag).
/// Repaints only when the live annotation updates, leaving the cached finalized annotations layer untouched.
class LiveAnnotationPainter extends CustomPainter {
  const LiveAnnotationPainter({
    required this.liveAnnotation,
    required this.originalPageSize,
  });

  final PdfAnnotation? liveAnnotation;
  final Size originalPageSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (liveAnnotation == null || originalPageSize.width <= 0 || originalPageSize.height <= 0) return;
    final scaleX = size.width / originalPageSize.width;
    final scaleY = size.height / originalPageSize.height;
    AnnotationPainter.paintAnnotation(canvas, liveAnnotation!, scaleX, scaleY);
  }

  @override
  bool shouldRepaint(covariant LiveAnnotationPainter oldDelegate) {
    return liveAnnotation != oldDelegate.liveAnnotation ||
        originalPageSize != oldDelegate.originalPageSize;
  }
}
