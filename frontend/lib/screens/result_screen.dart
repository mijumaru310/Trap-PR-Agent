import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review Result"), centerTitle: true),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          const SizedBox(height: 10),

          const Icon(Icons.emoji_events, size: 90, color: Colors.amber),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "92",
              style: TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),

          const Center(
            child: Text(
              "Excellent!",
              style: TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: const [
                  Text(
                    "Detected Issues",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 15),

                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("SQL Injection"),
                  ),

                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Hardcoded Secret"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: const [
                  Text(
                    "Missed Issues",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 15),

                  ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text("Input Validation"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            color: Colors.blue.shade50,

            child: const Padding(
              padding: EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Gemini Feedback",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 15),

                  Text(
                    "Great review!\n\n"
                    "You successfully identified the SQL Injection vulnerability."
                    "\n\n"
                    "To improve your review, also mention the lack of input validation and recommend using Prepared Statements.",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          Card(
            color: Colors.orange.shade100,

            child: const Padding(
              padding: EdgeInsets.all(20),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.workspace_premium, color: Colors.orange, size: 35),

                  SizedBox(width: 10),

                  Text(
                    "+120 XP",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
