import 'package:material_ui/material_ui.dart';

/// Output from [SignatureDialog].
class SignatureResult {
  const SignatureResult({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;
}

/// Dedicated dialog with a smooth signature pad canvas.
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({
    super.key,
    this.defaultColor = Colors.black,
    this.defaultStrokeWidth = 2.5,
  });

  final Color defaultColor;
  final double defaultStrokeWidth;

  static Future<SignatureResult?> show(
    BuildContext context, {
    Color defaultColor = Colors.black,
    double defaultStrokeWidth = 2.5,
  }) {
    return showDialog<SignatureResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SignatureDialog(
        defaultColor: defaultColor,
        defaultStrokeWidth: defaultStrokeWidth,
      ),
    );
  }

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  late Color _selectedColor;
  late double _selectedStrokeWidth;

  final List<Color> _colorOptions = const [
    Colors.black87,
    Color(0xFF002244), // Midnight Blue / Ink Blue
    Color(0xFF8B0000), // Dark Red
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.defaultColor;
    _selectedStrokeWidth = widget.defaultStrokeWidth;
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                          Icons.draw_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Draw Signature',
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
              const SizedBox(height: 12),

              // Drawing pad canvas
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Guideline signature line
                      Positioned(
                        bottom: 40,
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 24,
                        child: Text(
                          'Sign above the line',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      // Gesture listener for drawing
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          setState(() {
                            _currentStroke = [details.localPosition];
                            _strokes.add(_currentStroke!);
                          });
                        },
                        onPanUpdate: (details) {
                          final pt = details.localPosition;
                          if (_currentStroke != null) {
                            if (_currentStroke!.isEmpty ||
                                (pt - _currentStroke!.last).distanceSquared >= 1.0) {
                              setState(() {
                                _currentStroke!.add(pt);
                              });
                            }
                          }
                        },
                        onPanEnd: (_) {
                          _currentStroke = null;
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _SignaturePadPainter(
                              strokes: _strokes,
                              color: _selectedColor,
                              strokeWidth: _selectedStrokeWidth,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Controls: Ink Color & Clear
              Row(
                children: [
                  Text(
                    'Ink Color:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._colorOptions.map((c) {
                    final isSelected = _selectedColor == c;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = c),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
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
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: _strokes.isEmpty ? null : _clear,
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Buttons
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
                    onPressed: _strokes.isEmpty
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              SignatureResult(
                                strokes: _strokes,
                                color: _selectedColor,
                                strokeWidth: _selectedStrokeWidth,
                              ),
                            );
                          },
                    child: const Text('Apply Signature', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

class _SignaturePadPainter extends CustomPainter {
  const _SignaturePadPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}
