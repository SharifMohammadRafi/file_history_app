import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_history_app/core/utils/format_utils.dart';
import 'package:file_history_app/features/file_history/data/text_extractor.dart';
import 'package:file_history_app/features/file_history/domain/entities/processed_file.dart';

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

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final typeLabel = _typeLabel(file.type);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(file.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----- DETAILS CARD -----
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
                    _detailRow('File name', file.name),
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

            // ----- IMAGE PREVIEW CARD -----
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

            // ----- EXTRACTED TEXT CARD -----
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String?>(
                  future: _textFuture,
                  builder: (context, snapshot) {
                    final titleRow = Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Extracted text',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // Copy button only when we have non-empty text
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
                            color: colorScheme.surfaceContainerHighest
                                .withAlpha(153),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha(204),
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
