import 'package:flutter/material.dart';

class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}



class _EmergencyChatScreenState extends State<EmergencyChatScreen> {
  final _controller = TextEditingController();
  final _messages = <_Message>[
    _Message(
      fromMe: false,
      text: "Hello, I'm here to help you. Take a deep breath. You're safe now.",
      time: '01:06 AM',
    ),
    _Message(
      fromMe: false,
      text:
          'Can you briefly describe what kind of help you need? Take your time.',
      time: '01:06 AM',
    ),
  ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(fromMe: true, text: text.trim(), time: 'Now'));
    });
    _controller.clear();

    // later: send to backend / admin
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F2FF),
            padding: const EdgeInsets.all(12),
            child: const Text(
              "Take your time. We're here to listen and help.",
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final align = m.fromMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start;
                final bg = m.fromMe ? const Color(0xFF2962FF) : Colors.white;
                final fg = m.fromMe ? Colors.white : Colors.black87;

                return Column(
                  crossAxisAlignment: align,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m.text, style: TextStyle(color: fg)),
                    ),
                    Text(
                      m.time,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          ),

          // Quick suggestions
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

          // input
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message here...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
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
    return ActionChip(label: Text(label), onPressed: () => _send(label));
  }
}

class _Message {
  final bool fromMe;
  final String text;
  final String time;

  _Message({required this.fromMe, required this.text, required this.time});
}
