import 'dart:ui';
import 'package:flutter/material.dart';

import 'drawing_annotation.dart';
import 'redaction_annotation.dart';
import 'shape_annotation.dart';
import 'signature_annotation.dart';
import 'stamp_annotation.dart';
import 'text_annotation.dart';

/// Base abstract class for all PDF annotations.
/// All coordinates are stored in standard PDF points (72 DPI),
/// making them resolution and zoom independent.
abstract class PdfAnnotation {
  PdfAnnotation({
    required this.id,
    required this.pageNumber,
    required this.bounds,
    required this.color,
    this.opacity = 1.0,
    DateTime? createdAt,
    this.isSelected = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Unique identifier for this annotation.
  final String id;

  /// 1-based page number where this annotation is placed.
  final int pageNumber;

  /// Bounding rectangle of the annotation in PDF points.
  final Rect bounds;

  /// Primary color of the annotation.
  final Color color;

  /// Opacity multiplier (0.0 to 1.0).
  final double opacity;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether this annotation is currently selected in the editor.
  final bool isSelected;

  /// Type identifier for serialization and identification.
  String get type;

  /// Creates a copy of this annotation with updated properties.
  PdfAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    Color? color,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
  });

  /// Check if a point (in PDF point coordinates) hits this annotation.
  bool hitTest(Offset point, {double padding = 8.0}) {
    return bounds.inflate(padding).contains(point);
  }

  /// Translates the annotation by [delta].
  PdfAnnotation translate(Offset delta);

  /// Converts this annotation to a JSON map.
  Map<String, dynamic> toJson();

  /// Polymorphic deserialization factory for all annotation types.
  static PdfAnnotation fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'drawing':
      case 'highlighter':
        return DrawingAnnotation.fromJson(json);
      case 'text':
        return TextAnnotation.fromJson(json);
      case 'shape':
        return ShapeAnnotation.fromJson(json);
      case 'signature':
        return SignatureAnnotation.fromJson(json);
      case 'stamp':
        return StampAnnotation.fromJson(json);
      case 'redaction':
        return RedactionAnnotation.fromJson(json);
      default:
        throw UnsupportedError('Unknown annotation type: $type');
    }
  }
}
