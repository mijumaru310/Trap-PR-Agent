import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = result['is_correct'] ?? false;
    final int score = result['score'] ?? 0;
    final String feedback = result['feedback'] ?? 'No feedback provided.';

    return Scaffold(
      appBar: AppBar(title: const Text("Review Result"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          Icon(
            isCorrect ? Icons.emoji_events : Icons.cancel,
            size: 90,
            color: isCorrect ? Colors.amber : Colors.red,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              score.toString(),
              style: TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.blue : Colors.redAccent,
              ),
            ),
          ),
          Center(
            child: Text(
              isCorrect ? "Excellent!" : "Needs Improvement",
              style: TextStyle(
                fontSize: 22,
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gemini Feedback",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    feedback,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text("Back to Home", style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
