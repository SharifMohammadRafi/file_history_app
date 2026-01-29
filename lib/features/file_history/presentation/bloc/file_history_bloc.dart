import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:file_history_app/features/file_history/domain/repositories/file_history_repository.dart';

import 'file_history_event.dart';
import 'file_history_state.dart';

class FileHistoryBloc extends Bloc<FileHistoryEvent, FileHistoryState> {
  final FileHistoryRepository repository;

  FileHistoryBloc(this.repository) : super(FileHistoryState.initial()) {
    on<FileHistoryStarted>(_onStarted);
    on<FileHistoryFileAdded>(_onFileAdded);
    on<FileHistoryFavoriteToggled>(_onFavoriteToggled);
    on<FileHistoryFileDeleted>(_onFileDeleted);
    on<FileHistorySearchQueryChanged>(_onSearchChanged);
    on<FileHistoryRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onStarted(
    FileHistoryStarted event,
    Emitter<FileHistoryState> emit,
  ) async {
    await _loadFiles(emit);
  }

  Future<void> _onFileAdded(
    FileHistoryFileAdded event,
    Emitter<FileHistoryState> emit,
  ) async {
    try {
      await repository.addOrUpdateFromPath(event.path);
      await _loadFiles(emit);
    } catch (e) {
      emit(
        state.copyWith(
          status: FileHistoryStatus.failure,
          errorMessage: 'Failed to add file: $e',
        ),
      );
    }
  }

  Future<void> _onFavoriteToggled(
    FileHistoryFavoriteToggled event,
    Emitter<FileHistoryState> emit,
  ) async {
    try {
      await repository.toggleFavorite(event.path);

      final updatedFiles = state.files.map((file) {
        if (file.path == event.path) {
          return file.copyWith(isFavorite: !file.isFavorite);
        }
        return file;
      }).toList();

      emit(state.copyWith(files: updatedFiles));
    } catch (e) {
      emit(
        state.copyWith(
          status: FileHistoryStatus.failure,
          errorMessage: 'Failed to toggle favorite: $e',
        ),
      );
    }
  }

  Future<void> _onFileDeleted(
    FileHistoryFileDeleted event,
    Emitter<FileHistoryState> emit,
  ) async {
    try {
      await repository.delete(event.path);
      final updatedFiles = state.files
          .where((file) => file.path != event.path)
          .toList();
      emit(state.copyWith(files: updatedFiles));
    } catch (e) {
      emit(
        state.copyWith(
          status: FileHistoryStatus.failure,
          errorMessage: 'Failed to delete file: $e',
        ),
      );
    }
  }

  void _onSearchChanged(
    FileHistorySearchQueryChanged event,
    Emitter<FileHistoryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onRefreshRequested(
    FileHistoryRefreshRequested event,
    Emitter<FileHistoryState> emit,
  ) async {
    await _loadFiles(emit);
  }

  Future<void> _loadFiles(Emitter<FileHistoryState> emit) async {
    try {
      emit(
        state.copyWith(status: FileHistoryStatus.loading, errorMessage: null),
      );
      final files = await repository.getAllFiles();
      emit(state.copyWith(status: FileHistoryStatus.success, files: files));
    } catch (e) {
      emit(
        state.copyWith(
          status: FileHistoryStatus.failure,
          errorMessage: 'Failed to load file history: $e',
        ),
      );
    }
  }
}
