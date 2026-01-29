import 'package:hive/hive.dart';

class FileHistoryLocalDataSource {
  final Box _box;

  FileHistoryLocalDataSource(this._box);

  Future<void> upsert(String path, Map<String, dynamic> data) async {
    await _box.put(path, data);
  }

  Future<void> delete(String path) async {
    await _box.delete(path);
  }

  Map<String, dynamic>? get(String path) {
    final raw = _box.get(path);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Iterable<MapEntry<String, Map<String, dynamic>>> getAllEntries() {
    final rawMap = _box.toMap();
    return rawMap.entries
        .where((e) => e.key is String && e.value is Map)
        .map(
          (e) => MapEntry<String, Map<String, dynamic>>(
            e.key as String,
            Map<String, dynamic>.from(e.value as Map),
          ),
        );
  }
}
