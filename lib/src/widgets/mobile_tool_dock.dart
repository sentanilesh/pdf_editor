import 'package:flutter/material.dart';
import '../controller/pdf_editor_controller.dart';
import '../models/shape_annotation.dart';
import '../models/signature_annotation.dart';
import '../models/text_annotation.dart';
import '../models/tool_type.dart';
import '../rendering/font_helper.dart';

/// Touch-friendly, thumb-accessible mobile tool dock and contextual properties bar.
/// Optimized specifically for smartphone and compact tablet screens.
class MobileToolDock extends StatelessWidget {
  const MobileToolDock({
    super.key,
    required this.controller,
  });

  final PdfEditorController controller;

  static const List<Color> _palette = [
    Colors.black87,
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFFB300), // Amber
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Colors.grey,
  ];

  static const List<double> _strokePresets = [1.0, 2.0, 3.0, 5.0, 8.0, 12.0];
  static const List<double> _fontPresets = [10.0, 12.0, 14.0, 16.0, 20.0, 24.0, 32.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tool = controller.activeTool;
        final selected = controller.selectedAnnotation;
        final isTextSelected = selected is TextAnnotation;
        final isSigSelected = selected is SignatureAnnotation;
        final isShapeSelected = selected is ShapeAnnotation;

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
            isSigSelected ||
            isShapeSelected;

        final hasFont = tool == PdfToolType.text || isTextSelected;
        final hasShapeMenu = tool == PdfToolType.shape;
        final hasProperties = hasColor || hasStroke || hasFont || hasShapeMenu;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Contextual Properties Bar (Color swatches, stroke, font)
            if (hasProperties)
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252528) : const Color(0xFFF8F9FA),
                  border: Border(
                    top: BorderSide(color: borderColor, width: 0.8),
                    bottom: BorderSide(color: borderColor, width: 0.8),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Color Swatches
                      if (hasColor) ...[
                        Row(
                          children: _palette.map((color) {
                            final isSelected = controller.currentColor.value == color.value;
                            return GestureDetector(
                              onTap: () => controller.setColor(color),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.35),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 13,
                                        color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 1,
                          height: 20,
                          color: borderColor,
                        ),
                      ],

                      // Stroke Width Selector
                      if (hasStroke) ...[
                        PopupMenuButton<double>(
                          tooltip: 'Stroke Thickness',
                          offset: const Offset(0, -180),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: borderColor),
                          ),
                          color: isDark ? const Color(0xFF222225) : Colors.white,
                          onSelected: (v) => controller.setStrokeWidth(v),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${controller.currentStrokeWidth.round()} pt',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 14),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => _strokePresets.map((val) {
                            return PopupMenuItem<double>(
                              value: val,
                              height: 32,
                              child: Text(
                                '${val.round()} pt',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: val == controller.currentStrokeWidth ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Shapes Picker Pill
                      if (hasShapeMenu) ...[
                        PopupMenuButton<ShapeType>(
                          tooltip: 'Shape',
                          offset: const Offset(0, -160),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: borderColor),
                          ),
                          color: isDark ? const Color(0xFF222225) : Colors.white,
                          onSelected: (shape) => controller.setShapeType(shape),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(_getShapeIcon(controller.currentShapeType), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _getShapeName(controller.currentShapeType),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 14),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: ShapeType.rectangle,
                              child: Row(
                                children: [
                                  Icon(Icons.rectangle_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Rectangle', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: ShapeType.circle,
                              child: Row(
                                children: [
                                  Icon(Icons.circle_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Circle', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: ShapeType.line,
                              child: Row(
                                children: [
                                  Icon(Icons.horizontal_rule, size: 16),
                                  SizedBox(width: 8),
                                  Text('Line', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: ShapeType.arrow,
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_right_alt, size: 16),
                                  SizedBox(width: 8),
                                  Text('Arrow', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Font Family & Size Pills
                      if (hasFont) ...[
                        // Font Family
                        PopupMenuButton<String>(
                          tooltip: 'Font Family',
                          offset: const Offset(0, -220),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: borderColor),
                          ),
                          color: isDark ? const Color(0xFF222225) : Colors.white,
                          onSelected: (family) => controller.setFontFamily(family),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  PdfFontHelper.resolveOption(isTextSelected ? selected.fontFamily : controller.currentFontFamily).id,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 14),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => PdfFontHelper.options.map((opt) {
                            return PopupMenuItem<String>(
                              value: opt.id,
                              height: 32,
                              child: Text(opt.displayName, style: opt.getTextStyle(fontSize: 12)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 6),

                        // Font Size
                        PopupMenuButton<double>(
                          tooltip: 'Font Size',
                          offset: const Offset(0, -200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: borderColor),
                          ),
                          color: isDark ? const Color(0xFF222225) : Colors.white,
                          onSelected: (size) => controller.setFontSize(size),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${(isTextSelected ? selected.fontSize : controller.currentFontSize).round()} pt',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 14),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => _fontPresets.map((val) {
                            return PopupMenuItem<double>(
                              value: val,
                              height: 32,
                              child: Text('${val.round()} pt', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 2. Primary Mobile Tool Dock
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1F) : Colors.white,
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MobileDockItem(
                      icon: Icons.pan_tool_outlined,
                      label: 'View',
                      isActive: tool == PdfToolType.view,
                      onTap: () => controller.setTool(PdfToolType.view),
                    ),
                    _MobileDockItem(
                      icon: Icons.near_me_outlined,
                      label: 'Select',
                      isActive: tool == PdfToolType.select,
                      onTap: () => controller.setTool(PdfToolType.select),
                    ),
                    _MobileDockItem(
                      icon: Icons.edit_outlined,
                      label: 'Pen',
                      isActive: tool == PdfToolType.draw,
                      onTap: () => controller.setTool(PdfToolType.draw),
                    ),
                    _MobileDockItem(
                      icon: Icons.highlight_outlined,
                      label: 'Highlight',
                      isActive: tool == PdfToolType.highlighter,
                      onTap: () => controller.setTool(PdfToolType.highlighter),
                    ),
                    _MobileDockItem(
                      icon: Icons.title,
                      label: 'Text',
                      isActive: tool == PdfToolType.text,
                      onTap: () => controller.setTool(PdfToolType.text),
                    ),
                    _MobileDockItem(
                      icon: Icons.category_outlined,
                      label: 'Shape',
                      isActive: tool == PdfToolType.shape,
                      onTap: () => controller.setTool(PdfToolType.shape),
                    ),
                    _MobileDockItem(
                      icon: Icons.draw_outlined,
                      label: 'Signature',
                      isActive: tool == PdfToolType.signature,
                      onTap: () => controller.setTool(PdfToolType.signature),
                    ),
                    _MobileDockItem(
                      icon: Icons.auto_fix_normal_outlined,
                      label: 'Eraser',
                      isActive: tool == PdfToolType.eraser,
                      onTap: () => controller.setTool(PdfToolType.eraser),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getShapeIcon(ShapeType type) {
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

  String _getShapeName(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return 'Rect';
      case ShapeType.circle:
        return 'Circle';
      case ShapeType.line:
        return 'Line';
      case ShapeType.arrow:
        return 'Arrow';
    }
  }
}

class _MobileDockItem extends StatelessWidget {
  const _MobileDockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
