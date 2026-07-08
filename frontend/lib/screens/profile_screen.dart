import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: statsAsyncValue.when(
        data: (data) {
          final int totalGenerated = data['total_generated_prs'] ?? 0;
          final int solvedCount = data['solved_count'] ?? 0;
          final double accuracy = (data['accuracy'] ?? 0).toDouble();

          // Calculate some arbitrary XP for fun based on solved count
          final int xp = solvedCount * 120;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  data['owner'] ?? 'User',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              const Center(
                child: Text(
                  "Reviewer",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 25),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Overall Statistics",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: statCard(
                              Icons.workspace_premium,
                              "XP",
                              xp.toString(),
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: statCard(
                              Icons.analytics,
                              "Accuracy",
                              "$accuracy%",
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: statCard(
                              Icons.task_alt,
                              "Solved",
                              solvedCount.toString(),
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: statCard(
                              Icons.format_list_numbered,
                              "Total PRs",
                              totalGenerated.toString(),
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Skill analysis is hardcoded for now, could be dynamic later based on tags
              const Text(
                "Skill Analysis",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              skillTile("Code Review", accuracy.toInt(), Colors.green),
              skillTile("Security", (accuracy * 0.9).toInt(), Colors.blue),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget statCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget skillTile(String title, int value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$title   $value%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
