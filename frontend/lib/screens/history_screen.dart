import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final missions = [
      {
        "pr": "PR #24",
        "title": "Fix Login API",
        "score": "92",
        "date": "Today",
      },
      {
        "pr": "PR #23",
        "title": "Optimize Search",
        "score": "88",
        "date": "Yesterday",
      },
      {
        "pr": "PR #22",
        "title": "Payment Bug Fix",
        "score": "95",
        "date": "2 days ago",
      },
      {
        "pr": "PR #21",
        "title": "User Authentication",
        "score": "84",
        "date": "3 days ago",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("History"), centerTitle: true),
      body: ListView(
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

          ...missions.map((mission) {
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.description)),
                title: Text(mission["pr"]!),
                subtitle: Text("${mission["title"]}\n${mission["date"]}"),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mission["score"]!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text("Score"),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
