import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettings {
  final String githubUsername;
  final String githubToken;
  final String aiProvider;
  final String aiApiKey;

  AppSettings({
    this.githubUsername = 'mijumaru310',
    this.githubToken = '',
    this.aiProvider = 'gemini',
    this.aiApiKey = '',
  });

  AppSettings copyWith({
    String? githubUsername,
    String? githubToken,
    String? aiProvider,
    String? aiApiKey,
  }) {
    return AppSettings(
      githubUsername: githubUsername ?? this.githubUsername,
      githubToken: githubToken ?? this.githubToken,
      aiProvider: aiProvider ?? this.aiProvider,
      aiApiKey: aiApiKey ?? this.aiApiKey,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings();
  }

  Future<void> _loadSettings() async {
    final username = await _storage.read(key: 'githubUsername') ?? 'mijumaru310';
    final token = await _storage.read(key: 'githubToken') ?? '';
    final provider = await _storage.read(key: 'aiProvider') ?? 'gemini';
    final apiKey = await _storage.read(key: 'aiApiKey') ?? '';

    state = AppSettings(
      githubUsername: username,
      githubToken: token,
      aiProvider: provider,
      aiApiKey: apiKey,
    );
  }

  Future<void> saveSettings({
    required String githubUsername,
    required String githubToken,
    required String aiProvider,
    required String aiApiKey,
  }) async {
    await _storage.write(key: 'githubUsername', value: githubUsername);
    await _storage.write(key: 'githubToken', value: githubToken);
    await _storage.write(key: 'aiProvider', value: aiProvider);
    await _storage.write(key: 'aiApiKey', value: aiApiKey);

    state = AppSettings(
      githubUsername: githubUsername,
      githubToken: githubToken,
      aiProvider: aiProvider,
      aiApiKey: aiApiKey,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
