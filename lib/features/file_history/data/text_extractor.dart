import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class TextExtractor {
  static Future<String> extractTextFromPdf(String path) async {
    final pdfFile = File(path);
    if (!await pdfFile.exists()) {
      debugPrint('[TextExtractor] PDF does not exist at $path');
      return '';
    }

    try {
      final bytes = await pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final pdfText = extractor.extractText();
      document.dispose();

      final trimmedPdfText = pdfText.trim();
      if (trimmedPdfText.isNotEmpty) {
        debugPrint(
          '[TextExtractor] PDF text layer found (${trimmedPdfText.length} chars).',
        );
        return trimmedPdfText;
      }

      debugPrint(
        '[TextExtractor] PDF text layer empty, trying OCR on page images.',
      );

      final ocrText = await _extractTextFromAssociatedImages(pdfFile);
      return ocrText.trim();
    } catch (e, st) {
      debugPrint('[TextExtractor] Error extracting PDF text: $e\n$st');
      return 'Failed to extract text from PDF: $e';
    }
  }

  static Future<String> extractTextFromImage(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      debugPrint('[TextExtractor] Image does not exist at $path');
      return '';
    }

    try {
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      await textRecognizer.close();

      return recognizedText.text.trim();
    } on MissingPluginException catch (e, st) {
      debugPrint('[TextExtractor] ML Kit plugin not available: $e\n$st');
      return 'Text recognition is not available on this build '
          '(ML Kit plugin not registered).';
    } catch (e, st) {
      debugPrint('[TextExtractor] Error extracting image text: $e\n$st');
      return 'Failed to extract text from image: $e';
    }
  }

  static Future<String> _extractTextFromAssociatedImages(File pdfFile) async {
    try {
      final dir = pdfFile.parent;
      final fileName = pdfFile.uri.pathSegments.last;

      String baseName = fileName;
      final dotIndex = baseName.lastIndexOf('.');
      if (dotIndex != -1) {
        baseName = baseName.substring(0, dotIndex);
      }

      final entities = await dir.list().toList();
      final List<File> imageFiles = [];

      for (final entity in entities) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.startsWith('${baseName}_page_')) continue;

        if (name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png')) {
          imageFiles.add(entity);
        }
      }

      if (imageFiles.isEmpty) {
        debugPrint(
          '[TextExtractor] No associated page images found for PDF ${pdfFile.path}',
        );
        return '';
      }

      imageFiles.sort((a, b) {
        int indexOf(File f) {
          final n = f.uri.pathSegments.last;
          final match = RegExp(r'_page_(\d+)\.').firstMatch(n);
          if (match == null) return 0;
          return int.tryParse(match.group(1) ?? '0') ?? 0;
        }

        return indexOf(a).compareTo(indexOf(b));
      });

      final buffer = StringBuffer();
      for (final img in imageFiles) {
        debugPrint('[TextExtractor] OCR on associated image: ${img.path}');
        final text = await extractTextFromImage(img.path);
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln('\n\n');
          buffer.writeln(text);
        }
      }

      final result = buffer.toString().trim();
      debugPrint(
        '[TextExtractor] OCR from associated images length: ${result.length}',
      );
      return result;
    } catch (e, st) {
      debugPrint(
        '[TextExtractor] Error while OCR from associated images: $e\n$st',
      );
      return '';
    }
  }
}
