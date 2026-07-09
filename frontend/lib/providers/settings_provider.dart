import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _keyGithubUsername = 'githubUsername';
const String _keyGithubToken = 'githubToken';
const String _keyAiProvider = 'aiProvider';
const String _keyAiApiKey = 'aiApiKey';

class AppSettings {
  final String githubUsername;
  final String githubToken;
  final String aiProvider;
  final String aiApiKey;
  final String? githubAvatarUrl;
  final bool isOnboarded;

  AppSettings({
    this.githubUsername = 'mijumaru310',
    this.githubToken = '',
    this.aiProvider = 'gemini',
    this.aiApiKey = '',
    this.githubAvatarUrl,
    this.isOnboarded = false,
  });

  AppSettings copyWith({
    String? githubUsername,
    String? githubToken,
    String? aiProvider,
    String? aiApiKey,
    String? githubAvatarUrl,
    bool? isOnboarded,
  }) {
    return AppSettings(
      githubUsername: githubUsername ?? this.githubUsername,
      githubToken: githubToken ?? this.githubToken,
      aiProvider: aiProvider ?? this.aiProvider,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      githubAvatarUrl: githubAvatarUrl ?? this.githubAvatarUrl,
      isOnboarded: isOnboarded ?? this.isOnboarded,
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
    final username = await _storage.read(key: _keyGithubUsername) ?? 'mijumaru310';
    final token = await _storage.read(key: _keyGithubToken) ?? '';
    final provider = await _storage.read(key: _keyAiProvider) ?? 'gemini';
    final apiKey = await _storage.read(key: _keyAiApiKey) ?? '';
    final avatar = await _storage.read(key: 'github_avatar_url');
    final onboardedStr = await _storage.read(key: 'is_onboarded');

    state = AppSettings(
      githubUsername: username,
      githubToken: token,
      aiProvider: provider,
      aiApiKey: apiKey,
      githubAvatarUrl: avatar,
      isOnboarded: onboardedStr == 'true',
    );
  }

  Future<void> saveSettings({
    required String githubUsername,
    required String githubToken,
    required String aiProvider,
    required String aiApiKey,
    String? githubAvatarUrl,
    bool? isOnboarded,
  }) async {
    await _storage.write(key: _keyGithubUsername, value: githubUsername);
    await _storage.write(key: _keyGithubToken, value: githubToken);
    await _storage.write(key: _keyAiProvider, value: aiProvider);
    await _storage.write(key: _keyAiApiKey, value: aiApiKey);
    if (githubAvatarUrl != null) {
      await _storage.write(key: 'github_avatar_url', value: githubAvatarUrl);
    }
    if (isOnboarded != null) {
      await _storage.write(key: 'is_onboarded', value: isOnboarded.toString());
    }

    state = state.copyWith(
      githubUsername: githubUsername,
      githubToken: githubToken,
      aiProvider: aiProvider,
      aiApiKey: aiApiKey,
      githubAvatarUrl: githubAvatarUrl,
      isOnboarded: isOnboarded,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
