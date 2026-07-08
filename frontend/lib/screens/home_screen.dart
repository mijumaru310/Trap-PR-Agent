import 'package:flutter/material.dart';

import 'loading_screen.dart';
import 'ask_ai_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trap-PR Agent"), centerTitle: true),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          const Text(
            "Today's Mission",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "PR #24",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Fix Login API",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  const Row(
                    children: [
                      Icon(Icons.folder),
                      SizedBox(width: 8),
                      Text("sample-api"),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Row(
                    children: [
                      Icon(Icons.star),
                      SizedBox(width: 8),
                      Text("Difficulty : ★★★★☆"),
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
                        // 後でGitHubを開く
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.verified),

                      label: const Text("Score My Review"),

                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoadingScreen(),
                          ),
                        );
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
                          MaterialPageRoute(
                            builder: (_) => const AskAIScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Past Missions",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text("PR #23"),
              subtitle: const Text("Optimize Search API"),
              trailing: const Text("95"),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text("PR #22"),
              subtitle: const Text("Payment Bug Fix"),
              trailing: const Text("90"),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text("PR #21"),
              subtitle: const Text("User Authentication"),
              trailing: const Text("87"),
            ),
          ),
        ],
      ),
    );
  }
}
