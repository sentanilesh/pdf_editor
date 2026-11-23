import 'dart:ui';
import 'package:flutter/material.dart';
import 'annotation.dart';

/// Text annotation that can be placed anywhere on the PDF page.
class TextAnnotation extends PdfAnnotation {
  TextAnnotation({
    required super.id,
    required super.pageNumber,
    required super.bounds,
    required this.text,
    required super.color,
    this.fontSize = 14.0,
    this.fontFamily = 'sans-serif',
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isBold = false,
    this.isItalic = false,
    super.opacity = 1.0,
    super.createdAt,
    super.isSelected = false,
  });

  /// The text content.
  final String text;

  /// Font size in points.
  final double fontSize;

  /// Font family (e.g. 'sans-serif', 'serif', 'monospace', 'cursive').
  final String fontFamily;

  /// Optional background fill color.
  final Color? backgroundColor;

  /// Optional box border color.
  final Color? borderColor;

  /// Border width if border color is set.
  final double borderWidth;

  /// Bold font weight.
  final bool isBold;

  /// Italic font style.
  final bool isItalic;

  @override
  String get type => 'text';

  @override
  TextAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    String? text,
    Color? color,
    double? fontSize,
    String? fontFamily,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    bool? isBold,
    bool? isItalic,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      bounds: bounds ?? this.bounds,
      text: text ?? this.text,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  TextAnnotation translate(Offset delta) {
    return copyWith(bounds: bounds.shift(delta));
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
        'text': text,
        'color': color.toARGB32(),
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'backgroundColor': backgroundColor?.toARGB32(),
        'borderColor': borderColor?.toARGB32(),
        'borderWidth': borderWidth,
        'isBold': isBold,
        'isItalic': isItalic,
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    final b = json['bounds'] as Map<String, dynamic>;
    return TextAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      bounds: Rect.fromLTWH(
        (b['left'] as num).toDouble(),
        (b['top'] as num).toDouble(),
        (b['width'] as num).toDouble(),
        (b['height'] as num).toDouble(),
      ),
      text: json['text'] as String,
      color: Color(json['color'] as int),
      fontSize: (json['fontSize'] as num).toDouble(),
      fontFamily: json['fontFamily'] as String? ?? 'sans-serif',
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      borderColor: json['borderColor'] != null
          ? Color(json['borderColor'] as int)
          : null,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 1.0,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
