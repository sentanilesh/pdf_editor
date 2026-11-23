import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_editor/pdf_editor.dart';

void main() {
  runApp(const PdfEditorDemoApp());
}

class PdfEditorDemoApp extends StatefulWidget {
  const PdfEditorDemoApp({super.key});

  @override
  State<PdfEditorDemoApp> createState() => _PdfEditorDemoAppState();
}

class _PdfEditorDemoAppState extends State<PdfEditorDemoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter PDF Editor & Viewer',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
      ),
      home: DemoHomeScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  late PdfEditorController _controller;
  PdfDocumentSource? _currentSource;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = PdfEditorController();
    _controller.onFormSubmitCallback = (isValid, msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isValid ? Colors.green.shade700 : Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };
    _loadSampleDocument();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSampleDocument() async {
    setState(() => _isLoading = true);
    final bytes = await PdfGeneratorHelper.generateSampleDocument();
    final source = PdfDocumentSource.bytes(
      bytes,
      name: 'Non_Disclosure_Agreement.pdf',
    );
    setState(() {
      _currentSource = source;
      _isLoading = false;
    });
    _controller.loadSource(source);
  }

  Future<void> _loadSampleFormDocument() async {
    setState(() => _isLoading = true);
    final bytes = await PdfGeneratorHelper.generateSampleFormDocument();
    final source = PdfDocumentSource.bytes(
      bytes,
      name: 'Interactive_Employee_Form.pdf',
    );
    setState(() {
      _currentSource = source;
      _isLoading = false;
    });
    _controller.loadSource(source);
  }

  Future<void> _loadFormNotWorkingPdf() async {
    setState(() => _isLoading = true);
    final data = await rootBundle.load('assets/form_not_working.pdf');
    final bytes = data.buffer.asUint8List();
    final source = PdfDocumentSource.bytes(
      bytes,
      name: 'form_not_working.pdf',
    );
    setState(() {
      _currentSource = source;
      _isLoading = false;
    });
    _controller.loadSource(source);
  }

  Future<void> _pickLocalPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      PdfDocumentSource newSource;

      if (kIsWeb || file.bytes != null) {
        newSource = PdfDocumentSource.bytes(
          file.bytes!,
          name: file.name,
        );
      } else if (file.path != null) {
        newSource = PdfDocumentSource.file(
          File(file.path!),
          name: file.name,
        );
      } else {
        return;
      }

      setState(() {
        _currentSource = newSource;
      });
      _controller.loadSource(newSource);
    }
  }

  void _showAnnotationsJsonDialog() {
    final jsonStr = _controller.exportAnnotationsJson();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.code_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Exported Annotations (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252528) : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonStr,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onExportPdf(Uint8List exportedBytes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('PDF Exported Successfully', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252528) : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSource?.name ?? 'document.pdf',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${(exportedBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All vector drawings, text annotations, stamps, signatures, and redactions are permanently flattened.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 750;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'PDF Editor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (screenWidth >= 900 && _currentSource?.name != null) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _currentSource?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Load Sample PDF
          Tooltip(
            message: 'Load Sample Document',
            child: isMobile
                ? IconButton(
                    icon: const Icon(Icons.description_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: _loadSampleDocument,
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Sample', style: TextStyle(fontSize: 12)),
                    onPressed: _loadSampleDocument,
                  ),
          ),

          // Load Fillable Form PDF
          Tooltip(
            message: 'Load Interactive Form Document',
            child: isMobile
                ? IconButton(
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: _loadSampleFormDocument,
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.assignment_outlined, size: 16),
                    label: const Text('Form', style: TextStyle(fontSize: 12)),
                    onPressed: _loadSampleFormDocument,
                  ),
          ),

          // Load form_not_working.pdf (Form & Validation Test)
          Tooltip(
            message: 'Load Form & Validation PDF',
            child: isMobile
                ? IconButton(
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: _loadFormNotWorkingPdf,
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: const Text('Val Form', style: TextStyle(fontSize: 12)),
                    onPressed: _loadFormNotWorkingPdf,
                  ),
          ),

          // Validate & Submit Form button when form fields are loaded
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (!_controller.hasFormFields) return const SizedBox.shrink();
              return Tooltip(
                message: 'Validate Form Fields',
                child: isMobile
                    ? IconButton(
                        icon: const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF1E88E5)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _controller.handleButtonAction('submit'),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF1E88E5),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 16),
                        label: const Text('Validate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _controller.handleButtonAction('submit'),
                      ),
              );
            },
          ),

          // Open Local File
          Tooltip(
            message: 'Open PDF File',
            child: isMobile
                ? IconButton(
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: _pickLocalPdf,
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.folder_open_outlined, size: 16),
                    label: const Text('Open', style: TextStyle(fontSize: 12)),
                    onPressed: _pickLocalPdf,
                  ),
          ),

          // Test Password Dialog Demo
          IconButton(
            tooltip: 'Test Password Dialog',
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final password = await PdfPasswordDialog.show(
                context,
                documentName: _currentSource?.name ?? 'Sample_NDA.pdf',
              );
              if (password == null) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Document unlocked with password: "$password"'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
          ),

          // JSON inspect
          IconButton(
            tooltip: 'View Annotations JSON',
            icon: const Icon(Icons.code_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: _showAnnotationsJsonDialog,
          ),

          // Dark / Light Mode Toggle
          IconButton(
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 18,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading || _currentSource == null
          ? const Center(child: CircularProgressIndicator())
          : PdfEditor(
              source: _currentSource!,
              controller: _controller,
              onSave: _onExportPdf,
            ),
    );
  }
}
