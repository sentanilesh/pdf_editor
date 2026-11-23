import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'annotation.dart';
import 'tool_type.dart';

/// Shape annotation (line, arrow, rectangle, circle/oval).
class ShapeAnnotation extends PdfAnnotation {
  ShapeAnnotation({
    required super.id,
    required super.pageNumber,
    required this.shapeType,
    required this.startPoint,
    required this.endPoint,
    required super.color,
    this.strokeWidth = 2.0,
    this.fillColor,
    super.opacity = 1.0,
    super.createdAt,
    super.isSelected = false,
    Rect? bounds,
  }) : super(
          bounds: bounds ?? _calculateBounds(startPoint, endPoint, strokeWidth),
        );

  /// Type of shape.
  final ShapeType shapeType;

  /// Start point of the shape in PDF coordinates.
  final Offset startPoint;

  /// End point of the shape in PDF coordinates.
  final Offset endPoint;

  /// Border/stroke width in points.
  final double strokeWidth;

  /// Optional interior fill color (for rectangle and circle).
  final Color? fillColor;

  @override
  String get type => 'shape';

  static Rect _calculateBounds(Offset start, Offset end, double strokeWidth) {
    final left = start.dx < end.dx ? start.dx : end.dx;
    final right = start.dx > end.dx ? start.dx : end.dx;
    final top = start.dy < end.dy ? start.dy : end.dy;
    final bottom = start.dy > end.dy ? start.dy : end.dy;

    final half = strokeWidth / 2 + 4.0;
    return Rect.fromLTRB(left - half, top - half, right + half, bottom + half);
  }

  @override
  bool hitTest(Offset point, {double padding = 8.0}) {
    final effectivePadding = (strokeWidth / 2) + padding;
    if (!bounds.inflate(effectivePadding).contains(point)) {
      return false;
    }
    if (shapeType == ShapeType.line || shapeType == ShapeType.arrow) {
      final dx = endPoint.dx - startPoint.dx;
      final dy = endPoint.dy - startPoint.dy;
      final lenSq = dx * dx + dy * dy;
      if (lenSq == 0) {
        return (point - startPoint).distance <= effectivePadding;
      }
      final t = (((point.dx - startPoint.dx) * dx + (point.dy - startPoint.dy) * dy) / lenSq).clamp(0.0, 1.0);
      final proj = Offset(startPoint.dx + t * dx, startPoint.dy + t * dy);
      return (point - proj).distance <= effectivePadding;
    }
    return bounds.inflate(effectivePadding).contains(point);
  }

  @override
  ShapeAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    ShapeType? shapeType,
    Offset? startPoint,
    Offset? endPoint,
    Color? color,
    double? strokeWidth,
    Color? fillColor,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    final newStart = startPoint ?? this.startPoint;
    final newEnd = endPoint ?? this.endPoint;
    final newStroke = strokeWidth ?? this.strokeWidth;
    return ShapeAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      shapeType: shapeType ?? this.shapeType,
      startPoint: newStart,
      endPoint: newEnd,
      color: color ?? this.color,
      strokeWidth: newStroke,
      fillColor: fillColor ?? this.fillColor,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
      bounds: bounds ?? _calculateBounds(newStart, newEnd, newStroke),
    );
  }

  @override
  ShapeAnnotation translate(Offset delta) {
    return copyWith(
      startPoint: startPoint + delta,
      endPoint: endPoint + delta,
      bounds: bounds.shift(delta),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'pageNumber': pageNumber,
        'shapeType': shapeType.name,
        'startPoint': {'x': startPoint.dx, 'y': startPoint.dy},
        'endPoint': {'x': endPoint.dx, 'y': endPoint.dy},
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'fillColor': fillColor?.toARGB32(),
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShapeAnnotation.fromJson(Map<String, dynamic> json) {
    final start = json['startPoint'] as Map<String, dynamic>;
    final end = json['endPoint'] as Map<String, dynamic>;
    return ShapeAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      shapeType: ShapeType.values.byName(json['shapeType'] as String),
      startPoint: Offset(
        (start['x'] as num).toDouble(),
        (start['y'] as num).toDouble(),
      ),
      endPoint: Offset(
        (end['x'] as num).toDouble(),
        (end['y'] as num).toDouble(),
      ),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      fillColor: json['fillColor'] != null
          ? Color(json['fillColor'] as int)
          : null,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
