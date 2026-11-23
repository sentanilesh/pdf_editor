import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'annotation.dart';
import 'tool_type.dart';

/// Document stamp annotation (e.g. APPROVED, CONFIDENTIAL, DRAFT).
class StampAnnotation extends PdfAnnotation {
  StampAnnotation({
    required super.id,
    required super.pageNumber,
    required super.bounds,
    required this.stampType,
    required super.color,
    this.customText,
    this.date,
    this.rotationAngle = -0.15, // slight angle for realistic stamped look
    super.opacity = 0.85,
    super.createdAt,
    super.isSelected = false,
  });

  /// The category of stamp.
  final StampType stampType;

  /// Custom stamp label if [stampType] is [StampType.custom].
  final String? customText;

  /// Optional date displayed on the stamp.
  final DateTime? date;

  /// Rotation angle in radians (e.g., -0.15 for slight tilt).
  final double rotationAngle;

  /// The displayed text for this stamp.
  String get displayTitle =>
      stampType == StampType.custom ? (customText ?? 'STAMP') : stampType.label;

  @override
  String get type => 'stamp';

  @override
  StampAnnotation copyWith({
    String? id,
    int? pageNumber,
    Rect? bounds,
    StampType? stampType,
    Color? color,
    String? customText,
    DateTime? date,
    double? rotationAngle,
    double? opacity,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    return StampAnnotation(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      bounds: bounds ?? this.bounds,
      stampType: stampType ?? this.stampType,
      color: color ?? this.color,
      customText: customText ?? this.customText,
      date: date ?? this.date,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      opacity: opacity ?? this.opacity,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  StampAnnotation translate(Offset delta) {
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
        'stampType': stampType.name,
        'color': color.toARGB32(),
        'customText': customText,
        'date': date?.toIso8601String(),
        'rotationAngle': rotationAngle,
        'opacity': opacity,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StampAnnotation.fromJson(Map<String, dynamic> json) {
    final b = json['bounds'] as Map<String, dynamic>;
    return StampAnnotation(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      bounds: Rect.fromLTWH(
        (b['left'] as num).toDouble(),
        (b['top'] as num).toDouble(),
        (b['width'] as num).toDouble(),
        (b['height'] as num).toDouble(),
      ),
      stampType: StampType.values.byName(json['stampType'] as String),
      color: Color(json['color'] as int),
      customText: json['customText'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      rotationAngle: (json['rotationAngle'] as num?)?.toDouble() ?? -0.15,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.85,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
