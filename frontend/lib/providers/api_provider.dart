import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final settings = ref.watch(settingsProvider);
  return ApiService(
    githubToken: settings.githubToken,
    aiProvider: settings.aiProvider,
    aiApiKey: settings.aiApiKey,
  );
});
