import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_history_app/core/utils/format_utils.dart';
import 'package:file_history_app/features/file_history/data/text_extractor.dart';
import 'package:file_history_app/features/file_history/domain/entities/processed_file.dart';

class FileDetailPage extends StatefulWidget {
  final ProcessedFile file;

  const FileDetailPage({Key? key, required this.file}) : super(key: key);

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

    return Scaffold(
      appBar: AppBar(title: Text(file.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('File name'), subtitle: Text(file.name)),
          ListTile(title: const Text('Path'), subtitle: Text(file.path)),
          ListTile(title: const Text('Type'), subtitle: Text(typeLabel)),
          ListTile(
            title: const Text('Size'),
            subtitle: Text(formatBytes(file.sizeBytes)),
          ),
          ListTile(
            title: const Text('Created at (first seen)'),
            subtitle: Text(formatDateTime(file.createdAt)),
          ),
          if (file.lastOpenedAt != null)
            ListTile(
              title: const Text('Last opened'),
              subtitle: Text(formatDateTime(file.lastOpenedAt!)),
            ),
          ListTile(
            title: const Text('Exists on disk'),
            subtitle: Text(file.existsOnDisk ? 'Yes' : 'No (Missing)'),
          ),
          ListTile(
            title: const Text('Favorite'),
            subtitle: Text(file.isFavorite ? 'Yes' : 'No'),
          ),
          const SizedBox(height: 16),

          if (file.type == ProcessedFileType.image && file.existsOnDisk)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(File(file.path), fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
              ],
            ),

          FutureBuilder<String?>(
            future: _textFuture,
            builder: (context, snapshot) {
              final titleText = Text(
                'Extracted text',
                style: Theme.of(context).textTheme.titleMedium,
              );

              if (!file.existsOnDisk) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    const SizedBox(height: 8),
                    const Text('File is missing on disk.'),
                  ],
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                );
              }

              final text = (snapshot.data ?? '').trim();

              if (text.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    const SizedBox(height: 8),
                    const Text('No text detected or file contains no text.'),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleText,
                  const SizedBox(height: 8),
                  SelectableText(text, style: const TextStyle(height: 1.4)),
                ],
              );
            },
          ),
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
