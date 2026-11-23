import 'package:flutter/material.dart';
import '../controller/pdf_editor_controller.dart';
import '../models/tool_type.dart';

/// Popover / dialog to pick colors, stroke thickness, and font sizes.
class ToolPropertiesBar extends StatelessWidget {
  const ToolPropertiesBar({
    super.key,
    required this.controller,
  });

  final PdfEditorController controller;

  static const List<Color> _palette = [
    Colors.black87,
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFF1E88E5), // Blue
    Color(0xFFFFB300), // Amber / Yellow
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tool = controller.activeTool;

        // Only show if the tool supports configurable properties
        final hasColor = tool == PdfToolType.draw ||
            tool == PdfToolType.highlighter ||
            tool == PdfToolType.shape ||
            tool == PdfToolType.text ||
            tool == PdfToolType.stamp;

        final hasStroke = tool == PdfToolType.draw ||
            tool == PdfToolType.shape ||
            tool == PdfToolType.highlighter;

        final hasFontSize = tool == PdfToolType.text;
        final hasShapePicker = tool == PdfToolType.shape;

        if (!hasColor && !hasStroke && !hasFontSize && !hasShapePicker) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Color Palette
                if (hasColor) ...[
                  ..._palette.map((color) {
                    final isSelected = controller.currentColor == color;
                    return InkWell(
                      onTap: () => controller.setColor(color),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.white,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  Container(height: 20, width: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 16),
                ],

                // Stroke Width
                if (hasStroke) ...[
                  const Text('Stroke: ', style: TextStyle(fontSize: 12)),
                  SizedBox(
                    width: 110,
                    child: Slider(
                      value: controller.currentStrokeWidth,
                      min: 1.0,
                      max: 12.0,
                      divisions: 11,
                      label: '${controller.currentStrokeWidth.round()} pt',
                      onChanged: (val) => controller.setStrokeWidth(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Font Size
                if (hasFontSize) ...[
                  const Text('Size: ', style: TextStyle(fontSize: 12)),
                  SizedBox(
                    width: 110,
                    child: Slider(
                      value: controller.currentFontSize,
                      min: 10.0,
                      max: 36.0,
                      divisions: 13,
                      label: '${controller.currentFontSize.round()} pt',
                      onChanged: (val) => controller.setFontSize(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Shape Type Dropdown
                if (hasShapePicker) ...[
                  const Text('Shape: ', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  DropdownButton<ShapeType>(
                    value: controller.currentShapeType,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: ShapeType.rectangle,
                        child: Text('Rectangle'),
                      ),
                      DropdownMenuItem(
                        value: ShapeType.circle,
                        child: Text('Circle / Oval'),
                      ),
                      DropdownMenuItem(
                        value: ShapeType.line,
                        child: Text('Line'),
                      ),
                      DropdownMenuItem(
                        value: ShapeType.arrow,
                        child: Text('Arrow'),
                      ),
                    ],
                    onChanged: (type) {
                      if (type != null) controller.setShapeType(type);
                    },
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
