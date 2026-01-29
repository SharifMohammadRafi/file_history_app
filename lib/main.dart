import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:file_history_app/core/theme/app_theme.dart';
import 'package:file_history_app/features/file_history/data/datasources/file_history_local_data_source.dart';
import 'package:file_history_app/features/file_history/data/repositories/file_history_repository_impl.dart';
import 'package:file_history_app/features/file_history/domain/repositories/file_history_repository.dart';
import 'package:file_history_app/features/file_history/presentation/bloc/file_history_bloc.dart';
import 'package:file_history_app/features/file_history/presentation/bloc/file_history_event.dart';
import 'package:file_history_app/features/file_history/presentation/pages/file_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final box = await Hive.openBox('file_history');

  final localDataSource = FileHistoryLocalDataSource(box);
  final repository = FileHistoryRepositoryImpl(localDataSource);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final FileHistoryRepository repository;

  const MyApp({Key? key, required this.repository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<FileHistoryRepository>.value(
      value: repository,
      child: BlocProvider(
        create: (_) =>
            FileHistoryBloc(repository)..add(const FileHistoryStarted()),
        child: MaterialApp(
          title: 'File History',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // follow system light/dark
          debugShowCheckedModeBanner: false,
          home: const FileHistoryPage(),
        ),
      ),
    );
  }
}
