import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../providers/stats_provider.dart';

class GenerateTrapDialog extends ConsumerStatefulWidget {
  const GenerateTrapDialog({super.key});

  @override
  ConsumerState<GenerateTrapDialog> createState() => _GenerateTrapDialogState();
}

class _GenerateTrapDialogState extends ConsumerState<GenerateTrapDialog> {
  final _ownerController = TextEditingController(text: defaultOwner);
  final _repoController = TextEditingController(text: defaultRepo);
  final _pathController = TextEditingController();

  bool _isLoading = false;
  
  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.generateAutoTrapPR(
        _ownerController.text,
        _repoController.text,
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
              'Language & branch name are auto-generated.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(controller: _ownerController, decoration: const InputDecoration(labelText: 'Owner')),
            TextField(controller: _repoController, decoration: const InputDecoration(labelText: 'Repo')),
            TextField(controller: _pathController, decoration: const InputDecoration(labelText: 'File Path (Optional)')),
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
