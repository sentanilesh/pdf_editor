import 'package:material_ui/material_ui.dart';
import '../models/tool_type.dart';

/// Result from [StampPickerDialog].
class StampPickerResult {
  const StampPickerResult({
    required this.stampType,
    this.customText,
    required this.color,
  });

  final StampType stampType;
  final String? customText;
  final Color color;
}

/// Dialog allowing user to select a pre-designed stamp or configure a custom one.
class StampPickerDialog extends StatefulWidget {
  const StampPickerDialog({
    super.key,
    required this.initialStampType,
    this.initialCustomText,
    required this.initialColor,
  });

  final StampType initialStampType;
  final String? initialCustomText;
  final Color initialColor;

  static Future<StampPickerResult?> show(
    BuildContext context, {
    StampType initialStampType = StampType.approved,
    String? initialCustomText,
    Color initialColor = const Color(0xFF2E7D32),
  }) {
    return showDialog<StampPickerResult>(
      context: context,
      builder: (_) => StampPickerDialog(
        initialStampType: initialStampType,
        initialCustomText: initialCustomText,
        initialColor: initialColor,
      ),
    );
  }

  @override
  State<StampPickerDialog> createState() => _StampPickerDialogState();
}

class _StampPickerDialogState extends State<StampPickerDialog> {
  late StampType _selectedType;
  late TextEditingController _customTextController;
  late Color _selectedColor;

  final Map<StampType, Color> _presetColors = {
    StampType.approved: const Color(0xFF2E7D32), // Green
    StampType.confidential: const Color(0xFFC62828), // Red
    StampType.draft: const Color(0xFFEF6C00), // Orange
    StampType.rejected: const Color(0xFFB71C1C), // Dark Red
    StampType.urgent: const Color(0xFFF57F17), // Yellow/Amber
    StampType.completed: const Color(0xFF1565C0), // Blue
    StampType.voidStamp: const Color(0xFF616161), // Grey
    StampType.custom: const Color(0xFF4527A0), // Deep Purple
  };

  final Map<StampType, IconData> _presetIcons = {
    StampType.approved: Icons.check_circle_outline_rounded,
    StampType.confidential: Icons.lock_outline_rounded,
    StampType.draft: Icons.edit_note_rounded,
    StampType.rejected: Icons.cancel_outlined,
    StampType.urgent: Icons.priority_high_rounded,
    StampType.completed: Icons.task_alt_rounded,
    StampType.voidStamp: Icons.block_flipped,
    StampType.custom: Icons.bookmark_border_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialStampType;
    _customTextController =
        TextEditingController(text: widget.initialCustomText ?? 'VERIFIED');
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final fieldBg = isDark ? const Color(0xFF252528) : const Color(0xFFF5F6F8);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
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
                          Icons.approval_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Select Stamp',
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

              // Grid of preset stamps
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StampType.values
                    .where((t) => t != StampType.custom)
                    .map((type) {
                  final isSelected = _selectedType == type;
                  final color = _presetColors[type] ?? Colors.blue;
                  final icon = _presetIcons[type] ?? Icons.label_outline;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.14) : fieldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : borderColor,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: isSelected ? color : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            type.label,
                            style: TextStyle(
                              color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 12),

              // Custom Stamp Toggle & Input
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedType = StampType.custom;
                    _selectedColor = _presetColors[StampType.custom]!;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Radio<StampType>(
                      value: StampType.custom,
                      groupValue: _selectedType,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                            _selectedColor = _presetColors[StampType.custom]!;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Custom Stamp Text',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              if (_selectedType == StampType.custom) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customTextController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.bookmark_outline_rounded, size: 18),
                    hintText: 'e.g. RECEIVED, PAID, REVIEWED',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Actions
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
                      Navigator.pop(
                        context,
                        StampPickerResult(
                          stampType: _selectedType,
                          customText: _selectedType == StampType.custom
                              ? _customTextController.text.trim().toUpperCase()
                              : null,
                          color: _selectedColor,
                        ),
                      );
                    },
                    child: const Text('Apply Stamp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
