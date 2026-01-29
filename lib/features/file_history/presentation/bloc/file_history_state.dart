import 'package:equatable/equatable.dart';

import 'package:file_history_app/features/file_history/domain/entities/processed_file.dart';

enum FileHistoryStatus { initial, loading, success, failure }

class FileHistoryState extends Equatable {
  final FileHistoryStatus status;
  final List<ProcessedFile> files;
  final String searchQuery;
  final String? errorMessage;

  const FileHistoryState({
    required this.status,
    required this.files,
    required this.searchQuery,
    required this.errorMessage,
  });

  factory FileHistoryState.initial() {
    return const FileHistoryState(
      status: FileHistoryStatus.initial,
      files: [],
      searchQuery: '',
      errorMessage: null,
    );
  }

  List<ProcessedFile> get filteredFiles {
    if (searchQuery.isEmpty) return files;
    final q = searchQuery.toLowerCase();
    return files
        .where((f) => f.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  FileHistoryState copyWith({
    FileHistoryStatus? status,
    List<ProcessedFile>? files,
    String? searchQuery,
    String? errorMessage,
  }) {
    return FileHistoryState(
      status: status ?? this.status,
      files: files ?? this.files,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, files, searchQuery, errorMessage];
}
