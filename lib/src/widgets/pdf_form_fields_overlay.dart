import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../controller/pdf_editor_controller.dart';
import '../models/pdf_form_field.dart';
import '../models/tool_type.dart';

/// Overlay widget that renders interactive, touch/mouse-accessible Flutter widgets
/// directly over PDF AcroForm fields (Text inputs, Checkboxes, Radios, Dropdowns, Listboxes, Buttons).
class PdfFormFieldsOverlay extends StatelessWidget {
  const PdfFormFieldsOverlay({
    super.key,
    required this.controller,
    required this.pageNumber,
    required this.pageSize,
    required this.page,
  });

  final PdfEditorController controller;
  final int pageNumber;
  final Size pageSize;
  final PdfPage page;

  @override
  Widget build(BuildContext context) {
    if (page.width <= 0 || page.height <= 0) return const SizedBox.shrink();

    final scaleX = pageSize.width / page.width;
    final scaleY = pageSize.height / page.height;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final fields = controller.getFormFieldsForPage(pageNumber);
        if (fields.isEmpty) return const SizedBox.shrink();

        final isDrawing = controller.activeTool == PdfToolType.draw ||
            controller.activeTool == PdfToolType.highlighter ||
            controller.activeTool == PdfToolType.eraser ||
            controller.activeTool == PdfToolType.shape;

        final overlayChildren = <Widget>[];
        for (final field in fields) {
          if (!field.isVisible) continue;
          overlayChildren.addAll(_buildFieldWidgets(context, field, scaleX, scaleY));
        }

        return IgnorePointer(
          ignoring: isDrawing,
          child: Stack(
            children: overlayChildren,
          ),
        );
      },
    );
  }

  List<Widget> _buildFieldWidgets(
    BuildContext context,
    PdfFormField field,
    double scaleX,
    double scaleY,
  ) {
    if (field is PdfTextFormField) {
      return [_buildTextField(context, field, scaleX, scaleY)];
    } else if (field is PdfCheckBoxFormField) {
      return [_buildCheckBoxField(context, field, scaleX, scaleY)];
    } else if (field is PdfRadioGroupFormField) {
      return _buildRadioGroupWidgets(context, field, scaleX, scaleY);
    } else if (field is PdfDropdownFormField) {
      return [_buildDropdownField(context, field, scaleX, scaleY)];
    } else if (field is PdfListBoxFormField) {
      return [_buildListBoxField(context, field, scaleX, scaleY)];
    } else if (field is PdfButtonFormField) {
      return [_buildButtonField(context, field, scaleX, scaleY)];
    }
    return const [];
  }

  Widget _buildTextField(
    BuildContext context,
    PdfTextFormField field,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTWH(
      field.bounds.left * scaleX,
      field.bounds.top * scaleY,
      field.bounds.width * scaleX,
      field.bounds.height * scaleY,
    );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: _PdfInlineTextField(
        field: field,
        scaleY: scaleY,
        onChanged: (newVal) {
          controller.updateFormFieldValue(field.name, newVal);
        },
        onBlur: (val) {
          controller.validateSingleField(field.name);
        },
      ),
    );
  }

  Widget _buildCheckBoxField(
    BuildContext context,
    PdfCheckBoxFormField field,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTWH(
      field.bounds.left * scaleX,
      field.bounds.top * scaleY,
      field.bounds.width * scaleX,
      field.bounds.height * scaleY,
    );

    final hasError = field.validationError != null;

    final hitHeight = math.max(rect.height + 8.0, 26.0);
    final hitTop = rect.top - (hitHeight - rect.height) / 2;
    final hitWidth = rect.width + 100.0;

    final hitRect = Rect.fromLTWH(
      rect.left,
      hitTop,
      hitWidth,
      hitHeight,
    );

    return Positioned(
      left: hitRect.left,
      top: hitRect.top,
      width: hitRect.width,
      height: hitRect.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: field.isReadOnly
            ? null
            : () {
                controller.updateFormFieldValue(field.name, !field.isChecked);
              },
        child: MouseRegion(
          cursor: field.isReadOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: SizedBox(
            width: hitRect.width,
            height: hitRect.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: rect.width,
                  height: rect.height,
                  decoration: BoxDecoration(
                    color: field.isChecked ? const Color(0xFF1E88E5) : Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: hasError ? Colors.redAccent : const Color(0xFF1E88E5),
                      width: hasError ? 2.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 1.5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: field.isChecked
                      ? Icon(
                          Icons.check,
                          size: (rect.height * 0.8).clamp(12.0, 24.0),
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRadioGroupWidgets(
    BuildContext context,
    PdfRadioGroupFormField field,
    double scaleX,
    double scaleY,
  ) {
    final pageItems = field.items.where((it) => it.pageNumber == pageNumber).toList();

    return pageItems.map((item) {
      final circleRect = Rect.fromLTWH(
        item.bounds.left * scaleX,
        item.bounds.top * scaleY,
        item.bounds.width * scaleX,
        item.bounds.height * scaleY,
      );

      final hitHeight = math.max(circleRect.height + 10.0, 28.0);
      final hitTop = circleRect.top - (hitHeight - circleRect.height) / 2;
      final hitWidth = circleRect.width + 120.0;

      final hitRect = Rect.fromLTWH(
        circleRect.left,
        hitTop,
        hitWidth,
        hitHeight,
      );

      final sel = field.selectedValue?.toLowerCase().replaceAll('/', '') ?? '';
      final itemVal = item.value.toLowerCase().replaceAll('/', '');
      final isSelected = (sel.isNotEmpty && (sel == itemVal || field.selectedValue == item.value)) ||
          (field.selectedIndex >= 0 &&
              field.selectedIndex < field.items.length &&
              field.items[field.selectedIndex].value.toLowerCase().replaceAll('/', '') == itemVal);

      return Positioned(
        left: hitRect.left,
        top: hitRect.top,
        width: hitRect.width,
        height: hitRect.height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: field.isReadOnly
              ? null
              : () {
                  controller.updateFormFieldValue(field.name, item.value);
                },
          child: MouseRegion(
            cursor: field.isReadOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: SizedBox(
              width: hitRect.width,
              height: hitRect.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: circleRect.width,
                    height: circleRect.height,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF757575),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Container(
                            width: circleRect.width * 0.52,
                            height: circleRect.height * 0.52,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E88E5),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDropdownField(
    BuildContext context,
    PdfDropdownFormField field,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTWH(
      field.bounds.left * scaleX,
      field.bounds.top * scaleY,
      field.bounds.width * scaleX,
      field.bounds.height * scaleY,
    );

    final hasError = field.validationError != null;

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: PopupMenuButton<String>(
        tooltip: field.tooltip ?? 'Select option',
        enabled: !field.isReadOnly,
        position: PopupMenuPosition.under,
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        constraints: BoxConstraints(
          minWidth: rect.width,
        ),
        onSelected: (val) {
          controller.updateFormFieldValue(field.name, val);
        },
        itemBuilder: (ctx) {
          return field.options.map((opt) {
            final isSelected = opt == field.selectedValue;
            return PopupMenuItem<String>(
              value: opt,
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, size: 14, color: Color(0xFF1E88E5)),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: hasError ? Colors.redAccent : const Color(0xFF1E88E5),
              width: hasError ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  field.selectedValue ?? (field.options.isNotEmpty ? field.options.first : ''),
                  style: TextStyle(
                    fontSize: (rect.height * 0.52).clamp(10.0, 15.0),
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: (rect.height * 0.8).clamp(16.0, 22.0),
                color: const Color(0xFF1E88E5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListBoxField(
    BuildContext context,
    PdfListBoxFormField field,
    double scaleX,
    double scaleY,
  ) {
    final rect = Rect.fromLTWH(
      field.bounds.left * scaleX,
      field.bounds.top * scaleY,
      field.bounds.width * scaleX,
      field.bounds.height * scaleY,
    );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: _PdfInlineListBox(
        field: field,
        controller: controller,
        height: rect.height,
      ),
    );
  }

  Widget _buildButtonField(
    BuildContext context,
    PdfButtonFormField field,
    double scaleX,
    double scaleY,
  ) {
    if (field.bounds == Rect.zero) return const SizedBox.shrink();

    final rect = Rect.fromLTWH(
      field.bounds.left * scaleX,
      field.bounds.top * scaleY,
      field.bounds.width * scaleX,
      field.bounds.height * scaleY,
    );

    final action = field.action ?? field.name.toLowerCase();

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Tooltip(
        message: field.tooltip ?? (field.url != null ? field.url! : field.label),
        waitDuration: const Duration(milliseconds: 700),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.black.withOpacity(0.08),
              highlightColor: Colors.black.withOpacity(0.04),
              hoverColor: Colors.black.withOpacity(0.03),
              onTap: () {
                controller.handleButtonAction(
                  action,
                  url: field.url,
                  targetPage: field.targetPage,
                  targetFieldName: field.targetFieldName,
                );
              },
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfInlineTextField extends StatefulWidget {
  const _PdfInlineTextField({
    required this.field,
    required this.scaleY,
    required this.onChanged,
    this.onBlur,
  });

  final PdfTextFormField field;
  final double scaleY;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onBlur;

  @override
  State<_PdfInlineTextField> createState() => _PdfInlineTextFieldState();
}

class _PdfInlineTextFieldState extends State<_PdfInlineTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onBlur?.call(_controller.text);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _PdfInlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.field.value != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.field.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = (widget.field.bounds.height * widget.scaleY * 0.55).clamp(10.0, 18.0);
    final hasError = widget.field.validationError != null;

    final borderColor = hasError
        ? Colors.redAccent
        : (_focusNode.hasFocus
            ? const Color(0xFF1E88E5)
            : const Color(0xFF90CAF9));

    return Tooltip(
      message: widget.field.validationError ?? (widget.field.isRequired ? 'Required' : ''),
      showDuration: const Duration(seconds: 3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: borderColor,
            width: hasError ? 2.0 : (_focusNode.hasFocus ? 1.5 : 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: hasError
                  ? Colors.redAccent.withOpacity(0.18)
                  : Colors.black.withOpacity(0.04),
              blurRadius: hasError ? 4 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: widget.field.isMultiline ? 6 : 2,
        ),
        alignment: widget.field.isMultiline ? Alignment.topLeft : Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.field.isReadOnly,
                obscureText: widget.field.isPassword,
                maxLines: widget.field.isMultiline ? null : 1,
                maxLength: widget.field.maxLength,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black87,
                  height: 1.25,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  counterText: '',
                  hintText: widget.field.isRequired && widget.field.value.isEmpty
                      ? (widget.field.validationError ?? '')
                      : null,
                  hintStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
                onChanged: (val) {
                  widget.onChanged(val);
                },
              ),
            ),
            if (hasError)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PdfInlineListBox extends StatefulWidget {
  const _PdfInlineListBox({
    required this.field,
    required this.controller,
    required this.height,
  });

  final PdfListBoxFormField field;
  final PdfEditorController controller;
  final double height;

  @override
  State<_PdfInlineListBox> createState() => _PdfInlineListBoxState();
}

class _PdfInlineListBoxState extends State<_PdfInlineListBox> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF90CAF9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: widget.field.options.length,
          itemBuilder: (context, index) {
            final opt = widget.field.options[index];
            final isSelected = opt == widget.field.selectedValue ||
                widget.field.selectedValues.contains(opt);

            return Material(
              color: isSelected ? const Color(0xFF1E88E5) : Colors.transparent,
              child: InkWell(
                onTap: widget.field.isReadOnly
                    ? null
                    : () {
                        widget.controller.updateFormFieldValue(widget.field.name, opt);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: (widget.height * 0.18).clamp(9.0, 13.0),
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
