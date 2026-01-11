import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final chatBannerColor = isDark
        ? Colors.blueGrey[900]
        : const Color(0xFFE8F2FF);
    final chatBannerText = isDark ? Colors.white70 : Colors.black87;
    final inputBg = isDark ? Colors.grey[900] : Colors.white;
    final inputBorder = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final chipBg = (isDark ? Colors.blueGrey[800] : Colors.grey[200])!;
    final chipText = (isDark ? Colors.white : Colors.black87);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Emergency Support'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? bgColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: chatBannerColor,
            padding: const EdgeInsets.all(12),
            child: Text(
              "Take your time. We're here to listen and help.",
              style: TextStyle(color: chatBannerText),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(message: _messages[index], isDark: isDark),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: isDark ? Colors.blue[200] : null,
                backgroundColor: isDark ? Colors.blueGrey[900] : null,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 6,
              children: [
                _chip('Not sure what I need', chipBg, chipText),
                _chip('Medical help', chipBg, chipText),
                _chip('Police', chipBg, chipText),
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
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onSubmitted: _send,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => _send(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return ActionChip(
      backgroundColor: bg,
      label: Text(label, style: TextStyle(fontSize: 12, color: fg)),
      onPressed: () => _send(label),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Message message;
  final bool isDark;
  const _ChatBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final align = message.fromMe
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bg = message.fromMe
        ? (isDark ? const Color(0xFF1976D2) : const Color(0xFF2962FF))
        : (isDark ? Colors.blueGrey[800] : Colors.grey[200]);
    final fg = message.fromMe
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);
    final timeColor = isDark ? Colors.grey[400] : Colors.grey;

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
        Text(message.time, style: TextStyle(fontSize: 10, color: timeColor)),
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
