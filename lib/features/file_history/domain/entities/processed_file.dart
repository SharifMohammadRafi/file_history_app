import 'package:equatable/equatable.dart';

enum ProcessedFileType { pdf, image, other }

class ProcessedFile extends Equatable {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;
  final ProcessedFileType type;
  final bool isFavorite;
  final bool existsOnDisk;

  const ProcessedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
    this.lastOpenedAt,
    required this.type,
    required this.isFavorite,
    required this.existsOnDisk,
  });

  ProcessedFile copyWith({
    String? path,
    String? name,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    ProcessedFileType? type,
    bool? isFavorite,
    bool? existsOnDisk,
  }) {
    return ProcessedFile(
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      existsOnDisk: existsOnDisk ?? this.existsOnDisk,
    );
  }

  @override
  List<Object?> get props => [
    path,
    name,
    sizeBytes,
    createdAt,
    lastOpenedAt,
    type,
    isFavorite,
    existsOnDisk,
  ];
}
