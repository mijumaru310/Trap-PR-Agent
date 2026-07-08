import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _githubUsernameController;
  late TextEditingController _githubTokenController;
  late TextEditingController _aiApiKeyController;
  String _selectedProvider = 'gemini';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _githubUsernameController = TextEditingController(text: settings.githubUsername);
    _githubTokenController = TextEditingController(text: settings.githubToken);
    _aiApiKeyController = TextEditingController(text: settings.aiApiKey);
    _selectedProvider = settings.aiProvider;
  }

  @override
  void dispose() {
    _githubUsernameController.dispose();
    _githubTokenController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ref.read(settingsProvider.notifier).saveSettings(
          githubUsername: _githubUsernameController.text.trim().isEmpty ? 'mijumaru310' : _githubUsernameController.text.trim(),
          githubToken: _githubTokenController.text.trim(),
          aiProvider: _selectedProvider,
          aiApiKey: _aiApiKeyController.text.trim(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved securely!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                      Text('Security Notice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'These keys are stored securely on your device using encrypted storage. If left blank, the server will use its default environment variables.',
                    style: TextStyle(color: Color(0xFF475569), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _githubUsernameController,
              label: 'GitHub Username',
              hint: 'e.g. octocat',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _githubTokenController,
              label: 'GitHub Personal Access Token',
              hint: 'ghp_...',
              icon: Icons.code,
              obscure: true,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: InputDecoration(
                labelText: 'AI Provider',
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0052FF), width: 2)),
                prefixIcon: const Icon(Icons.smart_toy_outlined, color: Color(0xFF64748B)),
              ),
              items: const [
                DropdownMenuItem(value: 'gemini', child: Text('Google Gemini (gemini-2.5-flash)')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI (gpt-4o)')),
                DropdownMenuItem(value: 'anthropic', child: Text('Anthropic (claude-3-5-sonnet)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedProvider = val;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _aiApiKeyController,
              label: 'AI API Key',
              hint: 'API key for the selected provider',
              icon: Icons.vpn_key_outlined,
              obscure: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
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
