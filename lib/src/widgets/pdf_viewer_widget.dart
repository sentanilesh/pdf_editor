import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_document_source.dart';
import 'pdf_password_dialog.dart';

/// Lightweight, read-only PDF viewer widget supporting continuous scrolling,
/// pinch-to-zoom, page navigation, and in-document search across all platforms.
class PdfViewerWidget extends StatefulWidget {
  const PdfViewerWidget({
    super.key,
    required this.source,
    this.initialPageNumber = 1,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.onPageChanged,
    this.passwordProvider,
  });

  final PdfDocumentSource source;
  final int initialPageNumber;
  final Color backgroundColor;
  final ValueChanged<int>? onPageChanged;
  final FutureOr<String?> Function()? passwordProvider;

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late final PdfViewerController _controller;
  late final PdfTextSearcher _searcher;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _isSearchOpen = false;
  bool _hasAttemptedPassword = false;
  final TextEditingController _searchField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPageNumber;
    _controller = PdfViewerController();
    _searcher = PdfTextSearcher(_controller);
  }

  @override
  void didUpdateWidget(covariant PdfViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _hasAttemptedPassword = false;
    }
  }

  @override
  void dispose() {
    _searcher.dispose();
    _searchField.dispose();
    super.dispose();
  }

  Future<String?> _resolvePassword() async {
    if (widget.passwordProvider != null) {
      return await widget.passwordProvider!();
    }
    if (!mounted) return null;
    final password = await PdfPasswordDialog.show(
      context,
      documentName: widget.source.name,
      isRetry: _hasAttemptedPassword,
    );
    _hasAttemptedPassword = true;
    return password;
  }

  Widget _buildViewer() {
    final params = PdfViewerParams(
      backgroundColor: widget.backgroundColor,
      matchTextColor: const Color(0x70FFEB3B),
      activeMatchTextColor: const Color(0xB0FF9800),
      pagePaintCallbacks: [
        _searcher.pageTextMatchPaintCallback,
      ],
      onDocumentChanged: (doc) {
        if (doc != null && mounted) {
          _hasAttemptedPassword = false;
          setState(() => _pageCount = doc.pages.length);
        }
      },
      onPageChanged: (pageNumber) {
        if (pageNumber != null && mounted) {
          setState(() => _currentPage = pageNumber);
          widget.onPageChanged?.call(pageNumber);
        }
      },
    );

    final src = widget.source;
    switch (src.type) {
      case PdfSourceType.bytes:
        return PdfViewer.data(
          src.bytes!,
          sourceName: src.name ?? 'document.pdf',
          controller: _controller,
          params: params,
          passwordProvider: _resolvePassword,
        );
      case PdfSourceType.file:
        return PdfViewer.file(
          src.file!.path,
          controller: _controller,
          params: params,
          passwordProvider: _resolvePassword,
        );
      case PdfSourceType.asset:
        return PdfViewer.asset(
          src.assetName!,
          controller: _controller,
          params: params,
          passwordProvider: _resolvePassword,
        );
      case PdfSourceType.network:
        return PdfViewer.uri(
          Uri.parse(src.url!),
          controller: _controller,
          params: params,
          passwordProvider: _resolvePassword,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Column(
        children: [
          // Navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () => _controller.goToPage(pageNumber: _currentPage - 1)
                      : null,
                ),
                Text(
                  '$_currentPage / $_pageCount',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _pageCount
                      ? () => _controller.goToPage(pageNumber: _currentPage + 1)
                      : null,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Zoom Out',
                  icon: const Icon(Icons.remove),
                  onPressed: () => _controller.zoomDown(),
                ),
                IconButton(
                  tooltip: 'Zoom In',
                  icon: const Icon(Icons.add),
                  onPressed: () => _controller.zoomUp(),
                ),
                IconButton(
                  tooltip: 'Search',
                  icon: Icon(
                    Icons.search,
                    color: _isSearchOpen ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearchOpen = !_isSearchOpen;
                      if (!_isSearchOpen) _searcher.resetTextSearch();
                    });
                  },
                ),
              ],
            ),
          ),

          // Search header if open
          if (_isSearchOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchField,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (q) {
                        if (q.trim().isEmpty) {
                          _searcher.resetTextSearch();
                        } else {
                          _searcher.startTextSearch(q.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () => _searcher.goToPrevMatch(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: () => _searcher.goToNextMatch(),
                  ),
                ],
              ),
            ),

          // PDF Viewport
          Expanded(child: _buildViewer()),
        ],
      ),
    );
  }
}
