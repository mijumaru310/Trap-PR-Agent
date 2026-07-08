import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loading_screen.dart';
import 'ask_ai_screen.dart';
import 'result_screen.dart';
import 'generate_trap_dialog.dart';
import '../providers/stats_provider.dart';
import '../providers/api_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Trap-PR Agent"), centerTitle: true),
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
          final pastMissions = history.where((item) => item['status'] != 'pending').take(3).toList();

          return ListView(
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
              ...pastMissions.map((mission) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text("PR #${mission['pr_number']}"),
                  subtitle: Text(mission['feature_proposal'] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(mission['score']?.toString() ?? '-'),
                ),
              )).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                Icon(Icons.workspace_premium),
                SizedBox(width: 8),
                Text("Reward : +120 XP"),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text("Open GitHub"),
                onPressed: () {
                  // TODO: launchUrl(Uri.parse(mission['pr_url']))
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified),
                label: const Text("Score My Review"),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoadingScreen()),
                  );
                  
                  try {
                    final api = ref.read(apiServiceProvider);
                    final result = await api.scoreReview(owner, mission['repo'], mission['pr_number']);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // pop loading
                      ref.invalidate(statsProvider);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // pop loading
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
