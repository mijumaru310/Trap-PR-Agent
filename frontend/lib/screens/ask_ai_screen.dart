import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';

class AskAIScreen extends ConsumerStatefulWidget {
  final String owner;
  final String repo;
  final int prNumber;

  const AskAIScreen({
    super.key,
    required this.owner,
    required this.repo,
    required this.prNumber,
  });

  @override
  ConsumerState<AskAIScreen> createState() => _AskAIScreenState();
}

class _AskAIScreenState extends ConsumerState<AskAIScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, String>> messages = [];
  int? _remainingCount;

  @override
  void initState() {
    super.initState();
    messages.add({
      "role": "ai",
      "text": "こんにちは！Trap Assistantです。\n現在の罠PR（#${widget.prNumber}）について、何かヒントや質問があればどうぞ！\n(※質問は1つのPRにつき3回まで可能です)",
    });
    
    // Future.microtask is used to call ref.read safely after initState
    Future.microtask(() => _loadHistory());
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getAskAIHistory(
        widget.owner,
        widget.repo,
        widget.prNumber,
      );
      if (mounted) {
        setState(() {
          _remainingCount = response['remaining_count'] as int?;
          final history = response['messages'] as List<dynamic>? ?? [];
          for (var msg in history) {
            messages.add({
              "role": msg["role"] as String,
              "text": msg["text"] as String,
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('履歴の取得に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  bool _isLoading = false;

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final question = _controller.text;
    _controller.clear();

    setState(() {
      messages.add({"role": "user", "text": question});
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.askAI(
        widget.owner,
        widget.repo,
        widget.prNumber,
        question,
      );

      if (mounted) {
        setState(() {
          _remainingCount = response['remaining_count'] as int?;
          messages.add({
            "role": "ai",
            "text": response['answer'] ?? '回答を取得できませんでした。',
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({
            "role": "ai",
            "text": "エラーが発生しました: $e",
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget buildMessage(Map<String, String> message) {
    final isUser = message["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0052FF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: isUser ? [BoxShadow(color: const Color(0xFF0052FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(
          message["text"]!,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Column(
          children: [
            const Text("AIに質問する", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (_remainingCount != null)
              Text("残り $_remainingCount 回", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading && (_remainingCount == null || _remainingCount! > 0),
                      decoration: InputDecoration(
                        hintText: "罠のヒントを教えて...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : const Color(0xFF0052FF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : sendMessage,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
