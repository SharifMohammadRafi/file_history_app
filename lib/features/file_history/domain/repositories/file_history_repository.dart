import '../entities/processed_file.dart';

abstract class FileHistoryRepository {
  Future<List<ProcessedFile>> getAllFiles();
  Future<void> addOrUpdateFromPath(String path);
  Future<void> toggleFavorite(String path);
  Future<void> delete(String path);
}
