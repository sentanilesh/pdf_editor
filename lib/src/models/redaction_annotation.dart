import 'package:flutter/material.dart';
import 'annotation.dart';

/// Redaction annotation used to permanently black out / redact sensitive areas.
class RedactionAnnotation extends PdfAnnotation {
  RedactionAnnotation({
    required super.id,
    required super.pageNumber,
    required super.bounds,
    super.color = Colors.black,
    this.overlayText,
    super.opacity = 1.0,
    super.createdAt,
    super.isSelected = false,
  });

  /// Optional text displayed centered over the redaction (e.g., "[REDACTED]").
  final String? overlayText;

  @override
  String get type => 'redaction';

  @override
  RedactionAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    Color? color,
    String? overlayText,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    return RedactionAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      bounds: bounds ?? this.bounds,
      color: color ?? this.color,
      overlayText: overlayText ?? this.overlayText,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  RedactionAnnotation translate(Offset delta) {
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
        'color': color.toARGB32(),
        'overlayText': overlayText,
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RedactionAnnotation.fromJson(Map<String, dynamic> json) {
    final b = json['bounds'] as Map<String, dynamic>;
    return RedactionAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      bounds: Rect.fromLTWH(
        (b['left'] as num).toDouble(),
        (b['top'] as num).toDouble(),
        (b['width'] as num).toDouble(),
        (b['height'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
      overlayText: json['overlayText'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
