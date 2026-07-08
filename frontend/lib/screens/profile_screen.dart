import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              "Shun",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 5),

          const Center(
            child: Text(
              "Level 7 Reviewer",
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
                          "3325",
                          Colors.orange,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: statCard(
                          Icons.analytics,
                          "Accuracy",
                          "94%",
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
                          "32",
                          Colors.green,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: statCard(
                          Icons.local_fire_department,
                          "Streak",
                          "12",
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Skill Analysis",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          skillTile("SQL Injection", 95, Colors.green),

          skillTile("Authentication", 88, Colors.blue),

          skillTile("XSS", 82, Colors.orange),

          skillTile("Performance", 65, Colors.red),

          const SizedBox(height: 25),

          Card(
            color: Colors.green.shade50,
            child: const ListTile(
              leading: Icon(Icons.emoji_events, color: Colors.green),
              title: Text("Best Skill"),
              subtitle: Text("SQL Injection"),
            ),
          ),

          Card(
            color: Colors.red.shade50,
            child: const ListTile(
              leading: Icon(Icons.trending_down, color: Colors.red),
              title: Text("Needs Improvement"),
              subtitle: Text("Performance"),
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(IconData icon, String title, String value, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
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
