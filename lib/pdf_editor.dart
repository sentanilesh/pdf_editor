/// A cross-platform Flutter PDF viewer and editor for Android, iOS, Web, Windows, macOS, and Linux.
library;

// Export Models
export 'src/models/annotation.dart';
export 'src/models/drawing_annotation.dart';
export 'src/models/history_action.dart';
export 'src/models/pdf_document_source.dart';
export 'src/models/pdf_form_field.dart';
export 'src/models/pdf_page_state.dart';
export 'src/models/redaction_annotation.dart';
export 'src/models/shape_annotation.dart';
export 'src/models/signature_annotation.dart';
export 'src/models/stamp_annotation.dart';
export 'src/models/text_annotation.dart';
export 'src/models/tool_type.dart';

// Export Controller
export 'src/controller/pdf_editor_controller.dart';

// Export Exporter & Services
export 'src/export/pdf_exporter.dart';
export 'src/services/pdf_form_service.dart';

// Export Rendering
export 'src/rendering/annotation_painter.dart';
export 'src/rendering/font_helper.dart';

// Export Widgets
export 'src/widgets/annotation_canvas.dart';
export 'src/widgets/color_stroke_picker.dart';
export 'src/widgets/editor_toolbar.dart';
export 'src/widgets/mobile_tool_dock.dart';
export 'src/widgets/pdf_editor.dart';
export 'src/widgets/pdf_form_fields_overlay.dart';
export 'src/widgets/pdf_password_dialog.dart';
export 'src/widgets/pdf_viewer_widget.dart';
export 'src/widgets/search_overlay.dart';
export 'src/widgets/signature_dialog.dart';
export 'src/widgets/stamp_picker_dialog.dart';
export 'src/widgets/text_annotation_dialog.dart';
export 'src/widgets/thumbnail_drawer.dart';

// Export Utilities
export 'src/utils/pdf_generator_helper.dart';
