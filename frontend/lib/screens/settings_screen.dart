import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/api_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _githubUsernameController;
  late TextEditingController _githubTokenController;
  String _selectedProvider = 'vertexai';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _githubUsernameController = TextEditingController(text: settings.githubUsername);
    _githubTokenController = TextEditingController(text: settings.githubToken);
  }

  @override
  void dispose() {
    _githubUsernameController.dispose();
    _githubTokenController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    final username = _githubUsernameController.text.trim().isEmpty ? 'mijumaru310' : _githubUsernameController.text.trim();
    String? avatarUrl;

    try {
      final userInfo = await ref.read(apiServiceProvider).getGitHubUserInfo(username);
      avatarUrl = userInfo['avatar_url'];
    } catch (e) {
      // APIに失敗してもアバター取得失敗として無視し、設定は保存する
    }

    await ref.read(settingsProvider.notifier).saveSettings(
          githubUsername: username,
          githubToken: _githubTokenController.text.trim(),
          aiProvider: 'vertexai',
          aiApiKey: '',
          githubAvatarUrl: avatarUrl,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました！')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF0052FF), size: 24),
                      SizedBox(width: 12),
                      Text('セキュリティに関する注意事項', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'APIキーやトークンは、暗号化されたローカルストレージ（デバイス内）に安全に保存されます。空欄の場合、サーバーのデフォルトの環境変数が使用されます。',
                    style: TextStyle(color: Color(0xFF475569), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _githubUsernameController,
              label: 'GitHub ユーザー名',
              hint: '例: octocat',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _githubTokenController,
              label: 'GitHub パーソナルアクセストークン (必須)',
              hint: 'ghp_...',
              icon: Icons.code,
              obscure: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('設定を保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0052FF), width: 2)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      ),
    );
  }
}
