import 'annotation.dart';
import 'pdf_form_field.dart';

/// Base class for undoable/redoable actions.
abstract class HistoryAction {
  const HistoryAction();

  /// Description of the action for debug or tooltip.
  String get description;
}

/// Action when an annotation is added.
class AddAnnotationAction extends HistoryAction {
  const AddAnnotationAction(this.annotation);
  final PdfAnnotation annotation;

  @override
  String get description => 'Add ${annotation.type}';
}

/// Action when an annotation is removed.
class RemoveAnnotationAction extends HistoryAction {
  const RemoveAnnotationAction(this.annotation);
  final PdfAnnotation annotation;

  @override
  String get description => 'Delete ${annotation.type}';
}

/// Action when an annotation is edited/translated/resized.
class ModifyAnnotationAction extends HistoryAction {
  const ModifyAnnotationAction({
    required this.oldAnnotation,
    required this.newAnnotation,
  });
  final PdfAnnotation oldAnnotation;
  final PdfAnnotation newAnnotation;

  @override
  String get description => 'Modify ${newAnnotation.type}';
}

/// Action when a page is rotated.
class RotatePageAction extends HistoryAction {
  const RotatePageAction({
    required this.pageNumber,
    required this.oldRotation,
    required this.newRotation,
  });
  final int pageNumber;
  final int oldRotation; // 0, 90, 180, 270
  final int newRotation;

  @override
  String get description => 'Rotate page $pageNumber to $newRotation°';
}

/// Action when a page is deleted.
class DeletePageAction extends HistoryAction {
  const DeletePageAction({
    required this.pageNumber,
    required this.deletedAnnotations,
  });
  final int pageNumber;
  final List<PdfAnnotation> deletedAnnotations;

  @override
  String get description => 'Delete page $pageNumber';
}

/// Action when all annotations on a page are cleared.
class ClearPageAnnotationsAction extends HistoryAction {
  const ClearPageAnnotationsAction({
    required this.pageNumber,
    required this.annotations,
  });
  final int pageNumber;
  final List<PdfAnnotation> annotations;

  @override
  String get description => 'Clear page $pageNumber annotations';
}

/// Action when an AcroForm field value is edited.
class UpdateFormFieldAction extends HistoryAction {
  const UpdateFormFieldAction({
    required this.oldField,
    required this.newField,
  });

  final PdfFormField oldField;
  final PdfFormField newField;

  @override
  String get description => 'Update form field ${newField.name}';
}
