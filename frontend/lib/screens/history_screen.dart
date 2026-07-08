import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("History"), centerTitle: true),
      body: statsAsyncValue.when(
        data: (data) {
          final history = data['history'] as List<dynamic>? ?? [];
          final pastMissions = history.where((item) => item['status'] != 'pending').toList();

          if (pastMissions.isEmpty) {
            return const Center(child: Text("No review history yet."));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Review History",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your previous review missions.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ...pastMissions.map((mission) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.description)),
                    title: Text("PR #${mission["pr_number"]}"),
                    subtitle: Text("${mission["feature_proposal"]}\n${mission["status"]}"),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mission["score"]?.toString() ?? "N/A",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: mission["score"] != null && mission["score"] >= 80 ? Colors.green : Colors.red,
                          ),
                        ),
                        const Text("Score"),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
