import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../main.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _githubUsernameController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();

  @override
  void dispose() {
    _githubUsernameController.dispose();
    _githubTokenController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final username = _githubUsernameController.text.trim().isEmpty 
        ? 'mijumaru310' 
        : _githubUsernameController.text.trim();
        
    await ref.read(settingsProvider.notifier).saveSettings(
      githubUsername: username,
      githubToken: _githubTokenController.text.trim(),
      aiProvider: ref.read(settingsProvider).aiProvider,
      aiApiKey: ref.read(settingsProvider).aiApiKey,
      isOnboarded: true,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Color(0xFF0052FF)),
              const SizedBox(height: 24),
              const Text(
                'Trap-PR Agent へようこそ！',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'このアプリはAIが生成した「罠」入りのプルリクエストを通じて、あなたのコードレビュー力を鍛えます。',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              const Text(
                'GitHubアカウント設定',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ご自身の環境で罠PRを作成するために、GitHubの情報を入力してください。（後から設定画面で変更・追加することも可能です）',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: _githubUsernameController,
                decoration: InputDecoration(
                  labelText: 'GitHub ユーザー名',
                  hintText: '例: octocat',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _githubTokenController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'GitHub パーソナルアクセストークン (任意)',
                  hintText: 'ghp_...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _finishOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('保存して始める', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _finishOnboarding,
                child: const Text('今はスキップする', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
