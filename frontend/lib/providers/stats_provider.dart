import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import 'settings_provider.dart';

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final settings = ref.watch(settingsProvider);
  return apiService.getUserStats(settings.githubUsername);
});
