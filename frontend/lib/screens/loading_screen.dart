import 'dart:async';

import 'package:flutter/material.dart';

import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const Icon(Icons.smart_toy, size: 90, color: Colors.blue),

                const SizedBox(height: 30),

                const Text(
                  "Trap-PR Agent",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                const CircularProgressIndicator(),

                const SizedBox(height: 30),

                const Text(
                  "Analyzing your GitHub review...",
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Fetching review comments...",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Evaluating with Gemini...",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
