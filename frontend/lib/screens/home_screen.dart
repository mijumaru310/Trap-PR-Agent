import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ask_ai_screen.dart';
import 'generate_trap_dialog.dart';
import 'settings_screen.dart';
import '../providers/stats_provider.dart';
import '../providers/api_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trap-PR Agent"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const GenerateTrapDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("New Trap PR"),
      ),
      body: statsAsyncValue.when(
        data: (data) {
          final history = data['history'] as List<dynamic>? ?? [];
          final pendingMissions = history.where((item) => item['status'] == 'pending').toList();
          final pendingMission = pendingMissions.isNotEmpty ? pendingMissions.first : null;
          final pastMissions = history.where((item) => item['status'] != 'pending').take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(statsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Today's Mission",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (pendingMission != null)
                  _buildPendingMissionCard(context, ref, pendingMission, data['owner'])
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No pending missions. Generate a new Trap PR!"),
                    ),
                  ),
                const SizedBox(height: 30),
                const Text(
                  "Past Missions",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...pastMissions.map((mission) {
                  final score = mission['score'];
                  final status = mission['status'];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        status == 'solved' ? Icons.check_circle : Icons.cancel,
                        color: status == 'solved' ? Colors.green : Colors.red,
                      ),
                      title: Text("PR #${mission['pr_number']}"),
                      subtitle: Text(mission['feature_proposal'] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(
                        score?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: score != null && score >= 80 ? Colors.green : Colors.red,
                        ),
                      ),
                      onTap: () {
                        if (mission['pr_url'] != null) {
                          launchUrl(Uri.parse(mission['pr_url']));
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingMissionCard(BuildContext context, WidgetRef ref, Map<String, dynamic> mission, String owner) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PR #${mission['pr_number']}",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mission['feature_proposal'] ?? 'New Feature',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.folder),
                const SizedBox(width: 8),
                Text(mission['repo'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                SizedBox(width: 8),
                Text("Auto-scoring enabled", style: TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text("Open GitHub"),
                onPressed: () {
                  if (mission['pr_url'] != null) {
                    launchUrl(Uri.parse(mission['pr_url']));
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Status"),
                onPressed: () {
                  ref.invalidate(statsProvider);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.grading),
                label: const Text("Score My Review (Manual)"),
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scoring review...')),
                    );
                    await ref.read(apiServiceProvider).scoreReview(
                          owner,
                          mission['repo'],
                          mission['pr_number'],
                        );
                    ref.invalidate(statsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scoring completed!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.smart_toy),
                label: const Text("Ask AI"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AskAIScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
