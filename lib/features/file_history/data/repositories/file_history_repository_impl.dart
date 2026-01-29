import 'dart:io';

import 'package:mime/mime.dart';

import 'package:file_history_app/features/file_history/domain/entities/processed_file.dart';
import 'package:file_history_app/features/file_history/domain/repositories/file_history_repository.dart';

import '../datasources/file_history_local_data_source.dart';

class FileHistoryRepositoryImpl implements FileHistoryRepository {
  final FileHistoryLocalDataSource localDataSource;

  FileHistoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<ProcessedFile>> getAllFiles() async {
    try {
      final entries = localDataSource.getAllEntries();
      final List<ProcessedFile> files = [];

      for (final entry in entries) {
        final path = entry.key;
        final map = entry.value;
        files.add(_mapToEntity(path, map));
      }

      files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return files;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addOrUpdateFromPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return;
      }

      final stat = await file.stat();
      final mime = lookupMimeType(path) ?? '';
      final type = _detectTypeFromMimeOrExtension(mime, path);

      final now = DateTime.now();

      final existing = localDataSource.get(path);
      final createdAtMs = existing?['createdAt'] as int?;
      final createdAt = createdAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : stat.modified;

      final isFavorite = existing?['isFavorite'] as bool? ?? false;

      final map = <String, dynamic>{
        'name': _extractNameFromPath(path),
        'size': stat.size,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastOpenedAt': now.millisecondsSinceEpoch,
        'type': _typeToString(type),
        'isFavorite': isFavorite,
      };

      await localDataSource.upsert(path, map);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> toggleFavorite(String path) async {
    try {
      final map = localDataSource.get(path);
      if (map == null) return;

      final current = map['isFavorite'] as bool? ?? false;
      map['isFavorite'] = !current;

      await localDataSource.upsert(path, map);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await localDataSource.delete(path);
    } catch (e) {
      rethrow;
    }
  }

  ProcessedFile _mapToEntity(String path, Map<String, dynamic> map) {
    final createdAtMs = map['createdAt'] as int?;
    final lastOpenedMs = map['lastOpenedAt'] as int?;
    final typeStr = map['type'] as String? ?? 'other';

    final file = File(path);
    final exists = file.existsSync();

    return ProcessedFile(
      path: path,
      name: map['name'] as String? ?? _extractNameFromPath(path),
      sizeBytes: map['size'] as int? ?? 0,
      createdAt: createdAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : DateTime.now(),
      lastOpenedAt: lastOpenedMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastOpenedMs)
          : null,
      type: _typeFromString(typeStr, path),
      isFavorite: map['isFavorite'] as bool? ?? false,
      existsOnDisk: exists,
    );
  }

  ProcessedFileType _detectTypeFromMimeOrExtension(String mime, String path) {
    final lowerPath = path.toLowerCase();

    if (mime.startsWith('application/pdf') || lowerPath.endsWith('.pdf')) {
      return ProcessedFileType.pdf;
    }

    if (mime.startsWith('image/') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.heic')) {
      return ProcessedFileType.image;
    }

    return ProcessedFileType.other;
  }

  String _typeToString(ProcessedFileType type) {
    switch (type) {
      case ProcessedFileType.pdf:
        return 'pdf';
      case ProcessedFileType.image:
        return 'image';
      case ProcessedFileType.other:
        return 'other';
    }
  }

  ProcessedFileType _typeFromString(String type, String path) {
    switch (type) {
      case 'pdf':
        return ProcessedFileType.pdf;
      case 'image':
        return ProcessedFileType.image;
      default:
        return _detectTypeFromMimeOrExtension('', path);
    }
  }

  String _extractNameFromPath(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}
