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
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.generateAutoTrapPR(
        _ownerController.text.trim(),
        _repoController.text.trim(),
        _pathController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trap PR generated! Auto-scoring is active.')),
        );
        ref.invalidate(statsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      title: const Text('Generate Trap PR'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select repository and file path to generate a PR.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ownerController,
              decoration: InputDecoration(
                labelText: 'Owner',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadRepos(_ownerController.text.trim()),
                  tooltip: 'Reload Repos',
                ),
              ),
              onSubmitted: (value) => _loadRepos(value.trim()),
            ),
            const SizedBox(height: 20),
            _isLoadingRepos
                ? const LinearProgressIndicator()
                : DropdownMenu<String>(
                    controller: _repoController,
                    label: const Text('Repo'),
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
                    label: const Text('File Path (Optional)'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _generate,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Generate'),
        ),
      ],
    );
  }
}
