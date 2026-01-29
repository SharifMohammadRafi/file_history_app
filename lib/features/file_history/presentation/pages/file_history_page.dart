import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simplest_document_scanner/simplest_document_scanner.dart';

import 'package:file_history_app/features/file_history/presentation/bloc/file_history_bloc.dart';
import 'package:file_history_app/features/file_history/presentation/bloc/file_history_event.dart';
import 'package:file_history_app/features/file_history/presentation/bloc/file_history_state.dart';
import 'package:file_history_app/features/file_history/presentation/pages/file_detail_page.dart';
import 'package:file_history_app/features/file_history/presentation/pages/starred_files_page.dart';
import 'package:file_history_app/features/file_history/presentation/widgets/file_list_item.dart';

enum _ScanSource { camera, file }

class FileHistoryPage extends StatelessWidget {
  const FileHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<FileHistoryBloc, FileHistoryState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'File History App',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'View starred items',
              icon: const Icon(Icons.star_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StarredFilesPage()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // SEARCH BY NAME
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  onChanged: (value) {
                    context.read<FileHistoryBloc>().add(
                      FileHistorySearchQueryChanged(value),
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<FileHistoryBloc, FileHistoryState>(
                  builder: (context, state) {
                    if (state.status == FileHistoryStatus.loading &&
                        state.files.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == FileHistoryStatus.failure &&
                        state.files.isEmpty) {
                      return Center(
                        child: Text(state.errorMessage ?? 'Unknown error'),
                      );
                    }

                    final files = state.filteredFiles;

                    if (files.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              size: 56,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No files in history yet',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the scan button to add your first document.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withAlpha(204),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<FileHistoryBloc>().add(
                          const FileHistoryRefreshRequested(),
                        );
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          return FileListItem(
                            index: index + 1, // serial number (1-based)
                            file: file,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FileDetailPage(file: file),
                                ),
                              );
                            },
                            onFavoriteToggle: () {
                              context.read<FileHistoryBloc>().add(
                                FileHistoryFavoriteToggled(file.path),
                              );
                            },
                            onDelete: () {
                              context.read<FileHistoryBloc>().add(
                                FileHistoryFileDeleted(file.path),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.document_scanner_rounded),
          onPressed: () async {
            try {
              final source = await _chooseScanSource(context);
              if (source == null) return;

              if (source == _ScanSource.camera) {
                await _scanWithScannerPlugin(context);
              } else {
                final pdfPath = await _pickPdfFile();
                if (pdfPath != null && context.mounted) {
                  context.read<FileHistoryBloc>().add(
                    FileHistoryFileAdded(pdfPath),
                  );
                }
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to scan/select document: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<_ScanSource?> _chooseScanSource(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return showModalBottomSheet<_ScanSource>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Scan with camera'),
                  subtitle: const Text('Use simplest_document_scanner'),
                  onTap: () {
                    Navigator.of(sheetContext).pop(_ScanSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.insert_drive_file_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Pick PDF from files'),
                  subtitle: const Text('Import existing PDF document'),
                  onTap: () {
                    Navigator.of(sheetContext).pop(_ScanSource.file);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scanWithScannerPlugin(BuildContext context) async {
    const options = DocumentScannerOptions(
      maxPages: 8,
      returnJpegs: true,
      returnPdf: true,
      jpegQuality: 0.9,
      allowGalleryImport: true,
      android: AndroidScannerOptions(scannerMode: DocumentScannerMode.full),
      ios: IosScannerOptions(enforceMaxPageLimit: true),
    );

    final ScannedDocument? document =
        await SimplestDocumentScanner.scanDocuments(options: options);

    if (document == null || (document.pages.isEmpty && !document.hasPdf)) {
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final baseDirPath = '${dir.path}${Platform.pathSeparator}scanned_docs';
    final baseDir = Directory(baseDirPath);

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bloc = context.read<FileHistoryBloc>();

    if (document.pdfBytes != null) {
      final pdfPath =
          '$baseDirPath${Platform.pathSeparator}scan_$timestamp.pdf';
      await File(pdfPath).writeAsBytes(document.pdfBytes!, flush: true);
      if (context.mounted) {
        bloc.add(FileHistoryFileAdded(pdfPath));
      }
    }

    for (final page in document.pages) {
      final imgPath =
          '$baseDirPath${Platform.pathSeparator}scan_${timestamp}_page_${page.index + 1}.jpg';
      await File(imgPath).writeAsBytes(page.bytes, flush: true);
      if (context.mounted) {
        bloc.add(FileHistoryFileAdded(imgPath));
      }
    }
  }

  Future<String?> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.path == null) return null;

    final f = File(file.path!);
    if (!await f.exists()) return null;

    return file.path!;
  }
}
