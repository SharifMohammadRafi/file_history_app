import 'package:equatable/equatable.dart';

abstract class FileHistoryEvent extends Equatable {
  const FileHistoryEvent();

  @override
  List<Object?> get props => [];
}

class FileHistoryStarted extends FileHistoryEvent {
  const FileHistoryStarted();
}

class FileHistoryFileAdded extends FileHistoryEvent {
  final String path;

  const FileHistoryFileAdded(this.path);

  @override
  List<Object?> get props => [path];
}

class FileHistoryFavoriteToggled extends FileHistoryEvent {
  final String path;

  const FileHistoryFavoriteToggled(this.path);

  @override
  List<Object?> get props => [path];
}

class FileHistoryFileDeleted extends FileHistoryEvent {
  final String path;

  const FileHistoryFileDeleted(this.path);

  @override
  List<Object?> get props => [path];
}

class FileHistorySearchQueryChanged extends FileHistoryEvent {
  final String query;

  const FileHistorySearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FileHistoryRefreshRequested extends FileHistoryEvent {
  const FileHistoryRefreshRequested();
}
