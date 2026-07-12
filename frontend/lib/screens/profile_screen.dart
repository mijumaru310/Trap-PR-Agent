import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("プロフィール"), centerTitle: true),
      body: statsAsyncValue.when(
        data: (data) {
          final int totalGenerated = data['total_generated_prs'] ?? 0;
          final int solvedCount = data['solved_count'] ?? 0;
          final double accuracy = (data['accuracy'] ?? 0).toDouble();
          final double crAccuracy = (data['code_review_accuracy'] ?? 0).toDouble();
          final double secAccuracy = (data['security_accuracy'] ?? 0).toDouble();

          final int totalScore = data['total_score'] ?? 0;

          // Calculate XP as total_score * 10
          final int xp = totalScore * 10;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0052FF), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFFF8FAFC),
                        backgroundImage: settings.githubAvatarUrl != null
                            ? NetworkImage(settings.githubAvatarUrl!)
                            : null,
                        child: settings.githubAvatarUrl == null
                            ? const Icon(Icons.person_outline, size: 40, color: Color(0xFF0052FF))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['owner'] ?? 'User',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text("Senior Reviewer", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "全体統計",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: statCard(Icons.workspace_premium_outlined, "経験値", xp.toString(), const Color(0xFFF59E0B))),
                  const SizedBox(width: 12),
                  Expanded(child: statCard(Icons.analytics_outlined, "正答率", "$accuracy%", const Color(0xFF0052FF))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: statCard(Icons.task_alt_outlined, "解決済", solvedCount.toString(), const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: statCard(Icons.format_list_numbered_outlined, "合計PR", totalGenerated.toString(), const Color(0xFF8B5CF6))),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                "スキル分析",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              skillTile("コードレビュー", crAccuracy.toInt(), const Color(0xFF10B981)),
              skillTile("セキュリティ", secAccuracy.toInt(), const Color(0xFF0052FF)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget statCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  Widget skillTile(String title, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              Text("$value%", style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
