import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _githubTokenController;
  late TextEditingController _aiApiKeyController;
  String _selectedProvider = 'gemini';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _githubTokenController = TextEditingController(text: settings.githubToken);
    _aiApiKeyController = TextEditingController(text: settings.aiApiKey);
    _selectedProvider = settings.aiProvider;
  }

  @override
  void dispose() {
    _githubTokenController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ref.read(settingsProvider.notifier).saveSettings(
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Notice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'These keys are stored securely on your device using encrypted storage. If left blank, the server will use its default environment variables.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _githubTokenController,
              decoration: const InputDecoration(
                labelText: 'GitHub Personal Access Token',
                hintText: 'ghp_...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'AI Provider',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.smart_toy),
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
            TextField(
              controller: _aiApiKeyController,
              decoration: const InputDecoration(
                labelText: 'AI API Key',
                hintText: 'API key for the selected provider',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
