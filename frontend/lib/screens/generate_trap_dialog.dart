import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/settings_provider.dart';

class GenerateTrapDialog extends ConsumerStatefulWidget {
  const GenerateTrapDialog({super.key});

  @override
  ConsumerState<GenerateTrapDialog> createState() => _GenerateTrapDialogState();
}

class _GenerateTrapDialogState extends ConsumerState<GenerateTrapDialog> {
  late TextEditingController _ownerController;
  late TextEditingController _repoController;
  final _pathController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingRepos = false;
  bool _isLoadingFiles = false;

  List<String> _repos = [];
  List<String> _files = [];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ownerController = TextEditingController(text: settings.githubUsername);
    _repoController = TextEditingController();
    
    // Automatically load repos for the default owner
    if (_ownerController.text.isNotEmpty) {
      _loadRepos(_ownerController.text);
    }
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadRepos(String owner) async {
    if (owner.isEmpty) return;
    setState(() {
      _isLoadingRepos = true;
      _repos = [];
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final repos = await apiService.getGitHubRepos(owner);
      if (mounted) {
        setState(() {
          _repos = repos;
        });
      }
    } catch (e) {
      debugPrint('Error loading repos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRepos = false;
        });
      }
    }
  }

  Future<void> _loadFiles(String owner, String repo) async {
    if (owner.isEmpty || repo.isEmpty) return;
    setState(() {
      _isLoadingFiles = true;
      _files = [];
      _pathController.clear();
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final files = await apiService.getGitHubRepoFiles(owner, repo);
      if (mounted) {
        setState(() {
          _files = files;
        });
      }
    } catch (e) {
      debugPrint('Error loading files: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  Future<void> _generate() async {
    final settings = ref.read(settingsProvider);
    final targetOwner = _ownerController.text.trim();

    if (targetOwner != settings.githubUsername) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ リポジトリの確認'),
          content: Text(
            '設定されたGitHubユーザー名（${settings.githubUsername}）とは異なるリポジトリ（$targetOwner）にPRを作成しようとしています。続行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('作成する', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.generateAutoTrapPR(
        targetOwner,
        _repoController.text.trim(),
        _pathController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('罠PRを生成しました！自動採点が有効です。')),
        );
        ref.invalidate(statsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('罠PR生成'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'リポジトリと対象ファイル（任意）を選択してください。',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ownerController,
              decoration: InputDecoration(
                labelText: 'Owner (ユーザー/組織名)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadRepos(_ownerController.text.trim()),
                  tooltip: 'リポジトリを再読み込み',
                ),
              ),
              onSubmitted: (value) => _loadRepos(value.trim()),
            ),
            const SizedBox(height: 20),
            _isLoadingRepos
                ? const LinearProgressIndicator()
                : DropdownMenu<String>(
                    controller: _repoController,
                    label: const Text('リポジトリ'),
                    expandedInsets: EdgeInsets.zero,
                    enableFilter: true,
                    dropdownMenuEntries: _repos.map((repo) {
                      return DropdownMenuEntry(value: repo, label: repo);
                    }).toList(),
                    onSelected: (value) {
                      if (value != null) {
                        _loadFiles(_ownerController.text.trim(), value);
                      }
                    },
                  ),
            const SizedBox(height: 20),
            _isLoadingFiles
                ? const LinearProgressIndicator()
                : DropdownMenu<String>(
                    controller: _pathController,
                    label: const Text('ファイルパス (任意: 未指定なら新規作成)'),
                    expandedInsets: EdgeInsets.zero,
                    enableFilter: true,
                    dropdownMenuEntries: _files.map((file) {
                      return DropdownMenuEntry(value: file, label: file);
                    }).toList(),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _generate,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('生成する'),
        ),
      ],
    );
  }
}
