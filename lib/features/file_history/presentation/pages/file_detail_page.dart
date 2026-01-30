import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:file_history_app/core/utils/format_utils.dart';
import 'package:file_history_app/features/file_history/data/text_extractor.dart';
import 'package:file_history_app/features/file_history/domain/entities/processed_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileDetailPage extends StatefulWidget {
  final ProcessedFile file;

  const FileDetailPage({super.key, required this.file});

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  late Future<String?> _textFuture;

  @override
  void initState() {
    super.initState();
    _textFuture = _loadExtractedText();
  }

  String get _displayName => widget.file.name.replaceAll('_', ' ');

  Future<String?> _loadExtractedText() async {
    final file = widget.file;

    if (!file.existsOnDisk) {
      return 'File is missing on disk.';
    }

    try {
      switch (file.type) {
        case ProcessedFileType.pdf:
          return await TextExtractor.extractTextFromPdf(file.path);
        case ProcessedFileType.image:
          return await TextExtractor.extractTextFromImage(file.path);
        case ProcessedFileType.other:
          return 'Text extraction is only supported for PDFs and images.';
      }
    } catch (e, st) {
      debugPrint('[FileDetailPage] Error extracting text: $e\n$st');
      return 'Failed to extract text: $e';
    }
  }

  Future<bool> _ensureStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Storage permission is required to save files.'),
      ),
    );
    return false;
  }

  Future<Directory?> _getDownloadsDirectory() async {
    final dir = Directory('/storage/emulated/0/Download');
    if (await dir.exists()) return dir;
    return null;
  }

  Future<bool> _confirmSaveDialog(String fileName) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Save file'),
              content: Text(
                'Do you want to save "$fileName" to your Downloads folder?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Export the extracted text as a new text-only PDF (for PDF files).
  Future<void> _exportTextAsPdf() async {
    final file = widget.file;

    if (!file.existsOnDisk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File is missing on disk.')));
      return;
    }

    if (file.type != ProcessedFileType.pdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export text PDF is only for PDFs.')),
      );
      return;
    }

    if (!await _ensureStoragePermission()) return;

    final text = ((await _textFuture) ?? '').trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text available to export.')),
      );
      return;
    }

    final originalFile = File(file.path);
    final name = originalFile.uri.pathSegments.last;
    String baseName = name;
    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = baseName.substring(0, dotIndex);
    }
    final outFileName = '${baseName}_text.pdf';

    final userConfirmed = await _confirmSaveDialog(
      outFileName.replaceAll('_', ' '),
    );
    if (!userConfirmed) return;

    try {
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloads folder not found on this device.'),
          ),
        );
        return;
      }

      final document = PdfDocument();
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final brush = PdfSolidBrush(PdfColor(0, 0, 0));
      final textElement = PdfTextElement(text: text, font: font, brush: brush);

      final layoutFormat = PdfLayoutFormat(layoutType: PdfLayoutType.paginate);

      textElement.draw(
        page: page,
        bounds: ui.Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
        format: layoutFormat,
      );

      final bytes = await document.save();
      document.dispose();

      final outPath = '${downloadsDir.path}/$outFileName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Text PDF saved to:\n$outPath')));
    } catch (e, st) {
      debugPrint('[FileDetailPage] Error exporting text PDF: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export text PDF: $e')));
    }
  }

  /// Export an image file as a one-page PDF (for image files).
  Future<void> _exportImageAsPdf() async {
    final file = widget.file;

    if (!file.existsOnDisk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File is missing on disk.')));
      return;
    }

    if (file.type != ProcessedFileType.image) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export image PDF is only for images.')),
      );
      return;
    }

    if (!await _ensureStoragePermission()) return;

    final imageFile = File(file.path);
    final name = imageFile.uri.pathSegments.last;
    String baseName = name;
    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex != -1) {
      baseName = baseName.substring(0, dotIndex);
    }
    final outFileName = '${baseName}_image.pdf';

    final userConfirmed = await _confirmSaveDialog(
      outFileName.replaceAll('_', ' '),
    );
    if (!userConfirmed) return;

    try {
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloads folder not found on this device.'),
          ),
        );
        return;
      }

      final imageBytes = await imageFile.readAsBytes();

      final document = PdfDocument();
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      final pdfImage = PdfBitmap(imageBytes);

      final imgWidth = pdfImage.width.toDouble();
      final imgHeight = pdfImage.height.toDouble();
      final pageRatio = pageSize.width / pageSize.height;
      final imgRatio = imgWidth / imgHeight;

      double drawWidth;
      double drawHeight;

      if (imgRatio > pageRatio) {
        drawWidth = pageSize.width;
        drawHeight = drawWidth / imgRatio;
      } else {
        drawHeight = pageSize.height;
        drawWidth = drawHeight * imgRatio;
      }

      final dx = (pageSize.width - drawWidth) / 2;
      final dy = (pageSize.height - drawHeight) / 2;

      page.graphics.drawImage(
        pdfImage,
        ui.Rect.fromLTWH(dx, dy, drawWidth, drawHeight),
      );

      final bytes = await document.save();
      document.dispose();

      final outPath = '${downloadsDir.path}/$outFileName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image PDF saved to:\n$outPath')));
    } catch (e, st) {
      debugPrint('[FileDetailPage] Error exporting image PDF: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export image PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final typeLabel = _typeLabel(file.type);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName),
        actions: [
          if (file.type == ProcessedFileType.pdf && file.existsOnDisk)
            IconButton(
              tooltip: 'Download text as PDF',
              icon: const Icon(Icons.download_rounded),
              onPressed: _exportTextAsPdf,
            ),
          if (file.type == ProcessedFileType.image && file.existsOnDisk)
            IconButton(
              tooltip: 'Download image as PDF',
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _exportImageAsPdf,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _detailRow('File name', _displayName),
                    _detailRow('Path', file.path),
                    _detailRow('Type', typeLabel),
                    _detailRow('Size', formatBytes(file.sizeBytes)),
                    _detailRow(
                      'Created at (first seen)',
                      formatDateTime(file.createdAt),
                    ),
                    if (file.lastOpenedAt != null)
                      _detailRow(
                        'Last opened',
                        formatDateTime(file.lastOpenedAt!),
                      ),
                    _detailRow(
                      'Exists on disk',
                      file.existsOnDisk ? 'Yes' : 'No (Missing)',
                    ),
                    _detailRow('Favorite', file.isFavorite ? 'Yes' : 'No'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (file.type == ProcessedFileType.image && file.existsOnDisk)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.file(
                            File(file.path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (file.type == ProcessedFileType.image && file.existsOnDisk)
              const SizedBox(height: 12),

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String?>(
                  future: _textFuture,
                  builder: (context, snapshot) {
                    final titleLabel = file.type == ProcessedFileType.pdf
                        ? 'Extracted text (PDF)'
                        : file.type == ProcessedFileType.image
                        ? 'Extracted text (image)'
                        : 'Extracted text';

                    final titleRow = Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titleLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData &&
                            (snapshot.data ?? '').trim().isNotEmpty &&
                            file.existsOnDisk)
                          IconButton(
                            tooltip: 'Copy text',
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              final text = (snapshot.data ?? '').trim();
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Text copied to clipboard'),
                                ),
                              );
                            },
                          ),
                      ],
                    );

                    if (!file.existsOnDisk) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 8),
                          const Text('File is missing on disk.'),
                        ],
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      );
                    }

                    final text = (snapshot.data ?? '').trim();

                    if (text.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: 8),
                          const Text(
                            'No text detected or file contains no text.',
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleRow,
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            text,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _typeLabel(ProcessedFileType type) {
    switch (type) {
      case ProcessedFileType.pdf:
        return 'PDF';
      case ProcessedFileType.image:
        return 'Image';
      case ProcessedFileType.other:
        return 'Other';
    }
  }
}
