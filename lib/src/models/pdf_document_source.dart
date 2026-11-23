import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// Supported types of PDF document sources.
enum PdfSourceType {
  file,
  bytes,
  asset,
  network,
}

/// Represents the source of a PDF document (File, Memory Bytes, Flutter Asset, or URL).
class PdfDocumentSource {
  const PdfDocumentSource._({
    required this.type,
    this.file,
    this.bytes,
    this.assetName,
    this.url,
    this.headers,
    this.name,
  });

  /// Document source from a local filesystem [File].
  factory PdfDocumentSource.file(File file, {String? name}) {
    return PdfDocumentSource._(
      type: PdfSourceType.file,
      file: file,
      name: name ?? file.uri.pathSegments.lastOrNull ?? 'document.pdf',
    );
  }

  /// Document source from raw [Uint8List] bytes.
  factory PdfDocumentSource.bytes(Uint8List bytes, {String? name}) {
    return PdfDocumentSource._(
      type: PdfSourceType.bytes,
      bytes: bytes,
      name: name ?? 'document.pdf',
    );
  }

  /// Document source from a Flutter bundled asset [assetName].
  factory PdfDocumentSource.asset(String assetName, {String? name}) {
    return PdfDocumentSource._(
      type: PdfSourceType.asset,
      assetName: assetName,
      name: name ?? assetName.split('/').last,
    );
  }

  /// Document source from a remote [url] with optional HTTP [headers].
  factory PdfDocumentSource.network(
    String url, {
    Map<String, String>? headers,
    String? name,
  }) {
    return PdfDocumentSource._(
      type: PdfSourceType.network,
      url: url,
      headers: headers,
      name: name ?? Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'downloaded.pdf',
    );
  }

  /// Type of document source.
  final PdfSourceType type;

  /// Underlying file when [type] is [PdfSourceType.file].
  final File? file;

  /// Underlying memory bytes when [type] is [PdfSourceType.bytes].
  final Uint8List? bytes;

  /// Asset bundle path when [type] is [PdfSourceType.asset].
  final String? assetName;

  /// URL when [type] is [PdfSourceType.network].
  final String? url;

  /// HTTP headers for [url].
  final Map<String, String>? headers;

  /// Display name or file name of the document.
  final String? name;

  /// Loads the PDF document data into memory as [Uint8List].
  Future<Uint8List> loadBytes() async {
    switch (type) {
      case PdfSourceType.bytes:
        if (bytes == null) {
          throw StateError('Bytes source has null data');
        }
        return bytes!;
      case PdfSourceType.file:
        if (file == null) {
          throw StateError('File source has null file');
        }
        return await file!.readAsBytes();
      case PdfSourceType.asset:
        if (assetName == null) {
          throw StateError('Asset source has null assetName');
        }
        final byteData = await rootBundle.load(assetName!);
        return byteData.buffer.asUint8List();
      case PdfSourceType.network:
        if (url == null) {
          throw StateError('Network source has null url');
        }
        final res = await http.get(Uri.parse(url!), headers: headers);
        if (res.statusCode != 200) {
          throw HttpException('Failed to load PDF (${res.statusCode}): $url');
        }
        return res.bodyBytes;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PdfDocumentSource) return false;
    if (other.type != type || other.name != name) return false;
    switch (type) {
      case PdfSourceType.file:
        return other.file?.path == file?.path;
      case PdfSourceType.bytes:
        return identical(other.bytes, bytes) || listEquals(other.bytes, bytes);
      case PdfSourceType.asset:
        return other.assetName == assetName;
      case PdfSourceType.network:
        return other.url == url;
    }
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      name,
      file?.path,
      assetName,
      url,
      bytes?.lengthInBytes,
    );
  }
}
