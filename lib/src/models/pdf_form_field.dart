import 'package:material_ui/material_ui.dart';

/// Supported types of interactive PDF AcroForm fields.
enum PdfFormFieldType {
  text,
  checkbox,
  radio,
  dropdown,
  listbox,
  button,
}

/// Base abstract class for an interactive PDF form field item.
abstract class PdfFormField {
  const PdfFormField({
    required this.name,
    required this.pageNumber,
    required this.bounds,
    this.isReadOnly = false,
    this.isRequired = false,
    this.isVisible = true,
    this.validationError,
    this.tooltip,
  });

  /// Unique field identifier/name in the PDF AcroForm dictionary.
  final String name;

  /// 1-based page number where this field is located.
  final int pageNumber;

  /// Bounding rectangle in unscaled PDF points.
  final Rect bounds;

  /// Whether the field is marked read-only in the PDF.
  final bool isReadOnly;

  /// Whether the field is required to have a value before submitting.
  final bool isRequired;

  /// Whether the field is currently visible.
  final bool isVisible;

  /// Active validation error string if invalid, or null if valid.
  final String? validationError;

  /// Optional tooltip or alternate description.
  final String? tooltip;

  /// Field type discriminator.
  PdfFormFieldType get type;

  /// Serializes field state to a JSON-compatible map.
  Map<String, dynamic> toJson();
}

/// Interactive text box / input field in a PDF.
class PdfTextFormField extends PdfFormField {
  const PdfTextFormField({
    required super.name,
    required super.pageNumber,
    required super.bounds,
    super.isReadOnly,
    super.isRequired,
    super.isVisible,
    super.validationError,
    super.tooltip,
    this.value = '',
    this.isMultiline = false,
    this.isPassword = false,
    this.maxLength,
    this.formatType,
  });

  /// Current text entered in this field.
  final String value;

  /// Whether this field supports multiple lines of text.
  final bool isMultiline;

  /// Whether this field is a password input.
  final bool isPassword;

  /// Optional maximum character length.
  final int? maxLength;

  /// Optional format constraint (e.g. 'email', 'number', 'formula').
  final String? formatType;

  @override
  PdfFormFieldType get type => PdfFormFieldType.text;

  PdfTextFormField copyWith({
    String? value,
    bool? isReadOnly,
    bool? isRequired,
    bool? isVisible,
    String? validationError,
    bool clearValidationError = false,
    String? tooltip,
    String? formatType,
  }) {
    return PdfTextFormField(
      name: name,
      pageNumber: pageNumber,
      bounds: bounds,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      validationError:
          clearValidationError ? null : (validationError ?? this.validationError),
      tooltip: tooltip ?? this.tooltip,
      value: value ?? this.value,
      isMultiline: isMultiline,
      isPassword: isPassword,
      maxLength: maxLength,
      formatType: formatType ?? this.formatType,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'name': name,
        'pageNumber': pageNumber,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'value': value,
        'isMultiline': isMultiline,
        'isPassword': isPassword,
        'maxLength': maxLength,
        'isRequired': isRequired,
        'isVisible': isVisible,
        'formatType': formatType,
      };
}

/// Interactive checkbox field in a PDF.
class PdfCheckBoxFormField extends PdfFormField {
  const PdfCheckBoxFormField({
    required super.name,
    required super.pageNumber,
    required super.bounds,
    super.isReadOnly,
    super.isRequired,
    super.isVisible,
    super.validationError,
    super.tooltip,
    this.isChecked = false,
  });

  /// Current checked state.
  final bool isChecked;

  @override
  PdfFormFieldType get type => PdfFormFieldType.checkbox;

  PdfCheckBoxFormField copyWith({
    bool? isChecked,
    bool? isReadOnly,
    bool? isRequired,
    bool? isVisible,
    String? validationError,
    bool clearValidationError = false,
    String? tooltip,
  }) {
    return PdfCheckBoxFormField(
      name: name,
      pageNumber: pageNumber,
      bounds: bounds,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      validationError:
          clearValidationError ? null : (validationError ?? this.validationError),
      tooltip: tooltip ?? this.tooltip,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'checkbox',
        'name': name,
        'pageNumber': pageNumber,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'isChecked': isChecked,
        'isRequired': isRequired,
        'isVisible': isVisible,
      };
}

/// Single item within a radio button group.
class PdfRadioButtonItem {
  const PdfRadioButtonItem({
    required this.value,
    required this.bounds,
    required this.pageNumber,
  });

  /// Value represented by this radio item.
  final String value;

  /// Bounding rectangle for this specific radio button.
  final Rect bounds;

  /// Page where this radio button item is positioned.
  final int pageNumber;

  Map<String, dynamic> toJson() => {
        'value': value,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'pageNumber': pageNumber,
      };
}

/// Interactive radio button group field in a PDF.
class PdfRadioGroupFormField extends PdfFormField {
  const PdfRadioGroupFormField({
    required super.name,
    required super.pageNumber,
    required super.bounds,
    super.isReadOnly,
    super.isRequired,
    super.isVisible,
    super.validationError,
    super.tooltip,
    required this.items,
    this.selectedIndex = -1,
    this.selectedValue,
  });

  /// List of radio choices in this group.
  final List<PdfRadioButtonItem> items;

  /// Currently selected option index (-1 for none).
  final int selectedIndex;

  /// Currently selected option value.
  final String? selectedValue;

  @override
  PdfFormFieldType get type => PdfFormFieldType.radio;

  PdfRadioGroupFormField copyWith({
    int? selectedIndex,
    String? selectedValue,
    bool clearSelectedValue = false,
    bool? isReadOnly,
    bool? isRequired,
    bool? isVisible,
    String? validationError,
    bool clearValidationError = false,
    String? tooltip,
  }) {
    return PdfRadioGroupFormField(
      name: name,
      pageNumber: pageNumber,
      bounds: bounds,
      items: items,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      validationError:
          clearValidationError ? null : (validationError ?? this.validationError),
      tooltip: tooltip ?? this.tooltip,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedValue: clearSelectedValue ? null : (selectedValue ?? this.selectedValue),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'radio',
        'name': name,
        'pageNumber': pageNumber,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'items': items.map((i) => i.toJson()).toList(),
        'selectedIndex': selectedIndex,
        'selectedValue': selectedValue,
        'isRequired': isRequired,
        'isVisible': isVisible,
      };
}

/// Interactive combo box / dropdown selection field in a PDF.
class PdfDropdownFormField extends PdfFormField {
  const PdfDropdownFormField({
    required super.name,
    required super.pageNumber,
    required super.bounds,
    super.isReadOnly,
    super.isRequired,
    super.isVisible,
    super.validationError,
    super.tooltip,
    required this.options,
    this.selectedIndex = -1,
    this.selectedValue,
  });

  /// Available dropdown options.
  final List<String> options;

  /// Currently selected index (-1 for none).
  final int selectedIndex;

  /// Currently selected option string.
  final String? selectedValue;

  @override
  PdfFormFieldType get type => PdfFormFieldType.dropdown;

  PdfDropdownFormField copyWith({
    int? selectedIndex,
    String? selectedValue,
    bool? isReadOnly,
    bool? isRequired,
    bool? isVisible,
    String? validationError,
    bool clearValidationError = false,
    String? tooltip,
  }) {
    return PdfDropdownFormField(
      name: name,
      pageNumber: pageNumber,
      bounds: bounds,
      options: options,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      validationError:
          clearValidationError ? null : (validationError ?? this.validationError),
      tooltip: tooltip ?? this.tooltip,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedValue: selectedValue ?? this.selectedValue,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dropdown',
        'name': name,
        'pageNumber': pageNumber,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'options': options,
        'selectedIndex': selectedIndex,
        'selectedValue': selectedValue,
        'isRequired': isRequired,
        'isVisible': isVisible,
      };
}

/// Interactive list box selection field in a PDF.
class PdfListBoxFormField extends PdfFormField {
  const PdfListBoxFormField({
    required super.name,
    required super.pageNumber,
    required super.bounds,
    super.isReadOnly,
    super.isRequired,
    super.isVisible,
    super.validationError,
    super.tooltip,
    required this.options,
    this.selectedIndex = -1,
    this.selectedValue,
    this.selectedValues = const [],
  });

  /// Available choices in the listbox.
  final List<String> options;

  /// Index of currently selected item (-1 for none).
  final int selectedIndex;

  /// Currently selected single item value.
  final String? selectedValue;

  /// List of selected values for multi-select.
  final List<String> selectedValues;

  @override
  PdfFormFieldType get type => PdfFormFieldType.listbox;

  PdfListBoxFormField copyWith({
    int? selectedIndex,
    String? selectedValue,
    List<String>? selectedValues,
    bool clearSelectedValue = false,
    bool? isReadOnly,
    bool? isRequired,
    bool? isVisible,
    String? validationError,
    bool clearValidationError = false,
    String? tooltip,
  }) {
    return PdfListBoxFormField(
      name: name,
      pageNumber: pageNumber,
      bounds: bounds,
      options: options,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      validationError:
          clearValidationError ? null : (validationError ?? this.validationError),
      tooltip: tooltip ?? this.tooltip,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedValue: clearSelectedValue ? null : (selectedValue ?? this.selectedValue),
      selectedValues: clearSelectedValue ? const [] : (selectedValues ?? this.selectedValues),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'listbox',
        'name': name,
        'pageNumber': pageNumber,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'options': options,
        'selectedIndex': selectedIndex,
        'selectedValue': selectedValue,
        'selectedValues': selectedValues,
        'isRequired': isRequired,
        'isVisible': isVisible,
      };
}

/// Interactive push button in a PDF form (e.g. submit, reset, hide, show, prevpage, nextpage, firstpage, url).
class PdfButtonFormField extends PdfFormField {
  const PdfButtonFormField({
    required super.name,
    required super.pageNumber,
    required super.bounds,
    super.isReadOnly,
    super.isRequired,
    super.isVisible,
    super.validationError,
    super.tooltip,
    required this.label,
    this.action,
    this.url,
    this.targetPage,
    this.targetFieldName,
  });

  /// Display text on the button.
  final String label;

  /// Associated form action (e.g. 'submit', 'reset', 'hide', 'show', 'prevpage', 'nextpage', 'firstpage', 'url').
  final String? action;

  /// Target URL to open if this button triggers a web link.
  final String? url;

  /// Target page to jump to if this button is a page jump.
  final int? targetPage;

  /// Target field name for field-specific actions (e.g. hide or show a specific field).
  final String? targetFieldName;

  @override
  PdfFormFieldType get type => PdfFormFieldType.button;

  PdfButtonFormField copyWith({
    String? label,
    String? action,
    String? url,
    int? targetPage,
    String? targetFieldName,
    bool? isReadOnly,
    bool? isRequired,
    bool? isVisible,
    String? validationError,
    bool clearValidationError = false,
    String? tooltip,
  }) {
    return PdfButtonFormField(
      name: name,
      pageNumber: pageNumber,
      bounds: bounds,
      label: label ?? this.label,
      action: action ?? this.action,
      url: url ?? this.url,
      targetPage: targetPage ?? this.targetPage,
      targetFieldName: targetFieldName ?? this.targetFieldName,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      validationError:
          clearValidationError ? null : (validationError ?? this.validationError),
      tooltip: tooltip ?? this.tooltip,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'button',
        'name': name,
        'pageNumber': pageNumber,
        'bounds': [bounds.left, bounds.top, bounds.width, bounds.height],
        'label': label,
        'action': action,
        'url': url,
        'targetPage': targetPage,
        'targetFieldName': targetFieldName,
        'isVisible': isVisible,
      };
}
