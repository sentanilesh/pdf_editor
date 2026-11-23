import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' hide PdfAnnotation;
import '../controller/pdf_editor_controller.dart';

/// Sidebar displaying real rendered PDF page thumbnails with quick jump,
/// page rotation, and deletion controls.
class ThumbnailDrawer extends StatefulWidget {
  const ThumbnailDrawer({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final PdfEditorController controller;
  final VoidCallback onClose;

  @override
  State<ThumbnailDrawer> createState() => _ThumbnailDrawerState();
}

class _ThumbnailDrawerState extends State<ThumbnailDrawer> {
  // In-memory cache for thumbnail images
  final Map<int, ui.Image> _thumbnailCache = {};
  final Set<int> _renderingPages = {};

  PdfEditorController get controller => widget.controller;

  @override
  void dispose() {
    for (final img in _thumbnailCache.values) {
      img.dispose();
    }
    _thumbnailCache.clear();
    super.dispose();
  }

  Future<void> _renderThumbnail(int pageNum) async {
    if (_thumbnailCache.containsKey(pageNum) || _renderingPages.contains(pageNum)) {
      return;
    }

    final doc = controller.document;
    if (doc == null || pageNum < 1 || pageNum > doc.pages.length) return;

    _renderingPages.add(pageNum);
    try {
      final page = doc.pages[pageNum - 1];
      // Render at crisp thumbnail resolution (~160 x 220)
      const targetWidth = 160;
      final targetHeight = ((page.height / page.width) * targetWidth).round();

      final rendered = await page.renderForDisplay(
        width: targetWidth,
        height: targetHeight,
        fullWidth: targetWidth.toDouble(),
        fullHeight: targetHeight.toDouble(),
      );

      if (rendered != null && mounted) {
        setState(() {
          _thumbnailCache[pageNum] = rendered;
        });
      }
    } catch (_) {
      // Fallback silently if thumbnail render fails
    } finally {
      _renderingPages.remove(pageNum);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pageCount = controller.pageCount;
        final currentPage = controller.currentPage;

        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(
              right: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pages ($pageCount)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Page Thumbnails List
              Expanded(
                child: pageCount == 0
                    ? const Center(child: Text('No pages'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: pageCount,
                        itemBuilder: (context, index) {
                          final pageNum = index + 1;
                          final isCurrent = pageNum == currentPage;
                          final pageState = controller.getPageState(pageNum);

                          if (pageState?.isDeleted == true) {
                            return const SizedBox.shrink();
                          }

                          // Trigger rendering of thumbnail if not cached yet
                          if (!_thumbnailCache.containsKey(pageNum)) {
                            _renderThumbnail(pageNum);
                          }

                          final cachedImg = _thumbnailCache[pageNum];
                          final rotation = pageState?.rotation ?? 0;
                          final quarterTurns = (rotation ~/ 90) % 4;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                // Thumbnail Card
                                InkWell(
                                  onTap: () => controller.jumpToPage(pageNum),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrent
                                            ? theme.colorScheme.primary
                                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        width: isCurrent ? 2.5 : 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(isCurrent ? 0.15 : 0.05),
                                          blurRadius: isCurrent ? 6 : 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Real rendered PDF thumbnail
                                          if (cachedImg != null)
                                            RotatedBox(
                                              quarterTurns: quarterTurns,
                                              child: RawImage(
                                                image: cachedImg,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          else
                                            const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),

                                          // Page number badge
                                          Positioned(
                                            bottom: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isCurrent
                                                    ? theme.colorScheme.primary
                                                    : Colors.black.withOpacity(0.65),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$pageNum',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
