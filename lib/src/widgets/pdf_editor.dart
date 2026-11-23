import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../controller/pdf_editor_controller.dart';
import '../models/pdf_document_source.dart';
import '../models/tool_type.dart';
import 'annotation_canvas.dart';
import 'color_stroke_picker.dart';
import 'editor_toolbar.dart';
import 'mobile_tool_dock.dart';
import 'pdf_form_fields_overlay.dart';
import 'pdf_password_dialog.dart';
import 'search_overlay.dart';
import 'thumbnail_drawer.dart';

/// Complete, out-of-the-box PDF Editor widget with viewing, full annotation suite,
/// page navigation, thumbnails drawer, search, history, and PDF export.
class PdfEditor extends StatefulWidget {
  const PdfEditor({
    super.key,
    required this.source,
    this.controller,
    this.onSave,
    this.onPrint,
    this.showToolbar = true,
    this.showPropertiesBar = false,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.passwordProvider,
    this.preserveFormFields = true,
    this.flattenFormFields = false,
    this.removeFormFields = false,
  });

  /// The PDF document source (bytes, file, asset, or network url).
  final PdfDocumentSource source;

  /// Optional external controller. If null, an internal one is created and managed.
  final PdfEditorController? controller;

  /// Callback when user triggers Save / Export. Provides exported PDF bytes.
  final void Function(Uint8List exportedBytes)? onSave;

  /// Callback when user triggers Print. If null, standard system print is invoked.
  final VoidCallback? onPrint;

  /// Whether to display the top editor toolbar.
  final bool showToolbar;

  /// Whether to display the secondary color / stroke / font properties bar.
  final bool showPropertiesBar;

  /// Background color surrounding the PDF page canvas.
  final Color backgroundColor;

  /// Optional custom password provider callback for encrypted PDFs.
  /// If null, a built-in interactive dialog ([PdfPasswordDialog]) is automatically
  /// displayed when a password-protected PDF is encountered.
  final FutureOr<String?> Function()? passwordProvider;

  /// Whether to preserve interactive form fields when saving/exporting (default: true).
  final bool preserveFormFields;

  /// Whether to flatten form fields into static visuals when saving/exporting (default: false).
  final bool flattenFormFields;

  /// Whether to completely remove all form elements when saving/exporting (default: false).
  final bool removeFormFields;

  @override
  State<PdfEditor> createState() => _PdfEditorState();
}

class _PdfEditorState extends State<PdfEditor> {
  late PdfEditorController _controller;
  bool _isInternalController = false;
  bool _hasAttemptedPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = PdfEditorController(initialSource: widget.source);
      _isInternalController = true;
    }

    if (_controller.source == null) {
      _controller.loadSource(widget.source);
    }
  }

  @override
  void didUpdateWidget(covariant PdfEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _hasAttemptedPassword = false;
      _controller.loadSource(widget.source);
    }
  }

  Future<String?> _resolvePassword() async {
    if (widget.passwordProvider != null) {
      final res = await widget.passwordProvider!();
      if (res != null) {
        _controller.setDocumentPassword(res);
      }
      return res;
    }

    if (!mounted) return null;
    final password = await PdfPasswordDialog.show(
      context,
      documentName: widget.source.name,
      isRetry: _hasAttemptedPassword,
    );
    _hasAttemptedPassword = true;
    if (password != null) {
      _controller.setDocumentPassword(password);
    }
    return password;
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    try {
      final bytes = await _controller.exportPdf(
        preserveFormFields: widget.preserveFormFields,
        flattenFormFields: widget.flattenFormFields,
        removeFormFields: widget.removeFormFields,
      );
      if (widget.onSave != null) {
        widget.onSave!(bytes);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF exported successfully (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handlePrint() async {
    if (widget.onPrint != null) {
      widget.onPrint!();
    } else {
      await _controller.printPdf();
    }
  }

  Widget _buildPdfrxViewer(PdfEditorController ctrl) {
    final src = widget.source;
    final isViewMode = ctrl.activeTool == PdfToolType.view;

    final params = PdfViewerParams(
      backgroundColor: widget.backgroundColor,
      panEnabled: isViewMode,
      scaleEnabled: isViewMode,
      matchTextColor: const Color(0x70FFEB3B),
      activeMatchTextColor: const Color(0xB0FF9800),
      onKey: (params, key, isRealKeyPress) {
        // Prevent viewer from consuming keys (especially space, arrows, home/end)
        // when user is typing inside any text field or editable input
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (primaryFocus != null && primaryFocus.context != null) {
          final isEditable = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
          if (isEditable) {
            return false;
          }
        }
        if (key == LogicalKeyboardKey.space) {
          return false;
        }
        return null;
      },
      pagePaintCallbacks: [
        ctrl.textSearcher.pageTextMatchPaintCallback,
      ],
      onDocumentChanged: (document) {
        if (document != null) {
          _hasAttemptedPassword = false;
          ctrl.onDocumentLoaded(document);
        }
      },
      onPageChanged: (pageNumber) {
        if (pageNumber != null) {
          ctrl.onPageChanged(pageNumber);
        }
      },
      errorBannerBuilder: (context, error, stackTrace, documentRef) {
        return SizedBox();
      },
      pageOverlaysBuilder: (context, pageRect, page) {
        return [
          Positioned.fill(
            child: AnnotationCanvas(
              controller: ctrl,
              page: page,
              pageSize: pageRect.size,
            ),
          ),
          Positioned.fill(
            child: PdfFormFieldsOverlay(
              controller: ctrl,
              pageNumber: page.pageNumber,
              pageSize: pageRect.size,
              page: page,
            ),
          ),
        ];
      },
    );

    switch (src.type) {
      case PdfSourceType.bytes:
        return PdfViewer.data(
          src.bytes!,
          sourceName: src.name ?? 'document.pdf',
          controller: ctrl.pdfrxController,
          params: params,
          passwordProvider: _resolvePassword,
        );

      case PdfSourceType.file:
        return PdfViewer.file(
          src.file!.path,
          controller: ctrl.pdfrxController,
          params: params,
          passwordProvider: _resolvePassword,
        );

      case PdfSourceType.asset:
        return PdfViewer.asset(
          src.assetName!,
          controller: ctrl.pdfrxController,
          params: params,
          passwordProvider: _resolvePassword,
        );

      case PdfSourceType.network:
        return PdfViewer.uri(
          Uri.parse(src.url!),
          controller: ctrl.pdfrxController,
          params: params,
          passwordProvider: _resolvePassword,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: widget.backgroundColor,
          body: Column(
            children: [
              // Main Toolbar (Top bar)
              if (widget.showToolbar)
                EditorToolbar(
                  controller: _controller,
                  onSave: _handleSave,
                  onPrint: _handlePrint,
                  isMobile: isMobile,
                ),

              // Desktop secondary properties bar (if enabled)
              if (!isMobile && widget.showPropertiesBar)
                ToolPropertiesBar(controller: _controller),

              // Viewer + Overlays (Search, Thumbnails)
              Expanded(
                child: Stack(
                  children: [
                    // Main Viewer & Annotation Canvas
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: _buildPdfrxViewer(_controller),
                      ),
                    ),

                    // Floating Quick Controls on Mobile Canvas (Zoom & Undo/Redo)
                    if (isMobile) ...[
                      // Floating Undo / Redo controls on bottom-left
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Material(
                          color: Colors.transparent,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252528) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.undo, size: 18),
                                  tooltip: 'Undo',
                                  visualDensity: VisualDensity.compact,
                                  color: _controller.canUndo
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? Colors.white30 : Colors.grey.shade400),
                                  onPressed: _controller.canUndo ? () => _controller.undo() : null,
                                ),
                                Container(
                                  height: 16,
                                  width: 1,
                                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.redo, size: 18),
                                  tooltip: 'Redo',
                                  visualDensity: VisualDensity.compact,
                                  color: _controller.canRedo
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? Colors.white30 : Colors.grey.shade400),
                                  onPressed: _controller.canRedo ? () => _controller.redo() : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Floating Zoom controls on bottom-right
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Material(
                          color: Colors.transparent,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252528) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  tooltip: 'Zoom Out',
                                  visualDensity: VisualDensity.compact,
                                  color: isDark ? Colors.white : Colors.black87,
                                  onPressed: () => _controller.zoomOut(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.fit_screen_outlined, size: 18),
                                  tooltip: 'Fit to Page',
                                  visualDensity: VisualDensity.compact,
                                  color: isDark ? Colors.white : Colors.black87,
                                  onPressed: () => _controller.resetZoom(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  tooltip: 'Zoom In',
                                  visualDensity: VisualDensity.compact,
                                  color: isDark ? Colors.white : Colors.black87,
                                  onPressed: () => _controller.zoomIn(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Scrim backdrop when drawer is open on mobile
                    if (_controller.isThumbnailDrawerOpen && isMobile)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _controller.toggleThumbnailDrawer(),
                          child: Container(color: Colors.black45),
                        ),
                      ),

                    // Page Thumbnails Drawer
                    if (_controller.isThumbnailDrawerOpen)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: ThumbnailDrawer(
                          controller: _controller,
                          onClose: () => _controller.toggleThumbnailDrawer(),
                        ),
                      ),

                    // In-document Text Search Bar
                    if (_controller.isSearchVisible)
                      Positioned(
                        top: isMobile ? 8 : 12,
                        left: isMobile ? 12 : null,
                        right: isMobile ? 12 : 20,
                        child: SearchOverlay(
                          controller: _controller,
                          onClose: () => _controller.toggleSearch(),
                        ),
                      ),
                  ],
                ),
              ),

              // Mobile Tool Dock + Contextual Properties (on mobile screens)
              if (isMobile && widget.showToolbar)
                MobileToolDock(controller: _controller),
            ],
          ),
        );
      },
    );
  }
}
