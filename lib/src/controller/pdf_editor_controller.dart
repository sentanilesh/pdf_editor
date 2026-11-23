import 'dart:convert';
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart' hide PdfAnnotation;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../export/pdf_exporter.dart';
import '../models/annotation.dart';
import '../models/history_action.dart';
import '../models/pdf_document_source.dart';
import '../models/pdf_form_field.dart';
import '../models/pdf_page_state.dart';
import '../models/shape_annotation.dart';
import '../models/signature_annotation.dart';
import '../models/text_annotation.dart';
import '../models/tool_type.dart';
import '../services/pdf_form_service.dart';

/// Main controller that orchestrates document loading, active tools,
/// annotation manipulation, undo/redo history, page operations, and export.
class PdfEditorController extends ChangeNotifier {
  PdfEditorController({
    PdfDocumentSource? initialSource,
    PdfToolType initialTool = PdfToolType.view,
  })  : _source = initialSource,
        _activeTool = initialTool {
    _pdfrxController = PdfViewerController();
    _textSearcher = PdfTextSearcher(_pdfrxController);
  }

  // --- Document & Underlying Controller ---
  PdfDocumentSource? _source;
  PdfDocumentSource? get source => _source;

  late final PdfViewerController _pdfrxController;
  PdfViewerController get pdfrxController => _pdfrxController;

  late final PdfTextSearcher _textSearcher;
  PdfTextSearcher get textSearcher => _textSearcher;

  PdfDocument? _document;
  PdfDocument? get document => _document;

  int _pageCount = 0;
  int get pageCount => _pageCount;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- Active Tool & Settings ---
  PdfToolType _activeTool = PdfToolType.view;
  PdfToolType get activeTool => _activeTool;

  Color _currentColor = Colors.blueAccent;
  Color get currentColor => _currentColor;

  double _currentStrokeWidth = 3.0;
  double get currentStrokeWidth => _currentStrokeWidth;

  double _currentOpacity = 1.0;
  double get currentOpacity => _currentOpacity;

  double _currentFontSize = 16.0;
  double get currentFontSize => _currentFontSize;

  String _currentFontFamily = 'Roboto';
  String get currentFontFamily => _currentFontFamily;

  ShapeType _currentShapeType = ShapeType.rectangle;
  ShapeType get currentShapeType => _currentShapeType;

  Color? _currentFillColor;
  Color? get currentFillColor => _currentFillColor;

  StampType _currentStampType = StampType.approved;
  StampType get currentStampType => _currentStampType;

  String? _currentCustomStampText;
  String? get currentCustomStampText => _currentCustomStampText;

  // --- Selection & Live Preview ---
  PdfAnnotation? _selectedAnnotation;
  PdfAnnotation? get selectedAnnotation => _selectedAnnotation;

  PdfAnnotation? _liveAnnotation;
  PdfAnnotation? get liveAnnotation => _liveAnnotation;

  String? _documentPassword;
  String? get documentPassword => _documentPassword;
  void setDocumentPassword(String? password) {
    _documentPassword = password;
  }

  // --- Interactive AcroForm Fields ---
  final List<PdfFormField> _formFields = [];
  List<PdfFormField> get formFields => List.unmodifiable(_formFields);
  List<PdfFormField> getFormFieldsForPage(int pageNumber) =>
      _formFields.where((f) => f.pageNumber == pageNumber).toList();
  bool get hasFormFields => _formFields.isNotEmpty;

  // --- Annotations & Page States ---
  final Map<int, List<PdfAnnotation>> _annotations = {};
  final Map<int, PdfPageState> _pageStates = {};
  List<int> _pageOrder = [];
  List<int> get pageOrder => List.unmodifiable(_pageOrder);

  // --- History (Undo / Redo) ---
  final List<HistoryAction> _undoStack = [];
  final List<HistoryAction> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // --- UI State ---
  bool _isSearchVisible = false;
  bool get isSearchVisible => _isSearchVisible;

  bool _isThumbnailDrawerOpen = false;
  bool get isThumbnailDrawerOpen => _isThumbnailDrawerOpen;

  // =========================================================================
  // Document Lifecycle
  // =========================================================================

  /// Loads a new document from [source].
  void loadSource(PdfDocumentSource source) {
    _source = source;
    _isLoading = true;
    _annotations.clear();
    _formFields.clear();
    _pageStates.clear();
    _pageOrder.clear();
    _undoStack.clear();
    _redoStack.clear();
    _selectedAnnotation = null;
    _liveAnnotation = null;
    _documentPassword = null;
    _currentPage = 1;
    notifyListeners();
  }

  /// Internal callback when pdfrx finishes loading the document.
  void onDocumentLoaded(PdfDocument doc) {
    _document = doc;
    _isLoading = false;
    _pageCount = doc.pages.length;
    _pageOrder = List.generate(_pageCount, (i) => i + 1);

    for (int i = 1; i <= _pageCount; i++) {
      final page = doc.pages[i - 1];
      _pageStates[i] = PdfPageState(
        pageNumber: i,
        originalWidth: page.width,
        originalHeight: page.height,
      );
    }
    notifyListeners();
    _extractFormFields();
  }

  Future<void> _extractFormFields() async {
    if (_source == null) return;
    try {
      final bytes = await _source!.loadBytes();
      final extracted = await PdfFormService.extractFormFields(
        bytes,
        password: _documentPassword,
      );
      if (extracted.isNotEmpty) {
        _formFields.clear();
        _formFields.addAll(extracted);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('PdfEditorController._extractFormFields error: $e\n$st');
    }
  }

  /// Updates current page number when user scrolls in viewer.
  void onPageChanged(int pageNumber) {
    if (_currentPage != pageNumber) {
      _currentPage = pageNumber;
      notifyListeners();
    }
  }

  // =========================================================================
  // Tool & Property Controls
  // =========================================================================

  void setTool(PdfToolType tool) {
    if (_activeTool != tool) {
      _activeTool = tool;
      if (tool != PdfToolType.select) {
        _selectedAnnotation = null;
      }
      _liveAnnotation = null;
      notifyListeners();
    }
  }

  void setColor(Color color) {
    _currentColor = color;
    if (_selectedAnnotation != null) {
      final updated = _selectedAnnotation!.copyWith(color: color);
      updateAnnotation(_selectedAnnotation!, updated);
    }
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    if (_selectedAnnotation is SignatureAnnotation) {
      final selected = _selectedAnnotation as SignatureAnnotation;
      final updated = selected.copyWith(strokeWidth: width);
      updateAnnotation(selected, updated);
    } else if (_selectedAnnotation is ShapeAnnotation) {
      final selected = _selectedAnnotation as ShapeAnnotation;
      final updated = selected.copyWith(strokeWidth: width);
      updateAnnotation(selected, updated);
    }
    notifyListeners();
  }

  void setOpacity(double opacity) {
    _currentOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setFontSize(double size) {
    _currentFontSize = size;
    if (_selectedAnnotation is TextAnnotation) {
      final selected = _selectedAnnotation as TextAnnotation;
      final updated = selected.copyWith(fontSize: size);
      updateAnnotation(selected, updated);
    }
    notifyListeners();
  }

  void setFontFamily(String family) {
    _currentFontFamily = family;
    if (_selectedAnnotation is TextAnnotation) {
      final selected = _selectedAnnotation as TextAnnotation;
      final updated = selected.copyWith(fontFamily: family);
      updateAnnotation(selected, updated);
    }
    notifyListeners();
  }

  void setShapeType(ShapeType type) {
    _currentShapeType = type;
    notifyListeners();
  }

  void setFillColor(Color? color) {
    _currentFillColor = color;
    notifyListeners();
  }

  void setStampType(StampType stampType, {String? customText}) {
    _currentStampType = stampType;
    _currentCustomStampText = customText;
    notifyListeners();
  }

  void setLiveAnnotation(PdfAnnotation? live) {
    if (_liveAnnotation != live) {
      _liveAnnotation = live;
      notifyListeners();
    }
  }

  // =========================================================================
  // Annotation Management
  // =========================================================================

  List<PdfAnnotation> getAnnotationsForPage(int pageNumber) {
    return _annotations[pageNumber] ?? const [];
  }

  void addAnnotation(PdfAnnotation annotation, {bool recordHistory = true}) {
    final list = _annotations.putIfAbsent(annotation.pageNumber, () => []);
    list.add(annotation);
    _annotations[annotation.pageNumber] = List.from(list);

    if (recordHistory) {
      _undoStack.add(AddAnnotationAction(annotation));
      _redoStack.clear();
    }
    notifyListeners();
  }

  void removeAnnotation(PdfAnnotation annotation, {bool recordHistory = true}) {
    final list = _annotations[annotation.pageNumber];
    if (list != null) {
      final removed = list.remove(annotation);
      if (removed) {
        _annotations[annotation.pageNumber] = List.from(list);
        if (_selectedAnnotation?.id == annotation.id) {
          _selectedAnnotation = null;
        }
        if (recordHistory) {
          _undoStack.add(RemoveAnnotationAction(annotation));
          _redoStack.clear();
        }
        notifyListeners();
      }
    }
  }

  void updateAnnotation(
    PdfAnnotation oldAnnotation,
    PdfAnnotation newAnnotation, {
    bool recordHistory = true,
  }) {
    final list = _annotations[oldAnnotation.pageNumber];
    if (list != null) {
      final index = list.indexWhere((a) => a.id == oldAnnotation.id);
      if (index != -1) {
        list[index] = newAnnotation;
        _annotations[oldAnnotation.pageNumber] = List.from(list);
        if (_selectedAnnotation?.id == oldAnnotation.id) {
          _selectedAnnotation = newAnnotation;
        }
        if (recordHistory) {
          _undoStack.add(ModifyAnnotationAction(
            oldAnnotation: oldAnnotation,
            newAnnotation: newAnnotation,
          ));
          _redoStack.clear();
        }
        notifyListeners();
      }
    }
  }

  void selectAnnotation(PdfAnnotation? annotation) {
    _selectedAnnotation = annotation;
    notifyListeners();
  }

  void clearAnnotationsForPage(int pageNumber) {
    final list = _annotations[pageNumber];
    if (list != null && list.isNotEmpty) {
      final saved = List<PdfAnnotation>.from(list);
      list.clear();
      _undoStack.add(ClearPageAnnotationsAction(
        pageNumber: pageNumber,
        annotations: saved,
      ));
      _redoStack.clear();
      _selectedAnnotation = null;
      notifyListeners();
    }
  }

  void clearAllAnnotations() {
    _annotations.clear();
    _selectedAnnotation = null;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // =========================================================================
  // Interactive AcroForm Controls
  // =========================================================================

  /// Optional listener for form submission feedback.
  void Function(bool isValid, String message)? onFormSubmitCallback;

  /// Updates or replaces the active list of interactive form fields.
  void setFormFields(List<PdfFormField> fields) {
    _formFields.clear();
    _formFields.addAll(fields);
    _recalculateFormulas();
    notifyListeners();
  }

  /// Updates the value of a form field by its [fieldName].
  /// Supports text fields, checkboxes, radios, dropdowns, and listboxes.
  void updateFormFieldValue(String fieldName, dynamic newValue, {bool recordHistory = true}) {
    final idx = _formFields.indexWhere((f) => f.name == fieldName);
    if (idx < 0) return;

    final old = _formFields[idx];
    PdfFormField updated;

    if (old is PdfTextFormField) {
      updated = old.copyWith(
        value: newValue.toString(),
        clearValidationError: true,
      );
    } else if (old is PdfCheckBoxFormField) {
      updated = old.copyWith(
        isChecked: newValue as bool,
        clearValidationError: true,
      );
    } else if (old is PdfRadioGroupFormField) {
      final valStr = newValue.toString();
      final cleanVal = valStr.toLowerCase().replaceAll('/', '');
      int itemIdx = old.items.indexWhere((it) {
        final itVal = it.value.toLowerCase().replaceAll('/', '');
        return itVal == cleanVal || it.value == valStr;
      });
      if (itemIdx < 0 && int.tryParse(valStr) != null) {
        final parsed = int.parse(valStr);
        if (parsed >= 0 && parsed < old.items.length) {
          itemIdx = parsed;
        }
      }
      final matchedVal = itemIdx >= 0 ? old.items[itemIdx].value : valStr;
      updated = old.copyWith(
        selectedValue: matchedVal,
        selectedIndex: itemIdx,
        clearValidationError: true,
      );
    } else if (old is PdfDropdownFormField) {
      final valStr = newValue.toString();
      final optIdx = old.options.indexOf(valStr);
      updated = old.copyWith(
        selectedValue: valStr,
        selectedIndex: optIdx,
        clearValidationError: true,
      );
    } else if (old is PdfListBoxFormField) {
      final valStr = newValue.toString();
      final optIdx = old.options.indexOf(valStr);
      updated = old.copyWith(
        selectedValue: valStr,
        selectedIndex: optIdx,
        selectedValues: [valStr],
        clearValidationError: true,
      );
    } else {
      return;
    }

    if (recordHistory) {
      _undoStack.add(UpdateFormFieldAction(oldField: old, newField: updated));
      _redoStack.clear();
    }

    _formFields[idx] = updated;

    // Trigger auto-calculation if a calculation field was updated
    if (fieldName.toLowerCase().contains('calc')) {
      _recalculateFormulas();
    }

    notifyListeners();
  }

  /// Evaluates and recalculates formula fields (e.g. [calc1] + [calc2] = [calcsum]).
  void _recalculateFormulas() {
    final sumIdx = _formFields.indexWhere((f) => f.name.toLowerCase() == 'calcsum');
    if (sumIdx >= 0) {
      final calc1Idx = _formFields.indexWhere((f) => f.name.toLowerCase() == 'calc1');
      final calc2Idx = _formFields.indexWhere((f) => f.name.toLowerCase() == 'calc2');

      double val1 = 0;
      double val2 = 0;
      if (calc1Idx >= 0 && _formFields[calc1Idx] is PdfTextFormField) {
        val1 = double.tryParse((_formFields[calc1Idx] as PdfTextFormField).value.trim()) ?? 0;
      }
      if (calc2Idx >= 0 && _formFields[calc2Idx] is PdfTextFormField) {
        val2 = double.tryParse((_formFields[calc2Idx] as PdfTextFormField).value.trim()) ?? 0;
      }

      final sum = val1 + val2;
      final sumStr = sum == sum.truncateToDouble() ? sum.toInt().toString() : sum.toString();
      final oldSum = _formFields[sumIdx];
      if (oldSum is PdfTextFormField && oldSum.value != sumStr) {
        _formFields[sumIdx] = oldSum.copyWith(value: sumStr);
      }
    }
  }

  /// Validates all required and format-checked fields in the form.
  /// Sets [validationError] on invalid fields and returns `true` if all fields pass.
  bool validateForm() {
    bool allValid = true;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    for (int i = 0; i < _formFields.length; i++) {
      final f = _formFields[i];
      String? error;

      if (f is PdfTextFormField) {
        final val = f.value.trim();
        final lower = f.name.toLowerCase();
        final isEmail = f.formatType == 'email' || lower.contains('email');
        final isReq = f.isRequired || lower.contains('required') || lower == 'required';

        if (isReq && val.isEmpty) {
          error = 'This field is required';
          allValid = false;
        } else if (isEmail) {
          if (val.isEmpty) {
            error = 'Email is required';
            allValid = false;
          } else if (!emailRegex.hasMatch(val)) {
            error = 'Invalid email format (e.g. name@domain.com)';
            allValid = false;
          }
        }

        if (error != f.validationError) {
          _formFields[i] = f.copyWith(
            validationError: error,
            clearValidationError: error == null,
          );
        }
      }
    }

    notifyListeners();
    return allValid;
  }

  /// Validates a single text field (e.g. on focus lost / blur).
  void validateSingleField(String fieldName) {
    final idx = _formFields.indexWhere((f) => f.name == fieldName);
    if (idx < 0) return;
    final f = _formFields[idx];
    if (f is! PdfTextFormField) return;

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final val = f.value.trim();
    final lower = f.name.toLowerCase();
    final isEmail = f.formatType == 'email' || lower.contains('email');
    final isReq = f.isRequired || lower.contains('required') || lower == 'required';

    String? error;
    if (isReq && val.isEmpty) {
      error = 'This field is required';
    } else if (isEmail && val.isNotEmpty && !emailRegex.hasMatch(val)) {
      error = 'Invalid email format (e.g. name@domain.com)';
    }

    if (error != f.validationError) {
      _formFields[idx] = f.copyWith(
        validationError: error,
        clearValidationError: error == null,
      );
      notifyListeners();
    }
  }

  /// Resets all interactive form fields to initial/default values.
  void resetForm() {
    for (int i = 0; i < _formFields.length; i++) {
      final f = _formFields[i];
      final lowerName = f.name.toLowerCase();

      if (f is PdfTextFormField) {
        String defaultVal = '';
        if (lowerName == 'calcsum') {
          defaultVal = '0';
        } else if (lowerName == 'hidden') {
          defaultVal = 'This is the hidden field';
        } else if (lowerName == 'field-specific') {
          defaultVal = 'Change this text';
        }
        _formFields[i] = f.copyWith(
          value: defaultVal,
          clearValidationError: true,
          isVisible: true,
        );
      } else if (f is PdfCheckBoxFormField) {
        _formFields[i] = f.copyWith(
          isChecked: false,
          clearValidationError: true,
          isVisible: true,
        );
      } else if (f is PdfRadioGroupFormField) {
        _formFields[i] = f.copyWith(
          selectedIndex: -1,
          selectedValue: null,
          clearSelectedValue: true,
          clearValidationError: true,
          isVisible: true,
        );
      } else if (f is PdfDropdownFormField) {
        _formFields[i] = f.copyWith(
          selectedIndex: f.options.isNotEmpty ? 0 : -1,
          selectedValue: f.options.isNotEmpty ? f.options.first : null,
          clearValidationError: true,
          isVisible: true,
        );
      } else if (f is PdfListBoxFormField) {
        _formFields[i] = f.copyWith(
          selectedIndex: -1,
          selectedValue: null,
          clearSelectedValue: true,
          selectedValues: const [],
          clearValidationError: true,
          isVisible: true,
        );
      }
    }
    _recalculateFormulas();
    notifyListeners();
  }

  /// Hides all interactive form fields (inputs, checkboxes, radios, dropdowns, listboxes)
  /// while keeping action buttons visible so the user can click "SHOW FIELD".
  void hideAllFields() {
    for (int i = 0; i < _formFields.length; i++) {
      final f = _formFields[i];
      if (f is! PdfButtonFormField) {
        if (f is PdfTextFormField) {
          _formFields[i] = f.copyWith(isVisible: false);
        } else if (f is PdfCheckBoxFormField) {
          _formFields[i] = f.copyWith(isVisible: false);
        } else if (f is PdfRadioGroupFormField) {
          _formFields[i] = f.copyWith(isVisible: false);
        } else if (f is PdfDropdownFormField) {
          _formFields[i] = f.copyWith(isVisible: false);
        } else if (f is PdfListBoxFormField) {
          _formFields[i] = f.copyWith(isVisible: false);
        }
      }
    }
    notifyListeners();
  }

  /// Shows all interactive form fields on the document.
  void showAllFields() {
    for (int i = 0; i < _formFields.length; i++) {
      final f = _formFields[i];
      if (f is PdfTextFormField) {
        _formFields[i] = f.copyWith(isVisible: true);
      } else if (f is PdfCheckBoxFormField) {
        _formFields[i] = f.copyWith(isVisible: true);
      } else if (f is PdfRadioGroupFormField) {
        _formFields[i] = f.copyWith(isVisible: true);
      } else if (f is PdfDropdownFormField) {
        _formFields[i] = f.copyWith(isVisible: true);
      } else if (f is PdfListBoxFormField) {
        _formFields[i] = f.copyWith(isVisible: true);
      }
    }
    notifyListeners();
  }

  /// Toggles visibility of a field by name (e.g. the 'hidden' field).
  void setFieldVisibility(String fieldName, bool visible) {
    final lower = fieldName.toLowerCase();
    for (int i = 0; i < _formFields.length; i++) {
      if (_formFields[i].name.toLowerCase().contains(lower)) {
        final f = _formFields[i];
        if (f is PdfTextFormField) {
          _formFields[i] = f.copyWith(isVisible: visible);
        } else if (f is PdfCheckBoxFormField) {
          _formFields[i] = f.copyWith(isVisible: visible);
        } else if (f is PdfRadioGroupFormField) {
          _formFields[i] = f.copyWith(isVisible: visible);
        } else if (f is PdfDropdownFormField) {
          _formFields[i] = f.copyWith(isVisible: visible);
        } else if (f is PdfListBoxFormField) {
          _formFields[i] = f.copyWith(isVisible: visible);
        }
      }
    }
    notifyListeners();
  }

  /// Handles interactive button click actions (submit, reset, hide, show, prevpage, nextpage, firstpage, url).
  Future<void> handleButtonAction(
    String action, {
    String? url,
    int? targetPage,
    String? targetFieldName,
  }) async {
    final act = action.toLowerCase();
    if (act.contains('submit')) {
      final isValid = validateForm();
      final msg = isValid
          ? 'Form submitted successfully!'
          : 'Validation Error: Please fill in all required fields with valid input.';
      onFormSubmitCallback?.call(isValid, msg);
    } else if (act.contains('reset')) {
      resetForm();
    } else if (act.contains('hide')) {
      final isHideAll = act.contains('all') || (targetFieldName != null && targetFieldName.toLowerCase() == 'all');
      if (isHideAll) {
        hideAllFields();
      } else {
        final target = (targetFieldName != null && targetFieldName.isNotEmpty)
            ? targetFieldName
            : 'field-specific';
        setFieldVisibility(target, false);
      }
    } else if (act.contains('show')) {
      final isShowAll = act.contains('all') || (targetFieldName != null && targetFieldName.toLowerCase() == 'all');
      if (isShowAll) {
        showAllFields();
      } else {
        final target = (targetFieldName != null && targetFieldName.isNotEmpty)
            ? targetFieldName
            : 'field-specific';
        setFieldVisibility(target, true);
      }
    } else if (act.contains('prev')) {
      await previousPage();
    } else if (act.contains('next')) {
      await nextPage();
    } else if (act.contains('first')) {
      await jumpToPage(1);
    } else if (act.contains('google') || act.contains('url') || act.contains('uri') || (url != null && url.isNotEmpty)) {
      final targetUrl = url ?? 'https://www.google.com';
      try {
        final uri = Uri.parse(targetUrl);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Failed to launch URL: $e');
        onFormSubmitCallback?.call(false, 'Failed to open $targetUrl: $e');
      }
    } else if (targetPage != null) {
      await jumpToPage(targetPage);
    }
  }

  // =========================================================================
  // Undo / Redo System
  // =========================================================================

  void undo() {
    if (!canUndo) return;
    final action = _undoStack.removeLast();

    if (action is AddAnnotationAction) {
      final list = _annotations[action.annotation.pageNumber];
      list?.removeWhere((a) => a.id == action.annotation.id);
      if (_selectedAnnotation?.id == action.annotation.id) {
        _selectedAnnotation = null;
      }
      _redoStack.add(action);
    } else if (action is RemoveAnnotationAction) {
      final list = _annotations.putIfAbsent(action.annotation.pageNumber, () => []);
      list.add(action.annotation);
      _redoStack.add(action);
    } else if (action is ModifyAnnotationAction) {
      final list = _annotations[action.newAnnotation.pageNumber];
      if (list != null) {
        final index = list.indexWhere((a) => a.id == action.newAnnotation.id);
        if (index != -1) {
          list[index] = action.oldAnnotation;
          if (_selectedAnnotation?.id == action.newAnnotation.id) {
            _selectedAnnotation = action.oldAnnotation;
          }
        }
      }
      _redoStack.add(action);
    } else if (action is RotatePageAction) {
      final current = _pageStates[action.pageNumber];
      if (current != null) {
        _pageStates[action.pageNumber] =
            current.copyWith(rotation: action.oldRotation);
      }
      _redoStack.add(action);
    } else if (action is DeletePageAction) {
      final current = _pageStates[action.pageNumber];
      if (current != null) {
        _pageStates[action.pageNumber] = current.copyWith(isDeleted: false);
      }
      _annotations[action.pageNumber] = List.from(action.deletedAnnotations);
      _redoStack.add(action);
    } else if (action is ClearPageAnnotationsAction) {
      _annotations[action.pageNumber] = List.from(action.annotations);
      _redoStack.add(action);
    } else if (action is UpdateFormFieldAction) {
      final idx = _formFields.indexWhere((f) => f.name == action.oldField.name);
      if (idx >= 0) {
        _formFields[idx] = action.oldField;
      }
      _redoStack.add(action);
    }

    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final action = _redoStack.removeLast();

    if (action is AddAnnotationAction) {
      final list = _annotations.putIfAbsent(action.annotation.pageNumber, () => []);
      list.add(action.annotation);
      _undoStack.add(action);
    } else if (action is RemoveAnnotationAction) {
      final list = _annotations[action.annotation.pageNumber];
      list?.removeWhere((a) => a.id == action.annotation.id);
      if (_selectedAnnotation?.id == action.annotation.id) {
        _selectedAnnotation = null;
      }
      _undoStack.add(action);
    } else if (action is ModifyAnnotationAction) {
      final list = _annotations[action.oldAnnotation.pageNumber];
      if (list != null) {
        final index = list.indexWhere((a) => a.id == action.oldAnnotation.id);
        if (index != -1) {
          list[index] = action.newAnnotation;
          if (_selectedAnnotation?.id == action.oldAnnotation.id) {
            _selectedAnnotation = action.newAnnotation;
          }
        }
      }
      _undoStack.add(action);
    } else if (action is RotatePageAction) {
      final current = _pageStates[action.pageNumber];
      if (current != null) {
        _pageStates[action.pageNumber] =
            current.copyWith(rotation: action.newRotation);
      }
      _undoStack.add(action);
    } else if (action is DeletePageAction) {
      final current = _pageStates[action.pageNumber];
      if (current != null) {
        _pageStates[action.pageNumber] = current.copyWith(isDeleted: true);
      }
      _annotations.remove(action.pageNumber);
      _undoStack.add(action);
    } else if (action is ClearPageAnnotationsAction) {
      _annotations.remove(action.pageNumber);
      _undoStack.add(action);
    } else if (action is UpdateFormFieldAction) {
      final idx = _formFields.indexWhere((f) => f.name == action.newField.name);
      if (idx >= 0) {
        _formFields[idx] = action.newField;
      }
      _undoStack.add(action);
    }

    notifyListeners();
  }

  // =========================================================================
  // Page Operations (Rotation, Delete, Reorder)
  // =========================================================================

  void rotatePage(int pageNumber, {int degrees = 90}) {
    final state = _pageStates[pageNumber];
    if (state != null) {
      final oldRot = state.rotation;
      final newRot = (oldRot + degrees) % 360;
      _pageStates[pageNumber] = state.copyWith(rotation: newRot);

      _undoStack.add(RotatePageAction(
        pageNumber: pageNumber,
        oldRotation: oldRot,
        newRotation: newRot,
      ));
      _redoStack.clear();
      notifyListeners();
    }
  }

  void deletePage(int pageNumber) {
    final state = _pageStates[pageNumber];
    if (state != null) {
      final deletedAnns = List<PdfAnnotation>.from(_annotations[pageNumber] ?? []);
      _pageStates[pageNumber] = state.copyWith(isDeleted: true);
      _annotations.remove(pageNumber);

      _undoStack.add(DeletePageAction(
        pageNumber: pageNumber,
        deletedAnnotations: deletedAnns,
      ));
      _redoStack.clear();
      notifyListeners();
    }
  }

  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _pageOrder.length ||
        newIndex < 0 ||
        newIndex >= _pageOrder.length) {
      return;
    }
    final item = _pageOrder.removeAt(oldIndex);
    _pageOrder.insert(newIndex, item);
    notifyListeners();
  }

  PdfPageState? getPageState(int pageNumber) => _pageStates[pageNumber];

  // =========================================================================
  // Navigation & Zoom
  // =========================================================================

  Future<void> jumpToPage(int pageNumber) async {
    if (pageNumber >= 1 && pageNumber <= _pageCount) {
      _currentPage = pageNumber;
      await _pdfrxController.goToPage(pageNumber: pageNumber);
      notifyListeners();
    }
  }

  Future<void> nextPage() async {
    if (_currentPage < _pageCount) {
      await jumpToPage(_currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await jumpToPage(_currentPage - 1);
    }
  }

  Future<void> zoomIn() async {
    await _pdfrxController.zoomUp();
  }

  Future<void> zoomOut() async {
    await _pdfrxController.zoomDown();
  }

  Future<void> resetZoom() async {
    await _pdfrxController.setZoom(Offset.zero, 1.0);
  }

  // =========================================================================
  // Search & UI Panels
  // =========================================================================

  void toggleSearch() {
    _isSearchVisible = !_isSearchVisible;
    if (!_isSearchVisible) {
      _textSearcher.resetTextSearch();
    }
    notifyListeners();
  }

  void toggleThumbnailDrawer() {
    _isThumbnailDrawerOpen = !_isThumbnailDrawerOpen;
    notifyListeners();
  }

  // =========================================================================
  // Export & Print
  // =========================================================================

  /// Exports the edited document with overlaid annotations as PDF bytes.
  /// If [flattenForms] is false (default), interactive form fields remain
  /// editable and interactive in the exported PDF, with user modifications saved.
  Future<Uint8List> exportPdf({
    double dpi = 150.0,
    bool flattenForms = false,
    PdfPasswordProvider? passwordProvider,
  }) async {
    if (_source == null) {
      throw StateError('Cannot export: No source document loaded.');
    }
    return await PdfExporter.export(
      source: _source!,
      annotations: _annotations,
      formFields: _formFields,
      pageStates: _pageStates,
      pageOrder: _pageOrder,
      dpi: dpi,
      flattenForms: flattenForms,
      passwordProvider: passwordProvider ??
          (_documentPassword != null ? () => _documentPassword : null),
    );
  }

  /// Directly sends the document (including annotations) to the device's
  /// print dialog / printer queue across Android, iOS, Windows, macOS, Linux, Web.
  Future<void> printPdf({String? documentName}) async {
    final pdfBytes = await exportPdf();
    await Printing.layoutPdf(
      name: documentName ?? _source?.name ?? 'document.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  // =========================================================================
  // JSON Serialization of Annotations
  // =========================================================================

  /// Serializes all annotations to a JSON string for persisting to a database or server.
  String exportAnnotationsJson() {
    final map = <String, dynamic>{};
    for (final entry in _annotations.entries) {
      map[entry.key.toString()] =
          entry.value.map((ann) => ann.toJson()).toList();
    }
    return jsonEncode(map);
  }

  /// Imports annotations from a previously exported JSON string.
  void importAnnotationsJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    _annotations.clear();

    for (final entry in decoded.entries) {
      final pageNum = int.parse(entry.key);
      final rawList = entry.value as List;
      _annotations[pageNum] = rawList
          .map((item) => PdfAnnotation.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _textSearcher.dispose();
    super.dispose();
  }
}
