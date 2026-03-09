// lib/widgets/task_ai_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/assignment.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

class TaskAiSheet extends StatefulWidget {
  final Assignment task;
  const TaskAiSheet({super.key, required this.task});

  @override
  State<TaskAiSheet> createState() => _TaskAiSheetState();
}

class _TaskAiSheetState extends State<TaskAiSheet> {
  final AiService _ai = AiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ai.startTaskChat(taskTitle: widget.task.title, course: widget.task.course);
    _messages.add(_Message(
      text: "Hey! I'm here to help with your assignment: **${widget.task.title}** for ${widget.task.course}. What would you like help with? 🤖✨",
      isAi: true,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? prefill]) async {
    final text = (prefill ?? _inputCtrl.text).trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(_Message(text: text, isAi: false));
      _loading = true;
    });
    _scrollToBottom();
    final reply = await _ai.sendMessage(text);
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(text: reply, isAi: true));
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            // Handle
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.violet, const Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Task Helper', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                        Text(widget.task.title, style: TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textMuted), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),

            const Divider(height: 16),

            // Quick chips
            SizedBox(
              height: 40,
              child: ListView(
                controller: scrollCtrl,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('📋 Break it down', () => _send('Break down this assignment into steps: ${widget.task.title}')),
                  _chip('💡 Key points', () => _send('Give me key points I need to cover for: ${widget.task.title}')),
                  _chip('📚 Resources', () => _send('Suggest resources and references for: ${widget.task.title}')),
                  _chip('⏱️ Time estimate', () => _send('How long would this realistically take to complete: ${widget.task.title}')),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_loading && i == _messages.length) return _TypingBubble();
                  final msg = _messages[i];
                  return _MessageBubble(message: msg)
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.1, end: 0);
                },
              ),
            ),

            // Input
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask about this task...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : () => _send(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.violet, const Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 12)],
                      ),
                      child: _loading
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.violet.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.violet.withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.violet, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isAi;
  const _Message({required this.text, required this.isAi});
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isAi) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.violet, const Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isAi ? AppColors.card : AppColors.violet,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isAi ? 4 : 18),
                  bottomRight: Radius.circular(message.isAi ? 18 : 4),
                ),
                border: message.isAi ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(color: message.isAi ? AppColors.textPrimary : Colors.white, fontSize: 14, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, top: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.violet, const Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 600.ms, delay: (i * 200).ms).then().fadeIn(duration: 600.ms)),
            ),
          ),
        ],
      ),
    );
  }
}
