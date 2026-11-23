import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart' hide PdfAnnotation;

import '../controller/pdf_editor_controller.dart';
import '../models/annotation.dart';
import '../models/drawing_annotation.dart';
import '../models/redaction_annotation.dart';
import '../models/shape_annotation.dart';
import '../models/signature_annotation.dart';
import '../models/stamp_annotation.dart';
import '../models/text_annotation.dart';
import '../models/tool_type.dart';
import '../rendering/annotation_painter.dart';
import 'signature_dialog.dart';
import 'text_annotation_dialog.dart';

enum _ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Overlay canvas for capturing annotations, gesture manipulation (moving, resizing),
/// and rendering live previews with Shift-key geometric constraints.
class AnnotationCanvas extends StatefulWidget {
  const AnnotationCanvas({
    super.key,
    required this.controller,
    required this.page,
    required this.pageSize,
  });

  final PdfEditorController controller;
  final PdfPage page;
  final Size pageSize;

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  // Live drawing / shape / move state
  List<Offset> _currentDrawingPoints = [];
  Offset? _shapeStartPoint;
  Offset? _shapeEndPoint;
  Offset? _dragStartPoint;
  PdfAnnotation? _draggingAnnotation;
  Rect? _initialBounds;
  _ResizeHandle? _activeResizeHandle;
  final ValueNotifier<PdfAnnotation?> _liveNotifier = ValueNotifier<PdfAnnotation?>(null);

  @override
  void dispose() {
    _liveNotifier.dispose();
    super.dispose();
  }

  int get pageNumber => widget.page.pageNumber;
  PdfEditorController get controller => widget.controller;

  double get scaleX => widget.pageSize.width / widget.page.width;
  double get scaleY => widget.pageSize.height / widget.page.height;

  Offset _toPdfPoint(Offset local) =>
      Offset(local.dx / scaleX, local.dy / scaleY);

  /// Constrains shape drawing when the Shift key is held down.
  Offset _constrainShapeEndPoint(Offset start, Offset current) {
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    if (!isShift) return current;

    final shapeType = controller.currentShapeType;
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;

    if (shapeType == ShapeType.rectangle || shapeType == ShapeType.circle) {
      // 1:1 perfect square or circle
      final side = math.max(dx.abs(), dy.abs());
      return Offset(
        start.dx + side * (dx < 0 ? -1.0 : 1.0),
        start.dy + side * (dy < 0 ? -1.0 : 1.0),
      );
    } else if (shapeType == ShapeType.line || shapeType == ShapeType.arrow) {
      // Snap line angle to 45 degree increments (0, 45, 90, 135, 180...)
      final angle = math.atan2(dy, dx);
      final snappedAngle = (angle / (math.pi / 4)).round() * (math.pi / 4);
      final dist = math.sqrt(dx * dx + dy * dy);
      return Offset(
        start.dx + dist * math.cos(snappedAngle),
        start.dy + dist * math.sin(snappedAngle),
      );
    }
    return current;
  }

  _ResizeHandle? _detectResizeHandle(Rect bounds, Offset point, {double padding = 12.0}) {
    if ((point - bounds.topLeft).distance <= padding) return _ResizeHandle.topLeft;
    if ((point - bounds.topRight).distance <= padding) return _ResizeHandle.topRight;
    if ((point - bounds.bottomLeft).distance <= padding) return _ResizeHandle.bottomLeft;
    if ((point - bounds.bottomRight).distance <= padding) return _ResizeHandle.bottomRight;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tool = controller.activeTool;
        final annotations = controller.getAnnotationsForPage(pageNumber);
        final selected = controller.selectedAnnotation?.pageNumber == pageNumber
            ? controller.selectedAnnotation
            : null;

        final isViewMode = tool == PdfToolType.view;

        return IgnorePointer(
          ignoring: isViewMode,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleTapUp(details.localPosition),
            onDoubleTapDown: (details) => _handleDoubleTap(details.localPosition),
            onPanStart: (details) => _handlePanStart(details.localPosition),
            onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
            onPanEnd: (details) => _handlePanEnd(),
            child: MouseRegion(
              cursor: _getCursor(selected),
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    // Layer 1: Finalized annotations on this page (cached via RepaintBoundary)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: widget.pageSize,
                        painter: AnnotationPainter(
                          annotations: annotations,
                          originalPageSize: Size(widget.page.width, widget.page.height),
                          selectedAnnotation: selected,
                        ),
                      ),
                    ),

                    // Layer 2: Live stroke/shape/resize preview layer (repaints only when active)
                    ValueListenableBuilder<PdfAnnotation?>(
                      valueListenable: _liveNotifier,
                      builder: (context, live, _) {
                        if (live == null) return const SizedBox.shrink();
                        return CustomPaint(
                          size: widget.pageSize,
                          painter: LiveAnnotationPainter(
                            liveAnnotation: live,
                            originalPageSize: Size(widget.page.width, widget.page.height),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  MouseCursor _getCursor(PdfAnnotation? selected) {
    final tool = controller.activeTool;
    if (tool == PdfToolType.select) {
      return _draggingAnnotation != null
          ? SystemMouseCursors.move
          : SystemMouseCursors.click;
    }
    if (tool == PdfToolType.draw || tool == PdfToolType.highlighter) {
      return SystemMouseCursors.precise;
    }
    if (tool == PdfToolType.text) {
      return SystemMouseCursors.text;
    }
    if (tool == PdfToolType.eraser) {
      return SystemMouseCursors.forbidden;
    }
    return MouseCursor.defer;
  }

  void _handleTapUp(Offset localPos) {
    final pdfPoint = _toPdfPoint(localPos);
    final tool = controller.activeTool;

    switch (tool) {
      case PdfToolType.eraser:
        _handleEraserTap(pdfPoint);
        break;

      case PdfToolType.select:
        _handleSelectTap(pdfPoint);
        break;

      case PdfToolType.text:
        _showInsertTextModal(pdfPoint);
        break;

      case PdfToolType.stamp:
        _placeStamp(pdfPoint);
        break;

      case PdfToolType.signature:
        _placeSignature(pdfPoint);
        break;

      default:
        // Also allow selecting annotations when tapping in other modes if hitting an annotation
        final annotations = controller.getAnnotationsForPage(pageNumber);
        for (final ann in annotations.reversed) {
          if (ann.hitTest(pdfPoint)) {
            controller.selectAnnotation(ann);
            break;
          }
        }
        break;
    }
  }

  void _handleDoubleTap(Offset localPos) {
    final pdfPoint = _toPdfPoint(localPos);
    final annotations = controller.getAnnotationsForPage(pageNumber);

    for (final ann in annotations.reversed) {
      if (ann.hitTest(pdfPoint) && ann is TextAnnotation) {
        _editExistingTextAnnotation(ann);
        break;
      }
    }
  }

  void _handleEraserTap(Offset pdfPoint) {
    final annotations = controller.getAnnotationsForPage(pageNumber);
    for (final ann in annotations.reversed) {
      if (ann.hitTest(pdfPoint)) {
        controller.removeAnnotation(ann);
        break;
      }
    }
  }

  void _handleSelectTap(Offset pdfPoint) {
    final annotations = controller.getAnnotationsForPage(pageNumber);
    PdfAnnotation? hit;
    for (final ann in annotations.reversed) {
      if (ann.hitTest(pdfPoint)) {
        hit = ann;
        break;
      }
    }

    if (hit != null && hit == controller.selectedAnnotation && hit is TextAnnotation) {
      // Tapping already selected text opens editor
      _editExistingTextAnnotation(hit);
    } else {
      controller.selectAnnotation(hit);
    }
  }

  Future<void> _showInsertTextModal(Offset pdfPoint) async {
    final config = await TextAnnotationDialog.show(
      context,
      initialFontSize: controller.currentFontSize,
      initialFontFamily: controller.currentFontFamily,
      initialColor: controller.currentColor,
      isEditing: false,
    );

    if (config != null && config.text.trim().isNotEmpty) {
      controller.setFontFamily(config.fontFamily);
      controller.setFontSize(config.fontSize);
      final approxW = (config.text.length * (config.fontSize * 0.65) + 24.0)
          .clamp(80.0, 400.0);
      final approxH = config.fontSize * 2.4;

      final ann = TextAnnotation(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        pageNumber: pageNumber,
        bounds: Rect.fromLTWH(pdfPoint.dx, pdfPoint.dy, approxW, approxH),
        text: config.text,
        color: config.color,
        fontSize: config.fontSize,
        fontFamily: config.fontFamily,
        backgroundColor: config.backgroundColor,
        isBold: config.isBold,
        isItalic: config.isItalic,
      );
      controller.addAnnotation(ann);
    }
  }

  Future<void> _editExistingTextAnnotation(TextAnnotation textAnn) async {
    final config = await TextAnnotationDialog.show(
      context,
      initialText: textAnn.text,
      initialFontSize: textAnn.fontSize,
      initialFontFamily: textAnn.fontFamily,
      initialColor: textAnn.color,
      initialBackgroundColor: textAnn.backgroundColor,
      initialIsBold: textAnn.isBold,
      initialIsItalic: textAnn.isItalic,
      isEditing: true,
    );

    if (config != null) {
      final approxW = (config.text.length * (config.fontSize * 0.65) + 24.0)
          .clamp(80.0, 500.0);
      final approxH = config.fontSize * 2.4;

      final updated = textAnn.copyWith(
        text: config.text,
        fontSize: config.fontSize,
        fontFamily: config.fontFamily,
        color: config.color,
        backgroundColor: config.backgroundColor,
        isBold: config.isBold,
        isItalic: config.isItalic,
        bounds: Rect.fromLTWH(
          textAnn.bounds.left,
          textAnn.bounds.top,
          math.max(textAnn.bounds.width, approxW),
          math.max(textAnn.bounds.height, approxH),
        ),
      );
      controller.updateAnnotation(textAnn, updated);
    }
  }

  void _placeStamp(Offset pdfPoint) {
    const stampWidth = 140.0;
    const stampHeight = 55.0;

    final stamp = StampAnnotation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pageNumber: pageNumber,
      bounds: Rect.fromCenter(
        center: pdfPoint,
        width: stampWidth,
        height: stampHeight,
      ),
      stampType: controller.currentStampType,
      customText: controller.currentCustomStampText,
      color: controller.currentColor,
      date: DateTime.now(),
    );

    controller.addAnnotation(stamp);
  }

  Future<void> _placeSignature(Offset pdfPoint) async {
    final result = await SignatureDialog.show(
      context,
      defaultColor: controller.currentColor,
    );

    if (result != null && result.strokes.isNotEmpty) {
      const sigWidth = 140.0;
      const sigHeight = 65.0;

      final rawStrokes = result.strokes;
      double minX = double.infinity;
      double maxX = double.negativeInfinity;
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final stroke in rawStrokes) {
        for (final pt in stroke) {
          if (pt.dx < minX) minX = pt.dx;
          if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy < minY) minY = pt.dy;
          if (pt.dy > maxY) maxY = pt.dy;
        }
      }

      final rawW = (maxX - minX).clamp(1.0, 5000.0);
      final rawH = (maxY - minY).clamp(1.0, 5000.0);

      final sigRect = Rect.fromCenter(
        center: pdfPoint,
        width: sigWidth,
        height: sigHeight,
      );

      final normStrokes = rawStrokes.map((stroke) {
        return stroke.map((pt) {
          final nx = (pt.dx - minX) / rawW;
          final ny = (pt.dy - minY) / rawH;
          return Offset(
            sigRect.left + nx * sigWidth,
            sigRect.top + ny * sigHeight,
          );
        }).toList();
      }).toList();

      final sigAnn = SignatureAnnotation(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        pageNumber: pageNumber,
        bounds: sigRect,
        strokes: normStrokes,
        color: result.color,
        strokeWidth: result.strokeWidth,
      );

      controller.addAnnotation(sigAnn);
    }
  }

  void _handlePanStart(Offset localPos) {
    final pdfPoint = _toPdfPoint(localPos);
    final tool = controller.activeTool;

    if (tool == PdfToolType.draw || tool == PdfToolType.highlighter) {
      _currentDrawingPoints = [pdfPoint];
      _liveNotifier.value = DrawingAnnotation(
        id: 'live',
        pageNumber: pageNumber,
        points: List.from(_currentDrawingPoints),
        color: controller.currentColor,
        strokeWidth: tool == PdfToolType.highlighter
            ? controller.currentStrokeWidth * 3.5
            : controller.currentStrokeWidth,
        isHighlighter: tool == PdfToolType.highlighter,
      );
    } else if (tool == PdfToolType.shape) {
      _shapeStartPoint = pdfPoint;
      _shapeEndPoint = pdfPoint;
      _liveNotifier.value = ShapeAnnotation(
        id: 'live',
        pageNumber: pageNumber,
        shapeType: controller.currentShapeType,
        startPoint: _shapeStartPoint!,
        endPoint: _shapeEndPoint!,
        color: controller.currentColor,
        strokeWidth: controller.currentStrokeWidth,
        fillColor: controller.currentFillColor,
      );
    } else if (tool == PdfToolType.redaction) {
      _shapeStartPoint = pdfPoint;
      _shapeEndPoint = pdfPoint;
      _liveNotifier.value = RedactionAnnotation(
        id: 'live',
        pageNumber: pageNumber,
        bounds: Rect.fromPoints(_shapeStartPoint!, _shapeEndPoint!),
        color: Colors.black,
        overlayText: '[REDACTED]',
      );
    } else if (tool == PdfToolType.select) {
      final selected = controller.selectedAnnotation;
      if (selected != null && selected.pageNumber == pageNumber) {
        // Check if tapping a corner handle to resize
        final handle = _detectResizeHandle(selected.bounds, pdfPoint);
        if (handle != null) {
          _activeResizeHandle = handle;
          _draggingAnnotation = selected;
          _dragStartPoint = pdfPoint;
          _initialBounds = selected.bounds;
          return;
        }

        // Check if clicking inside bounding box to move
        if (selected.hitTest(pdfPoint, padding: 10.0)) {
          _activeResizeHandle = null;
          _draggingAnnotation = selected;
          _dragStartPoint = pdfPoint;
          _initialBounds = selected.bounds;
          return;
        }
      }

      // Check if clicking another annotation to select and start dragging immediately
      final annotations = controller.getAnnotationsForPage(pageNumber);
      for (final ann in annotations.reversed) {
        if (ann.hitTest(pdfPoint, padding: 8.0)) {
          controller.selectAnnotation(ann);
          _activeResizeHandle = null;
          _draggingAnnotation = ann;
          _dragStartPoint = pdfPoint;
          _initialBounds = ann.bounds;
          break;
        }
      }
    }
  }

  void _handlePanUpdate(Offset localPos) {
    final pdfPoint = _toPdfPoint(localPos);
    final tool = controller.activeTool;

    if (tool == PdfToolType.draw || tool == PdfToolType.highlighter) {
      if (_currentDrawingPoints.isEmpty ||
          (pdfPoint - _currentDrawingPoints.last).distanceSquared >= 1.5) {
        _currentDrawingPoints.add(pdfPoint);
        _liveNotifier.value = DrawingAnnotation(
          id: 'live',
          pageNumber: pageNumber,
          points: List.from(_currentDrawingPoints),
          color: controller.currentColor,
          strokeWidth: tool == PdfToolType.highlighter
              ? controller.currentStrokeWidth * 3.5
              : controller.currentStrokeWidth,
          isHighlighter: tool == PdfToolType.highlighter,
        );
      }
    } else if (tool == PdfToolType.shape && _shapeStartPoint != null) {
      // Apply Shift-key constraint for perfect square/circle or 45-degree line!
      _shapeEndPoint = _constrainShapeEndPoint(_shapeStartPoint!, pdfPoint);

      _liveNotifier.value = ShapeAnnotation(
        id: 'live',
        pageNumber: pageNumber,
        shapeType: controller.currentShapeType,
        startPoint: _shapeStartPoint!,
        endPoint: _shapeEndPoint!,
        color: controller.currentColor,
        strokeWidth: controller.currentStrokeWidth,
        fillColor: controller.currentFillColor,
      );
    } else if (tool == PdfToolType.redaction && _shapeStartPoint != null) {
      _shapeEndPoint = pdfPoint;
      _liveNotifier.value = RedactionAnnotation(
        id: 'live',
        pageNumber: pageNumber,
        bounds: Rect.fromPoints(_shapeStartPoint!, _shapeEndPoint!),
        color: Colors.black,
        overlayText: '[REDACTED]',
      );
    } else if (tool == PdfToolType.select &&
        _draggingAnnotation != null &&
        _dragStartPoint != null &&
        _initialBounds != null) {
      if (_activeResizeHandle != null) {
        // Resizing
        final init = _initialBounds!;
        Rect newBounds;
        switch (_activeResizeHandle!) {
          case _ResizeHandle.topLeft:
            newBounds = Rect.fromLTRB(
              math.min(pdfPoint.dx, init.right - 15),
              math.min(pdfPoint.dy, init.bottom - 15),
              init.right,
              init.bottom,
            );
            break;
          case _ResizeHandle.topRight:
            newBounds = Rect.fromLTRB(
              init.left,
              math.min(pdfPoint.dy, init.bottom - 15),
              math.max(pdfPoint.dx, init.left + 15),
              init.bottom,
            );
            break;
          case _ResizeHandle.bottomLeft:
            newBounds = Rect.fromLTRB(
              math.min(pdfPoint.dx, init.right - 15),
              init.top,
              init.right,
              math.max(pdfPoint.dy, init.top + 15),
            );
            break;
          case _ResizeHandle.bottomRight:
            newBounds = Rect.fromLTRB(
              init.left,
              init.top,
              math.max(pdfPoint.dx, init.left + 15),
              math.max(pdfPoint.dy, init.top + 15),
            );
            break;
        }

        final resized = _draggingAnnotation!.copyWith(bounds: newBounds);
        _liveNotifier.value = resized;
      } else {
        // Moving / Repositioning
        final delta = pdfPoint - _dragStartPoint!;
        final translated = _draggingAnnotation!.translate(delta);
        _liveNotifier.value = translated;
      }
    }
  }

  void _handlePanEnd() {
    final tool = controller.activeTool;

    if ((tool == PdfToolType.draw || tool == PdfToolType.highlighter) &&
        _currentDrawingPoints.length > 1) {
      final finalAnn = DrawingAnnotation(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        pageNumber: pageNumber,
        points: List.from(_currentDrawingPoints),
        color: controller.currentColor,
        strokeWidth: tool == PdfToolType.highlighter
            ? controller.currentStrokeWidth * 3.5
            : controller.currentStrokeWidth,
        isHighlighter: tool == PdfToolType.highlighter,
      );
      controller.addAnnotation(finalAnn);
    } else if (tool == PdfToolType.shape &&
        _shapeStartPoint != null &&
        _shapeEndPoint != null) {
      final dist = (_shapeEndPoint! - _shapeStartPoint!).distance;
      if (dist > 3.0) {
        final shapeAnn = ShapeAnnotation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          pageNumber: pageNumber,
          shapeType: controller.currentShapeType,
          startPoint: _shapeStartPoint!,
          endPoint: _shapeEndPoint!,
          color: controller.currentColor,
          strokeWidth: controller.currentStrokeWidth,
          fillColor: controller.currentFillColor,
        );
        controller.addAnnotation(shapeAnn);
      }
    } else if (tool == PdfToolType.redaction &&
        _shapeStartPoint != null &&
        _shapeEndPoint != null) {
      final rect = Rect.fromPoints(_shapeStartPoint!, _shapeEndPoint!);
      if (rect.width > 5.0 && rect.height > 5.0) {
        final redAnn = RedactionAnnotation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          pageNumber: pageNumber,
          bounds: rect,
          color: Colors.black,
          overlayText: '[REDACTED]',
        );
        controller.addAnnotation(redAnn);
      }
    } else if (tool == PdfToolType.select &&
        _draggingAnnotation != null &&
        _liveNotifier.value != null) {
      // Save moved or resized annotation
      controller.updateAnnotation(
        _draggingAnnotation!,
        _liveNotifier.value!,
      );
    }

    _currentDrawingPoints = [];
    _shapeStartPoint = null;
    _shapeEndPoint = null;
    _dragStartPoint = null;
    _draggingAnnotation = null;
    _initialBounds = null;
    _activeResizeHandle = null;
    _liveNotifier.value = null;
  }
}
