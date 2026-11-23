import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/pdf_editor_controller.dart';

/// Floating in-document text search bar overlay.
class SearchOverlay extends StatefulWidget {
  const SearchOverlay({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final PdfEditorController controller;
  final VoidCallback onClose;

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  PdfEditorController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() {
      if (mounted) setState(() {});
    });

    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _goToPrev();
          } else {
            _onEnterPressed();
          }
          // Prevent Flutter's default EditableText unfocus behavior!
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      controller.textSearcher.resetTextSearch();
      return;
    }

    // Responsive debounce for smooth continuous typing
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted && trimmed.isNotEmpty) {
        controller.textSearcher.startTextSearch(
          trimmed,
          searchImmediately: true,
          caseInsensitive: true,
        );
      }
    });
  }

  void _onEnterPressed() {
    _debounceTimer?.cancel();
    final trimmed = _queryController.text.trim();
    if (trimmed.isEmpty) return;

    final searcher = controller.textSearcher;
    final isSamePattern = searcher.pattern == trimmed;

    if (!isSamePattern || searcher.matches.isEmpty) {
      searcher.startTextSearch(
        trimmed,
        searchImmediately: true,
        caseInsensitive: true,
      );
    } else {
      _goToNext();
    }
    _ensureFocus();
  }

  void _ensureFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _clearQuery() {
    _queryController.clear();
    controller.textSearcher.resetTextSearch();
    _ensureFocus();
  }

  void _goToNext() {
    final searcher = controller.textSearcher;
    if (searcher.matches.isEmpty) return;
    final curr = searcher.currentIndex;
    final next = (curr == null || curr >= searcher.matches.length - 1) ? 0 : curr + 1;
    searcher.goToMatchOfIndex(next);
    controller.pdfrxController.invalidate();
    _ensureFocus();
  }

  void _goToPrev() {
    final searcher = controller.textSearcher;
    if (searcher.matches.isEmpty) return;
    final curr = searcher.currentIndex;
    final prev = (curr == null || curr <= 0) ? searcher.matches.length - 1 : curr - 1;
    searcher.goToMatchOfIndex(prev);
    controller.pdfrxController.invalidate();
    _ensureFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searcher = controller.textSearcher;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return ListenableBuilder(
      listenable: searcher,
      builder: (context, _) {
        final matches = searcher.matches;
        final currentIdx = searcher.currentIndex;
        final matchCount = matches.length;
        final isSearching = searcher.isSearching;
        final queryText = _queryController.text.trim();

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        String matchText = '';
        if (queryText.isNotEmpty) {
          if (isSearching && matchCount == 0) {
            matchText = 'Searching...';
          } else if (matchCount == 0) {
            matchText = '0 matches';
          } else {
            matchText = '${(currentIdx ?? 0) + 1} of $matchCount';
          }
        }

        return Material(
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF222225) : Colors.white,
          child: Container(
            height: 38,
            width: isMobile ? null : 340,
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.none,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search in document...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _onEnterPressed(),
                  ),
                ),

                // Clear button
                if (queryText.isNotEmpty)
                  InkWell(
                    onTap: _clearQuery,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        Icons.cancel,
                        size: 15,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                    ),
                  ),

                // Match status pill
                if (matchText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: matchCount > 0
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : (isSearching
                              ? Colors.grey.withOpacity(0.15)
                              : Colors.red.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSearching) ...[
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          matchText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: matchCount > 0
                                ? theme.colorScheme.primary
                                : (isSearching ? Colors.grey : Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Previous match button
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                  tooltip: 'Previous match (Shift+Enter)',
                  visualDensity: VisualDensity.compact,
                  splashRadius: 14,
                  onPressed: matchCount > 0 ? _goToPrev : null,
                ),

                // Next match button
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  tooltip: 'Next match (Enter)',
                  visualDensity: VisualDensity.compact,
                  splashRadius: 14,
                  onPressed: matchCount > 0 ? _goToNext : null,
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'Close (Esc)',
                  visualDensity: VisualDensity.compact,
                  splashRadius: 14,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
