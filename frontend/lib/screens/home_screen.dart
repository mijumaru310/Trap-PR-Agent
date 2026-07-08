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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                const Text(
                  "Today's Mission",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                if (pendingMission != null)
                  _buildPendingMissionCard(context, ref, pendingMission, data['owner'])
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 16),
                          Text(
                            "No pending missions",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap the + button to generate a new Trap PR!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                const Text(
                  "Past Missions",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                ...pastMissions.map((mission) {
                  final score = mission['score'];
                  final status = mission['status'];
                  final isSolved = status == 'solved';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSolved ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSolved ? Icons.check_circle_outline : Icons.error_outline,
                          color: isSolved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                      title: Text("PR #${mission['pr_number']}", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(mission['feature_proposal'] ?? 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B))),
                      ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "PR #${mission['pr_number']}",
                style: const TextStyle(
                  color: Color(0xFF0052FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mission['feature_proposal'] ?? 'New Feature',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mission['repo'] ?? 'N/A',
                          style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 12),
                      Text("Auto-scoring enabled", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (mission['pr_url'] != null) {
                        launchUrl(Uri.parse(mission['pr_url']));
                      }
                    },
                    child: const Text("GitHub"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                    child: const Text("Score Review"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text("Ask AI Assistant"),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF).withOpacity(0.02),
                  side: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
                  foregroundColor: const Color(0xFF0052FF),
                ),
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
