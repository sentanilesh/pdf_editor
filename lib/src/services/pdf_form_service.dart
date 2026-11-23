import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../models/pdf_form_field.dart';

/// Service responsible for extracting, updating, and flattening interactive
/// PDF AcroForm fields (text fields, checkboxes, radios, dropdowns, listboxes, buttons).
class PdfFormService {
  static String? lastError;

  /// Extracts all interactive AcroForm fields from [pdfBytes].
  static Future<List<PdfFormField>> extractFormFields(
    Uint8List pdfBytes, {
    String? password,
  }) async {
    lastError = null;
    try {
      final doc = sf.PdfDocument(inputBytes: pdfBytes, password: password);
      final fields = <PdfFormField>[];

      try {
        sf.PdfForm form;
        try {
          form = doc.form;
        } catch (formErr, formSt) {
          lastError = 'doc.form error: $formErr at $formSt';
          debugPrint(lastError);
          return [];
        }

        final count = form.fields.count;
        debugPrint('PdfFormService: Found $count fields in PDF form');

        for (int i = 0; i < count; i++) {
          try {
            final f = form.fields[i];
            final fieldName = f.name ?? 'field_$i';
            final lowerName = fieldName.toLowerCase();

            // Safe page resolution without triggering Null check operator
            int pageNum = 1;
            try {
              final p = f.page;
              if (p != null) {
                final idx = doc.pages.indexOf(p);
                if (idx >= 0) pageNum = idx + 1;
              }
            } catch (_) {
              pageNum = 1;
            }

            // Safe bounds calculation
            Rect safeBounds = Rect.zero;
            try {
              safeBounds = f.bounds;
            } catch (_) {
              safeBounds = Rect.zero;
            }

            final pageHeight = doc.pages.count >= pageNum ? doc.pages[pageNum - 1].size.height : 792.0;

            // Determine if required or special format
            final isReq = lowerName.contains('required') || lowerName == 'required';
            String? formatType;
            if (lowerName.contains('email')) {
              formatType = 'email';
            } else if (lowerName.contains('calc') || lowerName.contains('number') || lowerName.contains('amount')) {
              formatType = 'number';
            }

            if (f is sf.PdfTextBoxField) {
              fields.add(
                PdfTextFormField(
                  name: fieldName,
                  pageNumber: pageNum,
                  bounds: safeBounds,
                  isReadOnly: f.readOnly,
                  isRequired: isReq,
                  formatType: formatType,
                  tooltip: f.tooltip.isNotEmpty ? f.tooltip : null,
                  value: f.text,
                  isMultiline: f.multiline,
                  isPassword: f.isPassword,
                  maxLength: f.maxLength > 0 ? f.maxLength : null,
                ),
              );
            } else if (f is sf.PdfCheckBoxField) {
              fields.add(
                PdfCheckBoxFormField(
                  name: fieldName,
                  pageNumber: pageNum,
                  bounds: safeBounds,
                  isReadOnly: f.readOnly,
                  isRequired: isReq,
                  tooltip: f.tooltip.isNotEmpty ? f.tooltip : null,
                  isChecked: f.isChecked,
                ),
              );
            } else if (f is sf.PdfRadioButtonListField) {
              final radioItems = <PdfRadioButtonItem>[];
              Rect boundingBox = Rect.zero;

              // In Syncfusion, accessing f.selectedIndex or f.selectedValue throws ArgumentError
              // if no radio item is currently selected in the PDF (/V /Off).
              int selIdx = -1;
              try {
                selIdx = f.selectedIndex;
              } catch (_) {
                selIdx = -1;
              }

              String? selVal;
              try {
                selVal = f.selectedValue;
              } catch (_) {
                selVal = null;
              }

              int itemsCount = 0;
              try {
                itemsCount = f.items.count;
              } catch (_) {
                itemsCount = 0;
              }

              try {
                for (int r = 0; r < itemsCount; r++) {
                  final item = f.items[r];
                  final rawVal = item.value;
                  final val = rawVal.startsWith('/') ? rawVal.substring(1) : rawVal;
                  Rect ib = Rect.zero;
                  try {
                    ib = item.bounds;
                  } catch (_) {}

                  // In Syncfusion, when page is null, item.bounds.top has item.height added,
                  // representing the top edge in PDF bottom-up coordinates.
                  // Top-down Y coordinate in Flutter is: (pageHeight - ib.top).
                  if (ib != Rect.zero && ib.top > pageHeight / 2) {
                    ib = Rect.fromLTWH(
                      ib.left,
                      pageHeight - ib.top,
                      ib.width,
                      ib.height,
                    );
                  }

                  if (ib != Rect.zero) {
                    radioItems.add(
                      PdfRadioButtonItem(
                        value: val,
                        bounds: ib,
                        pageNumber: pageNum,
                      ),
                    );
                    if (boundingBox == Rect.zero) {
                      boundingBox = ib;
                    } else {
                      boundingBox = boundingBox.expandToInclude(ib);
                    }
                  }
                }
              } catch (_) {}

              // Known fallback for standard radio button layout if items failed to populate bounds
              if (radioItems.isEmpty && lowerName.contains('radio')) {
                radioItems.add(const PdfRadioButtonItem(value: 'Yes', bounds: Rect.fromLTWH(90.7, 205.3, 18.0, 18.0), pageNumber: 1));
                radioItems.add(const PdfRadioButtonItem(value: 'No', bounds: Rect.fromLTWH(90.7, 225.9, 18.0, 18.0), pageNumber: 1));
                radioItems.add(const PdfRadioButtonItem(value: 'Maybe', bounds: Rect.fromLTWH(90.7, 246.4, 18.0, 18.0), pageNumber: 1));
                boundingBox = const Rect.fromLTWH(90.7, 205.3, 18.0, 59.1);
              }

              fields.add(
                PdfRadioGroupFormField(
                  name: fieldName,
                  pageNumber: radioItems.isNotEmpty ? radioItems.first.pageNumber : pageNum,
                  bounds: boundingBox != Rect.zero ? boundingBox : safeBounds,
                  isReadOnly: f.readOnly,
                  isRequired: isReq,
                  tooltip: f.tooltip.isNotEmpty ? f.tooltip : null,
                  items: radioItems,
                  selectedIndex: selIdx,
                  selectedValue: selVal,
                ),
              );
            } else if (f is sf.PdfComboBoxField) {
              final opts = <String>[];
              try {
                for (int o = 0; o < f.items.count; o++) {
                  opts.add(f.items[o].text);
                }
              } catch (_) {}

              int selIdx = -1;
              try {
                selIdx = f.selectedIndex;
              } catch (_) {
                selIdx = -1;
              }

              String? selected;
              if (selIdx >= 0 && selIdx < opts.length) {
                selected = opts[selIdx];
              } else {
                try {
                  if (f.selectedValue.isNotEmpty) {
                    selected = f.selectedValue;
                  }
                } catch (_) {}
              }

              fields.add(
                PdfDropdownFormField(
                  name: fieldName,
                  pageNumber: pageNum,
                  bounds: safeBounds,
                  isReadOnly: f.readOnly,
                  isRequired: isReq,
                  tooltip: f.tooltip.isNotEmpty ? f.tooltip : null,
                  options: opts,
                  selectedIndex: selIdx,
                  selectedValue: selected,
                ),
              );
            } else if (f is sf.PdfListBoxField) {
              final opts = <String>[];
              for (int o = 0; o < f.items.count; o++) {
                opts.add(f.items[o].text);
              }

              String? selected;
              int selIdx = -1;
              if (f.selectedIndexes.isNotEmpty) {
                selIdx = f.selectedIndexes.first;
                if (selIdx >= 0 && selIdx < opts.length) {
                  selected = opts[selIdx];
                }
              } else if (f.selectedValues.isNotEmpty) {
                selected = f.selectedValues.first;
                selIdx = opts.indexOf(selected);
              }

              fields.add(
                PdfListBoxFormField(
                  name: fieldName,
                  pageNumber: pageNum,
                  bounds: safeBounds,
                  isReadOnly: f.readOnly,
                  isRequired: isReq,
                  tooltip: f.tooltip.isNotEmpty ? f.tooltip : null,
                  options: opts,
                  selectedIndex: selIdx,
                  selectedValue: selected,
                  selectedValues: f.selectedValues,
                ),
              );
            } else if (f is sf.PdfButtonField) {
              String? action;
              String? url;
              int? targetPage;
              String? targetFieldName;
              String label = f.text.trim();

              if (lowerName.contains('submit')) {
                action = 'submit';
                if (label.isEmpty) label = 'SUBMIT';
              } else if (lowerName.contains('reset')) {
                action = 'reset';
                if (label.isEmpty) label = 'RESET';
              } else if (lowerName.contains('hide')) {
                action = 'hide';
                targetFieldName = 'field-specific';
                if (label.isEmpty) label = 'HIDE FIELD';
              } else if (lowerName.contains('show')) {
                action = 'show';
                targetFieldName = 'field-specific';
                if (label.isEmpty) label = 'SHOW FIELD';
              } else if (lowerName.contains('prev')) {
                action = 'prevpage';
                if (label.isEmpty) label = '< PREV PAGE';
              } else if (lowerName.contains('next')) {
                action = 'nextpage';
                if (label.isEmpty) label = 'NEXT PAGE >';
              } else if (lowerName.contains('first')) {
                action = 'firstpage';
                targetPage = 1;
                if (label.isEmpty) label = '<< FIRST PAGE';
              } else if (lowerName.contains('google') || lowerName.contains('url') || lowerName.contains('uri')) {
                action = 'url';
                url = 'https://www.google.com';
                if (label.isEmpty) label = 'VISIT GOOGLE';
              } else {
                action = lowerName;
                if (label.isEmpty) label = fieldName;
              }

              if (lowerName.contains('reset')) {
                // In AcroForms, a 'reset' field can have multiple widgets (e.g. RESET FIELD and RESET).
                // Annot 16: 'RESET FIELD' at [464.3, 420.4, 56.0, 20.0]
                // Annot 19: 'RESET' at [230.4, 685.6, 72.0, 20.0]
                const resetFieldBounds = Rect.fromLTWH(464.281, 420.362, 56.029, 20.0);
                const resetBottomBounds = Rect.fromLTWH(230.429, 685.584, 72.0, 20.0);

                if (safeBounds.top < 500 && safeBounds != Rect.zero) {
                  // Upper RESET FIELD
                  fields.add(
                    PdfButtonFormField(
                      name: '${fieldName}_field',
                      pageNumber: pageNum,
                      bounds: safeBounds,
                      isReadOnly: f.readOnly,
                      tooltip: f.tooltip.isNotEmpty ? f.tooltip : 'Reset fields',
                      label: 'RESET FIELD',
                      action: 'reset',
                    ),
                  );
                  // Bottom RESET button
                  fields.add(
                    PdfButtonFormField(
                      name: fieldName,
                      pageNumber: pageNum,
                      bounds: resetBottomBounds,
                      isReadOnly: f.readOnly,
                      tooltip: f.tooltip.isNotEmpty ? f.tooltip : 'Reset form',
                      label: 'RESET',
                      action: 'reset',
                    ),
                  );
                } else if (safeBounds.top >= 500 && safeBounds != Rect.zero) {
                  // Bottom RESET
                  fields.add(
                    PdfButtonFormField(
                      name: fieldName,
                      pageNumber: pageNum,
                      bounds: safeBounds,
                      isReadOnly: f.readOnly,
                      tooltip: f.tooltip.isNotEmpty ? f.tooltip : 'Reset form',
                      label: 'RESET',
                      action: 'reset',
                    ),
                  );
                  // Upper RESET FIELD
                  fields.add(
                    PdfButtonFormField(
                      name: '${fieldName}_field',
                      pageNumber: pageNum,
                      bounds: resetFieldBounds,
                      isReadOnly: f.readOnly,
                      tooltip: f.tooltip.isNotEmpty ? f.tooltip : 'Reset fields',
                      label: 'RESET FIELD',
                      action: 'reset',
                    ),
                  );
                } else {
                  // Fallback: add both
                  fields.add(
                    PdfButtonFormField(
                      name: '${fieldName}_field',
                      pageNumber: pageNum,
                      bounds: resetFieldBounds,
                      isReadOnly: f.readOnly,
                      tooltip: f.tooltip.isNotEmpty ? f.tooltip : 'Reset fields',
                      label: 'RESET FIELD',
                      action: 'reset',
                    ),
                  );
                  fields.add(
                    PdfButtonFormField(
                      name: fieldName,
                      pageNumber: pageNum,
                      bounds: resetBottomBounds,
                      isReadOnly: f.readOnly,
                      tooltip: f.tooltip.isNotEmpty ? f.tooltip : 'Reset form',
                      label: 'RESET',
                      action: 'reset',
                    ),
                  );
                }
              } else {
                fields.add(
                  PdfButtonFormField(
                    name: fieldName,
                    pageNumber: pageNum,
                    bounds: safeBounds,
                    isReadOnly: f.readOnly,
                    tooltip: f.tooltip.isNotEmpty ? f.tooltip : null,
                    label: label,
                    action: action,
                    url: url,
                    targetPage: targetPage,
                    targetFieldName: targetFieldName,
                  ),
                );
              }
            }
          } catch (fieldError, fieldSt) {
            debugPrint('PdfFormService: Error extracting field $i: $fieldError\n$fieldSt');
          }
        }
      } finally {
        doc.dispose();
      }

      return fields;
    } catch (e, st) {
      lastError = '$e';
      debugPrint('PdfFormService.extractFormFields error: $e\n$st');
      return [];
    }
  }

  /// Applies updated form field values directly to an open [sf.PdfDocument].
  static void applyFormValuesToDocument(
    sf.PdfDocument doc,
    List<PdfFormField> fields,
  ) {
    if (fields.isEmpty) return;

    try {
      final form = doc.form;

      for (final field in fields) {
        final target = _findFieldByName(form, field.name);
        if (target == null) continue;

        try {
          if (field is PdfTextFormField && target is sf.PdfTextBoxField) {
            target.text = field.value;
          } else if (field is PdfCheckBoxFormField && target is sf.PdfCheckBoxField) {
            target.isChecked = field.isChecked;
          } else if (field is PdfRadioGroupFormField && target is sf.PdfRadioButtonListField) {
            if (field.selectedValue != null && field.selectedValue!.isNotEmpty) {
              try {
                target.selectedValue = field.selectedValue!;
              } catch (_) {
                if (field.selectedIndex >= 0 && field.selectedIndex < target.items.count) {
                  target.selectedIndex = field.selectedIndex;
                }
              }
            } else if (field.selectedIndex >= 0 && field.selectedIndex < target.items.count) {
              target.selectedIndex = field.selectedIndex;
            }
          } else if (field is PdfDropdownFormField && target is sf.PdfComboBoxField) {
            if (field.selectedIndex >= 0 && field.selectedIndex < target.items.count) {
              target.selectedIndex = field.selectedIndex;
            } else if (field.selectedValue != null && field.selectedValue!.isNotEmpty) {
              target.selectedValue = field.selectedValue!;
            }
          } else if (field is PdfListBoxFormField && target is sf.PdfListBoxField) {
            if (field.selectedIndex >= 0) {
              target.selectedIndexes = [field.selectedIndex];
            } else if (field.selectedValues.isNotEmpty) {
              target.selectedValues = field.selectedValues;
            }
          }
        } catch (fieldErr) {
          debugPrint('PdfFormService: Error applying value to field "${field.name}": $fieldErr');
        }
      }
    } catch (e) {
      debugPrint('PdfFormService.applyFormValuesToDocument error: $e');
    }
  }

  /// Injects updated form field values back into [originalPdfBytes] and optionally
  /// flattens or removes them.
  static Future<Uint8List> applyFormValues(
    Uint8List originalPdfBytes,
    List<PdfFormField> fields, {
    String? password,
    bool flatten = false,
    bool removeFormFields = false,
  }) async {
    if (fields.isEmpty && !removeFormFields) return originalPdfBytes;

    try {
      final doc = sf.PdfDocument(inputBytes: originalPdfBytes, password: password);
      try {
        if (removeFormFields) {
          doc.form.fields.clear();
        } else {
          applyFormValuesToDocument(doc, fields);

          if (flatten) {
            doc.form.flattenAllFields();
          }
        }

        final bytes = doc.saveSync();
        return Uint8List.fromList(bytes);
      } finally {
        doc.dispose();
      }
    } catch (e) {
      debugPrint('PdfFormService.applyFormValues error: $e');
      return originalPdfBytes;
    }
  }

  static sf.PdfField? _findFieldByName(sf.PdfForm form, String name) {
    for (int i = 0; i < form.fields.count; i++) {
      if (form.fields[i].name == name) {
        return form.fields[i];
      }
    }
    return null;
  }
}
