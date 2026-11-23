import 'package:flutter/material.dart';

import '../rendering/font_helper.dart';

/// Configuration returned by [TextAnnotationDialog].
class TextAnnotationConfig {
  const TextAnnotationConfig({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
    required this.color,
    this.backgroundColor,
    this.isBold = false,
    this.isItalic = false,
  });

  final String text;
  final double fontSize;
  final String fontFamily;
  final Color color;
  final Color? backgroundColor;
  final bool isBold;
  final bool isItalic;
}

/// Custom-styled, compact dialog for inserting and editing text annotations.
class TextAnnotationDialog extends StatefulWidget {
  const TextAnnotationDialog({
    super.key,
    this.initialText = '',
    this.initialFontSize = 16.0,
    this.initialFontFamily = 'sans-serif',
    this.initialColor = Colors.black87,
    this.initialBackgroundColor,
    this.initialIsBold = false,
    this.initialIsItalic = false,
    this.isEditing = false,
  });

  final String initialText;
  final double initialFontSize;
  final String initialFontFamily;
  final Color initialColor;
  final Color? initialBackgroundColor;
  final bool initialIsBold;
  final bool initialIsItalic;
  final bool isEditing;

  static Future<TextAnnotationConfig?> show(
    BuildContext context, {
    String initialText = '',
    double initialFontSize = 16.0,
    String initialFontFamily = 'sans-serif',
    Color initialColor = Colors.black87,
    Color? initialBackgroundColor,
    bool initialIsBold = false,
    bool initialIsItalic = false,
    bool isEditing = false,
  }) {
    return showDialog<TextAnnotationConfig>(
      context: context,
      barrierDismissible: true,
      builder: (_) => TextAnnotationDialog(
        initialText: initialText,
        initialFontSize: initialFontSize,
        initialFontFamily: initialFontFamily,
        initialColor: initialColor,
        initialBackgroundColor: initialBackgroundColor,
        initialIsBold: initialIsBold,
        initialIsItalic: initialIsItalic,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<TextAnnotationDialog> {
  late final TextEditingController _textController;
  late double _fontSize;
  late String _fontFamily;
  late Color _textColor;
  late Color? _backgroundColor;
  late bool _isBold;
  late bool _isItalic;

  static const List<double> _fontSizes = [
    10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 40.0,
  ];

  static const List<Color> _textColors = [
    Colors.black87,
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFFB300), // Amber
    Color(0xFF8E24AA), // Purple
    Color(0xFFFB8C00), // Orange
    Colors.grey,
  ];

  static const List<MapEntry<String, Color?>> _bgOptions = [
    MapEntry('Transparent', null),
    MapEntry('Yellow Note', Color(0xFFFFF9C4)),
    MapEntry('White Box', Colors.white),
    MapEntry('Light Gray', Color(0xFFF0F0F0)),
    MapEntry('Light Blue', Color(0xFFE3F2FD)),
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _fontSize = widget.initialFontSize;
    _fontFamily = PdfFontHelper.resolveOption(widget.initialFontFamily).id;
    _textColor = widget.initialColor;
    _backgroundColor = widget.initialBackgroundColor;
    _isBold = widget.initialIsBold;
    _isItalic = widget.initialIsItalic;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fieldBg = isDark ? const Color(0xFF252528) : const Color(0xFFF5F6F8);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.text_fields_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isEditing ? 'Edit Text' : 'Insert Text',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Custom Input Field
              TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 3,
                style: PdfFontHelper.resolveTextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  isBold: _isBold,
                  isItalic: _isItalic,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type text annotation...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Controls Grid: Font Family, Size, Style (Mobile-responsive layout)
              Builder(
                builder: (context) {
                  final isMobileDialog = MediaQuery.of(context).size.width < 440;

                  final fontTypeDropdown = _CustomDropdown<String>(
                    label: 'Font Type',
                    value: PdfFontHelper.resolveOption(_fontFamily).id,
                    items: PdfFontHelper.options.map((opt) {
                      return DropdownMenuItem(
                        value: opt.id,
                        child: Text(
                          opt.displayName,
                          style: opt.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _fontFamily = val);
                    },
                  );

                  final fontSizeDropdown = _CustomDropdown<double>(
                    label: 'Size',
                    value: _fontSizes.contains(_fontSize) ? _fontSize : 16.0,
                    items: _fontSizes.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text('${s.round()} pt', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _fontSize = val);
                    },
                  );

                  final styleToggle = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Style',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            _StyleToggleButton(
                              icon: Icons.format_bold_rounded,
                              isActive: _isBold,
                              tooltip: 'Bold',
                              onPressed: () => setState(() => _isBold = !_isBold),
                            ),
                            Container(width: 1, height: 20, color: borderColor),
                            _StyleToggleButton(
                              icon: Icons.format_italic_rounded,
                              isActive: _isItalic,
                              tooltip: 'Italic',
                              onPressed: () => setState(() => _isItalic = !_isItalic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (isMobileDialog) {
                    return Column(
                      children: [
                        fontTypeDropdown,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: fontSizeDropdown),
                            const SizedBox(width: 10),
                            styleToggle,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 3, child: fontTypeDropdown),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: fontSizeDropdown),
                      const SizedBox(width: 8),
                      styleToggle,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Color & Background Fill Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Color Palette
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text Color',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _textColors.map((color) {
                            final isSelected = _textColor == color;
                            return InkWell(
                              onTap: () => setState(() => _textColor = color),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 13,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black87
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Background Fill Dropdown
                  Expanded(
                    child: _CustomDropdown<Color?>(
                      label: 'Background',
                      value: _backgroundColor,
                      items: _bgOptions.map((e) {
                        return DropdownMenuItem(
                          value: e.value,
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: e.value ?? Colors.transparent,
                                  border: Border.all(color: Colors.grey.shade400, width: 1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(e.key, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _backgroundColor = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Preview Card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252528) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'PREVIEW',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: _backgroundColor != null
                            ? Border.all(color: Colors.grey.shade300, width: 0.8)
                            : null,
                      ),
                      child: Text(
                        _textController.text.isEmpty
                            ? 'Sample text annotation'
                            : _textController.text,
                        style: PdfFontHelper.resolveTextStyle(
                          fontFamily: _fontFamily,
                          fontSize: _fontSize,
                          color: _textColor,
                          isBold: _isBold,
                          isItalic: _isItalic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: borderColor),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isEmpty) return;
                      Navigator.pop(
                        context,
                        TextAnnotationConfig(
                          text: text,
                          fontSize: _fontSize,
                          fontFamily: _fontFamily,
                          color: _textColor,
                          backgroundColor: _backgroundColor,
                          isBold: _isBold,
                          isItalic: _isItalic,
                        ),
                      );
                    },
                    child: Text(
                      widget.isEditing ? 'Update Text' : 'Insert Text',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDropdown<T> extends StatelessWidget {
  const _CustomDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fieldBg = isDark ? const Color(0xFF252528) : const Color(0xFFF5F6F8);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              borderRadius: BorderRadius.circular(10),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _StyleToggleButton extends StatelessWidget {
  const _StyleToggleButton({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 34,
          alignment: Alignment.center,
          color: isActive
              ? theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.12)
              : Colors.transparent,
          child: Icon(
            icon,
            size: 16,
            color: isActive
                ? theme.colorScheme.primary
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
