import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';

class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  final _messages = <_Message>[];

  @override
  void initState() {
    super.initState();

    // Use FirebaseAI to get the Gemini model
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
      systemInstruction: Content.text(
        "You are an emergency support assistant. Be calm, concise, and helpful. "
        "If a medical emergency is suspected, advise the user to call local emergency services immediately and then give first aid instructions. "
        "Ask short clarifying questions when needed.Give first aid instructions when appropriate.",
      ),
      generationConfig: GenerationConfig(maxOutputTokens: 300),
    );
    _chatSession = _model.startChat();

    // Initial UI messages (these are just UI, not system rules)
    final now = DateFormat('hh:mm a').format(DateTime.now());
    _messages.addAll([
      _Message(
        fromMe: false,
        text:
            "Hello, I'm here to help you. Take a deep breath. You're safe now.",
        time: now,
      ),
      _Message(
        fromMe: false,
        text: "Tell me what’s happening right now (in one sentence).",
        time: now,
      ),
    ]);
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        _Message(
          fromMe: true,
          text: userMessage,
          time: DateFormat('hh:mm a').format(DateTime.now()),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      setState(() {
        _isLoading = false;
        _messages.add(
          _Message(
            fromMe: false,
            text: response.text?.trim().isNotEmpty == true
                ? response.text!.trim()
                : "I’m having trouble responding right now. Please try again.",
            time: DateFormat('hh:mm a').format(DateTime.now()),
          ),
        );
      });
    } catch (e) {
      setState(() => _isLoading = false);

      // ✅ Use debugPrint (safer than print for long logs)
      debugPrint("GEMINI ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gemini error: $e")));
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Support')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F2FF),
            padding: const EdgeInsets.all(12),
            child: const Text("Take your time. We're here to listen and help."),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(message: _messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              children: [
                _chip('Not sure what I need'),
                _chip('Medical help'),
                _chip('Police'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.blue),
                  onPressed: () => _send(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => _send(label),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Message message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final align = message.fromMe
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bg = message.fromMe ? const Color(0xFF2962FF) : Colors.grey[200];
    final fg = message.fromMe ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.fromMe ? 16 : 0),
              bottomRight: Radius.circular(message.fromMe ? 0 : 16),
            ),
          ),
          child: Text(message.text, style: TextStyle(color: fg)),
        ),
        Text(
          message.time,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _Message {
  final bool fromMe;
  final String text;
  final String time;
  _Message({required this.fromMe, required this.text, required this.time});
}
