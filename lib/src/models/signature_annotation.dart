import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'annotation.dart';

/// Handwritten signature annotation.
class SignatureAnnotation extends PdfAnnotation {
  SignatureAnnotation({
    required super.id,
    required super.pageNumber,
    required super.bounds,
    required this.strokes,
    required super.color,
    this.strokeWidth = 2.5,
    this.imageBytes,
    super.opacity = 1.0,
    super.createdAt,
    super.isSelected = false,
  });

  /// Vector strokes making up the signature (each stroke is a list of points).
  final List<List<Offset>> strokes;

  /// Width of pen stroke.
  final double strokeWidth;

  /// Optional pre-rendered PNG image bytes for fast raster display / export.
  final Uint8List? imageBytes;

  @override
  String get type => 'signature';

  @override
  SignatureAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    List<List<Offset>>? strokes,
    Color? color,
    double? strokeWidth,
    Uint8List? imageBytes,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    List<List<Offset>>? effectiveStrokes = strokes;
    if (effectiveStrokes == null && bounds != null && bounds != this.bounds) {
      final oldW = this.bounds.width;
      final oldH = this.bounds.height;
      if (oldW > 0 && oldH > 0) {
        final scaleW = bounds.width / oldW;
        final scaleH = bounds.height / oldH;
        effectiveStrokes = this.strokes.map((stroke) {
          return stroke.map((pt) {
            final relX = pt.dx - this.bounds.left;
            final relY = pt.dy - this.bounds.top;
            return Offset(
              bounds.left + relX * scaleW,
              bounds.top + relY * scaleH,
            );
          }).toList();
        }).toList();
      }
    }

    return SignatureAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      bounds: bounds ?? this.bounds,
      strokes: effectiveStrokes ?? this.strokes,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      imageBytes: imageBytes ?? this.imageBytes,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  SignatureAnnotation translate(Offset delta) {
    final shiftedStrokes = strokes
        .map((stroke) => stroke.map((p) => p + delta).toList())
        .toList();
    return copyWith(
      bounds: bounds.shift(delta),
      strokes: shiftedStrokes,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'pageNumber': pageNumber,
        'bounds': {
          'left': bounds.left,
          'top': bounds.top,
          'width': bounds.width,
          'height': bounds.height,
        },
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
        'strokes': strokes
            .map((s) => s.map((p) => {'x': p.dx, 'y': p.dy}).toList())
            .toList(),
      };

  factory SignatureAnnotation.fromJson(Map<String, dynamic> json) {
    final b = json['bounds'] as Map<String, dynamic>;
    final rawStrokes = json['strokes'] as List;
    final strokes = rawStrokes.map((s) {
      return (s as List).map((p) {
        return Offset(
          (p['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
        );
      }).toList();
    }).toList();

    return SignatureAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      bounds: Rect.fromLTWH(
        (b['left'] as num).toDouble(),
        (b['top'] as num).toDouble(),
        (b['width'] as num).toDouble(),
        (b['height'] as num).toDouble(),
      ),
      strokes: strokes,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
