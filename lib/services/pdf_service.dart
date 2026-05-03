import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// On-device PDF text extraction using Syncfusion.
class PdfService {
  /// Extract all text from a PDF file given its bytes.
  static Future<String> extractText(Uint8List bytes) async {
    return compute(_extractInBackground, bytes);
  }

  static String _extractInBackground(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text.trim();
    } catch (e) {
      throw Exception('PDF extraction failed: $e');
    }
  }
}
