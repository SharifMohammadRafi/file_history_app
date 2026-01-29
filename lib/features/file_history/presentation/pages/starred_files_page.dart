import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:file_history_app/features/file_history/presentation/bloc/file_history_bloc.dart';
import 'package:file_history_app/features/file_history/presentation/bloc/file_history_event.dart';
import 'package:file_history_app/features/file_history/presentation/bloc/file_history_state.dart';
import 'package:file_history_app/features/file_history/presentation/pages/file_detail_page.dart';
import 'package:file_history_app/features/file_history/presentation/widgets/file_list_item.dart';

class StarredFilesPage extends StatelessWidget {
  const StarredFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Starred files')),
      body: SafeArea(
        child: BlocBuilder<FileHistoryBloc, FileHistoryState>(
          builder: (context, state) {
            final favorites = state.files
                .where((f) => f.isFavorite)
                .toList(growable: false);

            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      size: 56,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No starred files yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mark files as favorite to see them here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final file = favorites[index];
                return FileListItem(
                  index: index + 1,
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
            );
          },
        ),
      ),
    );
  }
}
