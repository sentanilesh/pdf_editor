/// Available editing tools in the PDF Editor.
enum PdfToolType {
  /// Navigation, scrolling, panning and pinch-to-zoom mode.
  view,

  /// Selection mode to tap, drag, move, resize, or delete existing annotations.
  select,

  /// Freehand ink drawing / pen with customizable color and stroke width.
  draw,

  /// Semi-transparent highlighter for marking text or diagrams.
  highlighter,

  /// Eraser to delete tapped annotations or strokes.
  eraser,

  /// Text box annotation with custom font size, text color, and background.
  text,

  /// Shape drawing tool (line, arrow, rectangle, circle/oval).
  shape,

  /// Handwritten digital signature placement.
  signature,

  /// Document stamps (e.g., APPROVED, CONFIDENTIAL, DRAFT, COMPLETED).
  stamp,

  /// Blackout redaction box to conceal sensitive information.
  redaction,
}

/// Shape types available for [PdfToolType.shape].
enum ShapeType {
  /// Simple straight line.
  line,

  /// Directed arrow with arrowhead.
  arrow,

  /// Outline or filled rectangle.
  rectangle,

  /// Outline or filled ellipse / circle.
  circle,
}

/// Pre-configured standard document stamps.
enum StampType {
  approved,
  confidential,
  draft,
  rejected,
  urgent,
  completed,
  voidStamp,
  custom,
}

extension StampTypeExt on StampType {
  String get label {
    switch (this) {
      case StampType.approved:
        return 'APPROVED';
      case StampType.confidential:
        return 'CONFIDENTIAL';
      case StampType.draft:
        return 'DRAFT';
      case StampType.rejected:
        return 'REJECTED';
      case StampType.urgent:
        return 'URGENT';
      case StampType.completed:
        return 'COMPLETED';
      case StampType.voidStamp:
        return 'VOID';
      case StampType.custom:
        return 'CUSTOM';
    }
  }
}
