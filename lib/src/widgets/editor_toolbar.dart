import 'package:material_ui/material_ui.dart';
import '../controller/pdf_editor_controller.dart';
import '../models/shape_annotation.dart';
import '../models/signature_annotation.dart';
import '../models/text_annotation.dart';
import '../models/tool_type.dart';
import '../rendering/font_helper.dart';

/// Clean, modern, and compact toolbar containing all viewer & editor capabilities.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.controller,
    this.onSave,
    this.onPrint,
    this.isMobile,
  });

  final PdfEditorController controller;
  final VoidCallback? onSave;
  final VoidCallback? onPrint;
  final bool? isMobile;

  static const List<Color> _palette = [
    Colors.black87,
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFFB300), // Amber / Yellow
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Colors.grey,
    Colors.white,
  ];

  static const List<double> _strokePresets = [1.0, 2.0, 3.0, 5.0, 8.0, 12.0];
  static const List<double> _fontPresets = [10.0, 12.0, 14.0, 16.0, 20.0, 24.0, 32.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tool = controller.activeTool;
        final selected = controller.selectedAnnotation;
        final isTextSelected = selected is TextAnnotation;

        final hasColor = tool == PdfToolType.draw ||
            tool == PdfToolType.highlighter ||
            tool == PdfToolType.shape ||
            tool == PdfToolType.text ||
            tool == PdfToolType.signature ||
            selected != null;

        final hasStroke = tool == PdfToolType.draw ||
            tool == PdfToolType.shape ||
            tool == PdfToolType.highlighter ||
            tool == PdfToolType.signature ||
            selected is SignatureAnnotation ||
            selected is ShapeAnnotation;

        final hasFontSize = tool == PdfToolType.text || isTextSelected;
        final hasFontFamily = tool == PdfToolType.text || isTextSelected;

        final screenWidth = MediaQuery.of(context).size.width;
        final effectiveIsMobile = isMobile ?? (screenWidth < 600);

        if (effectiveIsMobile) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnails toggle
                  _CompactIconButton(
                    icon: Icons.view_sidebar_outlined,
                    tooltip: 'Page Thumbnails',
                    isActive: controller.isThumbnailDrawerOpen,
                    onPressed: () => controller.toggleThumbnailDrawer(),
                  ),

                  const _VerticalDivider(),

                  // Page Navigation: < 1 / 2 >
                  _CompactIconButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Previous Page',
                    onPressed: controller.currentPage > 1
                        ? () => controller.previousPage()
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${controller.currentPage} / ${controller.pageCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  _CompactIconButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Next Page',
                    onPressed: controller.currentPage < controller.pageCount
                        ? () => controller.nextPage()
                        : null,
                  ),

                  const _VerticalDivider(),

                  // Zoom Controls: - Fit +
                  _CompactIconButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom Out',
                    onPressed: () => controller.zoomOut(),
                  ),
                  _CompactIconButton(
                    icon: Icons.fit_screen_outlined,
                    tooltip: 'Fit to Page',
                    onPressed: () => controller.resetZoom(),
                  ),
                  _CompactIconButton(
                    icon: Icons.add,
                    tooltip: 'Zoom In',
                    onPressed: () => controller.zoomIn(),
                  ),

                  const _VerticalDivider(),

                  // Undo & Redo
                  _CompactIconButton(
                    icon: Icons.undo,
                    tooltip: 'Undo',
                    onPressed: controller.canUndo ? () => controller.undo() : null,
                  ),
                  _CompactIconButton(
                    icon: Icons.redo,
                    tooltip: 'Redo',
                    onPressed: controller.canRedo ? () => controller.redo() : null,
                  ),

                  const _VerticalDivider(),

                  // Search in Document
                  _CompactIconButton(
                    icon: Icons.search,
                    tooltip: 'Search in Document',
                    isActive: controller.isSearchVisible,
                    onPressed: () => controller.toggleSearch(),
                  ),

                  // Export Button
                  if (onSave != null) ...[
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 14),
                      label: const Text('Export'),
                      onPressed: onSave,
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Thumbnails toggle
                _CompactIconButton(
                  icon: Icons.view_sidebar_outlined,
                  tooltip: 'Page Thumbnails',
                  isActive: controller.isThumbnailDrawerOpen,
                  onPressed: () => controller.toggleThumbnailDrawer(),
                ),

                const _VerticalDivider(),

                // 2. Page Navigation: < 1 / 2 >
                _CompactIconButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Previous Page',
                  onPressed: controller.currentPage > 1
                      ? () => controller.previousPage()
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${controller.currentPage} / ${controller.pageCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                    ),
                  ),
                ),
                _CompactIconButton(
                  icon: Icons.chevron_right,
                  tooltip: 'Next Page',
                  onPressed: controller.currentPage < controller.pageCount
                      ? () => controller.nextPage()
                      : null,
                ),

                const _VerticalDivider(),

                // 3. Zoom controls: - Fit +
                _CompactIconButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onPressed: () => controller.zoomOut(),
                ),
                _CompactIconButton(
                  icon: Icons.fit_screen_outlined,
                  tooltip: 'Reset Zoom (100%)',
                  onPressed: () => controller.resetZoom(),
                ),
                _CompactIconButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onPressed: () => controller.zoomIn(),
                ),

                const _VerticalDivider(),

                // 4. Primary Annotation Tools (Segmented Style)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // View / Hand
                      _CompactToolButton(
                        icon: Icons.pan_tool_outlined,
                        tooltip: 'View & Scroll',
                        isActive: tool == PdfToolType.view,
                        onPressed: () => controller.setTool(PdfToolType.view),
                      ),
                      // Select
                      _CompactToolButton(
                        icon: Icons.near_me_outlined,
                        tooltip: 'Select & Move',
                        isActive: tool == PdfToolType.select,
                        onPressed: () => controller.setTool(PdfToolType.select),
                      ),
                      // Pen
                      _CompactToolButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Pen / Draw',
                        isActive: tool == PdfToolType.draw,
                        onPressed: () => controller.setTool(PdfToolType.draw),
                      ),
                      // Highlighter
                      _CompactToolButton(
                        icon: Icons.highlight_outlined,
                        tooltip: 'Highlighter',
                        isActive: tool == PdfToolType.highlighter,
                        onPressed: () => controller.setTool(PdfToolType.highlighter),
                      ),
                      // Text
                      _CompactToolButton(
                        icon: Icons.title,
                        tooltip: 'Text Box',
                        isActive: tool == PdfToolType.text,
                        onPressed: () => controller.setTool(PdfToolType.text),
                      ),
                      // Shapes dropdown
                      _ShapesMenuButton(controller: controller),
                      // Signature
                      _CompactToolButton(
                        icon: Icons.draw_outlined,
                        tooltip: 'Handwritten Signature',
                        isActive: tool == PdfToolType.signature,
                        onPressed: () => controller.setTool(PdfToolType.signature),
                      ),
                      // Eraser
                      _CompactToolButton(
                        icon: Icons.auto_fix_normal_outlined,
                        tooltip: 'Eraser',
                        isActive: tool == PdfToolType.eraser,
                        onPressed: () => controller.setTool(PdfToolType.eraser),
                      ),
                    ],
                  ),
                ),

                // 5. Contextual Properties Pill (Color & Thickness)
                if (hasColor || hasStroke || hasFontSize) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Color Selector Popup
                        if (hasColor)
                          _ColorPickerPopup(
                            currentColor: controller.currentColor,
                            palette: _palette,
                            onColorSelected: (c) => controller.setColor(c),
                          ),

                        // Stroke Width Selector Popup
                        if (hasStroke) ...[
                          const SizedBox(width: 4),
                          _ValuePickerPopup(
                            label: '${controller.currentStrokeWidth.round()} pt',
                            tooltip: 'Stroke Thickness',
                            values: _strokePresets,
                            currentValue: controller.currentStrokeWidth,
                            onSelected: (v) => controller.setStrokeWidth(v),
                          ),
                        ],

                        // Font Family Selector Popup
                        if (hasFontFamily) ...[
                          const SizedBox(width: 4),
                          _FontFamilyPickerPopup(
                            currentFontFamily: isTextSelected
                                ? selected.fontFamily
                                : controller.currentFontFamily,
                            onSelected: (family) => controller.setFontFamily(family),
                          ),
                        ],

                        // Font Size Selector Popup
                        if (hasFontSize) ...[
                          const SizedBox(width: 4),
                          _ValuePickerPopup(
                            label: '${(isTextSelected ? selected.fontSize : controller.currentFontSize).round()} pt',
                            tooltip: 'Font Size',
                            values: _fontPresets,
                            currentValue: isTextSelected
                                ? selected.fontSize
                                : controller.currentFontSize,
                            onSelected: (v) => controller.setFontSize(v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const _VerticalDivider(),

                // 6. Undo & Redo
                _CompactIconButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  onPressed: controller.canUndo ? () => controller.undo() : null,
                ),
                _CompactIconButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  onPressed: controller.canRedo ? () => controller.redo() : null,
                ),

                const _VerticalDivider(),

                // 7. Search in Document
                _CompactIconButton(
                  icon: Icons.search,
                  tooltip: 'Search in Document',
                  isActive: controller.isSearchVisible,
                  onPressed: () => controller.toggleSearch(),
                ),

                // 8. Save / Export button
                if (onSave != null) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Export PDF'),
                    onPressed: onSave,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Compact Helper Widgets
// ---------------------------------------------------------------------------

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? Colors.white12 : Colors.grey.shade300,
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color iconColor;
    if (onPressed == null) {
      iconColor = isDark ? Colors.white24 : Colors.grey.shade400;
    } else if (isActive) {
      iconColor = theme.colorScheme.primary;
    } else {
      iconColor = isDark ? Colors.white70 : Colors.grey.shade700;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary.withOpacity(0.12) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _CompactToolButton extends StatelessWidget {
  const _CompactToolButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
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
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? theme.colorScheme.primary.withOpacity(0.3) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: isActive
                ? theme.colorScheme.primary
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

class _ShapesMenuButton extends StatelessWidget {
  const _ShapesMenuButton({required this.controller});
  final PdfEditorController controller;

  IconData _iconForShape(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return Icons.rectangle_outlined;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.line:
        return Icons.horizontal_rule;
      case ShapeType.arrow:
        return Icons.arrow_right_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isShapeTool = controller.activeTool == PdfToolType.shape;

    return Material(
      child: PopupMenuButton<ShapeType>(
        tooltip: 'Shapes',
        offset: const Offset(0, 36),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        color: isDark ? const Color(0xFF222225) : Colors.white,
        initialValue: controller.currentShapeType,
        onSelected: (ShapeType type) {
          controller.setTool(PdfToolType.shape);
          controller.setShapeType(type);
        },
        child: Container(
          width: 36,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isShapeTool
                ? (isDark ? theme.colorScheme.primary.withOpacity(0.3) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isShapeTool
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconForShape(controller.currentShapeType),
                size: 16,
                color: isShapeTool
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: isShapeTool
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white38 : Colors.grey.shade500),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: ShapeType.rectangle,
            child: Row(
              children: [
                Icon(Icons.rectangle_outlined, size: 18),
                SizedBox(width: 8),
                Text('Rectangle'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ShapeType.circle,
            child: Row(
              children: [
                Icon(Icons.circle_outlined, size: 18),
                SizedBox(width: 8),
                Text('Circle / Oval'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ShapeType.line,
            child: Row(
              children: [
                Icon(Icons.horizontal_rule, size: 18),
                SizedBox(width: 8),
                Text('Line'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ShapeType.arrow,
            child: Row(
              children: [
                Icon(Icons.arrow_right_alt, size: 18),
                SizedBox(width: 8),
                Text('Arrow'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerPopup extends StatelessWidget {
  const _ColorPickerPopup({
    required this.currentColor,
    required this.palette,
    required this.onColorSelected,
  });

  final Color currentColor;
  final List<Color> palette;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<Color>(
      tooltip: 'Color Palette',
      offset: const Offset(0, 36),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      color: isDark ? const Color(0xFF222225) : Colors.white,
      onSelected: onColorSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<Color>(
          enabled: false,
          child: SizedBox(
            width: 160,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: palette.map((color) {
                final isSelected = currentColor == color;
                return InkWell(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade400,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ValuePickerPopup extends StatelessWidget {
  const _ValuePickerPopup({
    required this.label,
    required this.tooltip,
    required this.values,
    required this.currentValue,
    required this.onSelected,
  });

  final String label;
  final String tooltip;
  final List<double> values;
  final double currentValue;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<double>(
      tooltip: tooltip,
      offset: const Offset(0, 36),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      color: isDark ? const Color(0xFF222225) : Colors.white,
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      itemBuilder: (context) => values.map((val) {
        return PopupMenuItem<double>(
          value: val,
          height: 32,
          child: Text(
            '${val.round()} pt',
            style: TextStyle(
              fontSize: 12,
              fontWeight: val == currentValue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FontFamilyPickerPopup extends StatelessWidget {
  const _FontFamilyPickerPopup({
    required this.currentFontFamily,
    required this.onSelected,
  });

  final String currentFontFamily;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeOpt = PdfFontHelper.resolveOption(currentFontFamily);

    return PopupMenuButton<String>(
      tooltip: 'Font Family',
      offset: const Offset(0, 36),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      color: isDark ? const Color(0xFF222225) : Colors.white,
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Text(
              activeOpt.id,
              style: activeOpt.getTextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      itemBuilder: (context) => PdfFontHelper.options.map((opt) {
        final isSelected = opt.id == activeOpt.id;
        return PopupMenuItem<String>(
          value: opt.id,
          height: 34,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 14, color: Colors.blue)
              else
                const SizedBox(width: 14),
              const SizedBox(width: 6),
              Text(
                opt.displayName,
                style: opt.getTextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
