import 'package:flutter/material.dart';

import 'package:file_history_app/core/utils/format_utils.dart';
import 'package:file_history_app/features/file_history/domain/entities/processed_file.dart';

class FileListItem extends StatelessWidget {
  final int index; // 1-based index for serial number
  final ProcessedFile file;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const FileListItem({
    Key? key,
    required this.index,
    required this.file,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabel(file.type);
    final sizeLabel = formatBytes(file.sizeBytes);
    final dateLabel = formatDateTime(file.createdAt);
    final existsLabel = file.existsOnDisk ? '' : ' · Missing';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Serial number
              SizedBox(
                width: 32,
                child: Text(
                  '$index.',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // File icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _fileIcon(file),
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: file.existsOnDisk
                            ? null
                            : TextDecoration.lineThrough,
                        color: file.existsOnDisk
                            ? null
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sizeLabel · $dateLabel · $typeLabel$existsLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Favorite & delete buttons
              IconButton(
                icon: Icon(
                  file.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: file.isFavorite
                      ? Colors.amber
                      : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                tooltip: file.isFavorite ? 'Unfavorite' : 'Favorite',
                onPressed: onFavoriteToggle,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error.withOpacity(0.9),
                  size: 22,
                ),
                tooltip: 'Delete from history',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
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
      default:
        return 'Other';
    }
  }

  IconData _fileIcon(ProcessedFile file) {
    switch (file.type) {
      case ProcessedFileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case ProcessedFileType.image:
        return Icons.image_rounded;
      case ProcessedFileType.other:
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
