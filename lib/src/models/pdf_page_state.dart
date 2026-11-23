/// Holds display and manipulation state for an individual PDF page.
class PdfPageState {
  PdfPageState({
    required this.pageNumber,
    this.originalWidth = 595.0, // default A4 points
    this.originalHeight = 842.0,
    this.rotation = 0,
    this.isDeleted = false,
  });

  /// 1-based index in original document.
  final int pageNumber;

  /// Original width in PDF points.
  final double originalWidth;

  /// Original height in PDF points.
  final double originalHeight;

  /// Additional rotation in degrees (0, 90, 180, 270).
  final int rotation;

  /// Whether this page has been deleted by the user.
  final bool isDeleted;

  /// Effective width taking rotation into account.
  double get effectiveWidth =>
      (rotation == 90 || rotation == 270) ? originalHeight : originalWidth;

  /// Effective height taking rotation into account.
  double get effectiveHeight =>
      (rotation == 90 || rotation == 270) ? originalWidth : originalHeight;

  PdfPageState copyWith({
    int? pageNumber,
    double? originalWidth,
    double? originalHeight,
    int? rotation,
    bool? isDeleted,
  }) {
    return PdfPageState(
      pageNumber: pageNumber ?? this.pageNumber,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      rotation: rotation ?? this.rotation,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
