import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font option definition for PDF text annotations.
class PdfFontOption {
  const PdfFontOption({
    required this.id,
    required this.displayName,
    required this.primaryFamily,
    required this.fallbacks,
    required this.builder,
  });

  /// Unique identifier / family key (e.g. 'Roboto', 'Merriweather', 'Fira Code', 'Caveat', 'Pacifico').
  final String id;

  /// User-friendly label displayed in dropdowns.
  final String displayName;

  /// Primary font family name.
  final String primaryFamily;

  /// Multi-platform fallback fonts.
  final List<String> fallbacks;

  /// Builder that produces a loaded [TextStyle] using google_fonts with fallbacks.
  final TextStyle Function({
    double? fontSize,
    Color? color,
    FontWeight fontWeight,
    FontStyle fontStyle,
  }) builder;

  /// Constructs a resolved [TextStyle] for this font option.
  TextStyle getTextStyle({
    double? fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return builder(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }
}

/// Helper utility for managing, resolving, and styling fonts across all platforms.
class PdfFontHelper {
  /// The standard font choices available for text annotations.
  static final List<PdfFontOption> options = [
    PdfFontOption(
      id: 'Roboto',
      displayName: 'Sans-Serif (Roboto)',
      primaryFamily: 'Roboto',
      fallbacks: const ['Arial', 'Segoe UI', 'Helvetica Neue', 'sans-serif'],
      builder: ({fontSize, color, fontWeight = FontWeight.normal, fontStyle = FontStyle.normal}) {
        return GoogleFonts.roboto(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textStyle: const TextStyle(fontFamilyFallback: ['Arial', 'Segoe UI', 'sans-serif']),
        );
      },
    ),
    PdfFontOption(
      id: 'Merriweather',
      displayName: 'Serif (Merriweather)',
      primaryFamily: 'Merriweather',
      fallbacks: const ['Georgia', 'Times New Roman', 'Times', 'serif'],
      builder: ({fontSize, color, fontWeight = FontWeight.normal, fontStyle = FontStyle.normal}) {
        return GoogleFonts.merriweather(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textStyle: const TextStyle(fontFamilyFallback: ['Georgia', 'Times New Roman', 'serif']),
        );
      },
    ),
    PdfFontOption(
      id: 'Fira Code',
      displayName: 'Monospace (Fira Code)',
      primaryFamily: 'Fira Code',
      fallbacks: const ['Consolas', 'Courier New', 'Menlo', 'monospace'],
      builder: ({fontSize, color, fontWeight = FontWeight.normal, fontStyle = FontStyle.normal}) {
        return GoogleFonts.firaCode(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textStyle: const TextStyle(fontFamilyFallback: ['Consolas', 'Courier New', 'monospace']),
        );
      },
    ),
    PdfFontOption(
      id: 'Caveat',
      displayName: 'Handwriting (Caveat)',
      primaryFamily: 'Caveat',
      fallbacks: const ['Comic Sans MS', 'Chalkboard', 'Apple Chancery', 'cursive'],
      builder: ({fontSize, color, fontWeight = FontWeight.normal, fontStyle = FontStyle.normal}) {
        return GoogleFonts.caveat(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textStyle: const TextStyle(fontFamilyFallback: ['Comic Sans MS', 'Chalkboard', 'cursive']),
        );
      },
    ),
    PdfFontOption(
      id: 'Pacifico',
      displayName: 'Cursive / Script (Pacifico)',
      primaryFamily: 'Pacifico',
      fallbacks: const ['Brush Script MT', 'Lucida Handwriting', 'cursive'],
      builder: ({fontSize, color, fontWeight = FontWeight.normal, fontStyle = FontStyle.normal}) {
        return GoogleFonts.pacifico(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textStyle: const TextStyle(fontFamilyFallback: ['Brush Script MT', 'cursive']),
        );
      },
    ),
    PdfFontOption(
      id: 'Oswald',
      displayName: 'Headline (Oswald)',
      primaryFamily: 'Oswald',
      fallbacks: const ['Impact', 'Arial Black', 'sans-serif'],
      builder: ({fontSize, color, fontWeight = FontWeight.normal, fontStyle = FontStyle.normal}) {
        return GoogleFonts.oswald(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          textStyle: const TextStyle(fontFamilyFallback: ['Impact', 'Arial Black', 'sans-serif']),
        );
      },
    ),
  ];

  /// Resolves any font key or legacy string (e.g. 'sans-serif', 'serif', 'monospace', 'cursive')
  /// to one of the concrete [PdfFontOption]s.
  static PdfFontOption resolveOption(String? fontIdOrFamily) {
    if (fontIdOrFamily == null || fontIdOrFamily.isEmpty) {
      return options[0];
    }
    final key = fontIdOrFamily.toLowerCase();
    if (key.contains('merriweather') || (key.contains('serif') && !key.contains('sans')) || key.contains('georgia') || key.contains('times')) {
      return options[1];
    } else if (key.contains('fira') || key.contains('mono') || key.contains('code') || key.contains('courier') || key.contains('consolas')) {
      return options[2];
    } else if (key.contains('pacifico') || key.contains('brush')) {
      return options[4];
    } else if (key.contains('oswald') || key.contains('impact') || key.contains('headline')) {
      return options[5];
    } else if (key.contains('caveat') || key.contains('cur') || key.contains('hand') || key.contains('script') || key.contains('comic')) {
      return options[3];
    } else {
      return options[0];
    }
  }

  /// Resolves a full [TextStyle] ensuring GoogleFonts font loading and multi-platform fallbacks.
  static TextStyle resolveTextStyle({
    required String? fontFamily,
    double fontSize = 14.0,
    Color color = Colors.black87,
    bool isBold = false,
    bool isItalic = false,
    double opacity = 1.0,
  }) {
    final opt = resolveOption(fontFamily);
    final effectiveColor = color.withOpacity(opacity.clamp(0.0, 1.0));
    final effectiveWeight = isBold ? FontWeight.bold : FontWeight.normal;
    final effectiveStyle = isItalic ? FontStyle.italic : FontStyle.normal;

    return opt.builder(
      fontSize: fontSize,
      color: effectiveColor,
      fontWeight: effectiveWeight,
      fontStyle: effectiveStyle,
    );
  }
}
