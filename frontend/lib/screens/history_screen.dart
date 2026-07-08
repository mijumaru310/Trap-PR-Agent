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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              const Text(
                "Review History",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your previous review missions.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
              const SizedBox(height: 24),
              ...pastMissions.map((mission) {
                final score = mission["score"];
                final status = mission["status"];
                final isSolved = status == 'solved';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFF64748B)),
                    ),
                    title: Text("PR #${mission["pr_number"]}", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mission["feature_proposal"] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSolved ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toString().toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        score?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: score != null && score >= 80 ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                        ),
                      ),
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
