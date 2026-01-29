import 'dart:math';

String formatBytes(int bytes, [int decimals = 1]) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  final size = bytes / pow(1024, i);
  return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
}

String formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}
