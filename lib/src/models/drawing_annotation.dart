import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'annotation.dart';

/// Freehand drawing or highlighter annotation consisting of smooth stroke points.
class DrawingAnnotation extends PdfAnnotation {
  DrawingAnnotation({
    required super.id,
    required super.pageNumber,
    required this.points,
    required super.color,
    this.strokeWidth = 3.0,
    this.isHighlighter = false,
    super.opacity = 1.0,
    super.createdAt,
    super.isSelected = false,
    Rect? bounds,
  }) : super(
          bounds: bounds ?? _calculateBounds(points, strokeWidth),
        );

  /// List of points forming the stroke in PDF point coordinates.
  final List<Offset> points;

  /// Width of the drawn stroke in points.
  final double strokeWidth;

  /// If true, renders with semi-transparent highlighter blend mode.
  final bool isHighlighter;

  @override
  String get type => isHighlighter ? 'highlighter' : 'drawing';

  static Rect _calculateBounds(List<Offset> pts, double strokeWidth) {
    if (pts.isEmpty) return Rect.zero;
    double minX = pts.first.dx;
    double maxX = pts.first.dx;
    double minY = pts.first.dy;
    double maxY = pts.first.dy;

    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final halfStroke = strokeWidth / 2;
    return Rect.fromLTRB(
      minX - halfStroke,
      minY - halfStroke,
      maxX + halfStroke,
      maxY + halfStroke,
    );
  }

  @override
  DrawingAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    Color? color,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
    List<Offset>? points,
    double? strokeWidth,
    bool? isHighlighter,
  }) {
    final newPoints = points ?? this.points;
    final newStroke = strokeWidth ?? this.strokeWidth;
    return DrawingAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      points: newPoints,
      color: color ?? this.color,
      strokeWidth: newStroke,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
      bounds: bounds ?? _calculateBounds(newPoints, newStroke),
    );
  }

  @override
  DrawingAnnotation translate(Offset delta) {
    final shifted = points.map((p) => p + delta).toList();
    return copyWith(
      points: shifted,
      bounds: bounds.shift(delta),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'pageNumber': pageNumber,
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'isHighlighter': isHighlighter,
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      };

  factory DrawingAnnotation.fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List)
        .map((e) => Offset((e['x'] as num).toDouble(), (e['y'] as num).toDouble()))
        .toList();
    return DrawingAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      points: pts,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isHighlighter: json['isHighlighter'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
