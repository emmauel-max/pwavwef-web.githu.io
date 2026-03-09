// lib/services/ai_service.dart
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Wrapper around Google Generative AI (Gemini) for task assistance
class AiService {
  // Pass GEMINI_API_KEY at build time via --dart-define:
  // flutter build appbundle --dart-define=GEMINI_API_KEY=your_key
  // flutter run --dart-define=GEMINI_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  GenerativeModel? _model;
  ChatSession? _chatSession;
  String _taskContext = '';

  GenerativeModel get _getModel {
    assert(_apiKey.isNotEmpty, 'GEMINI_API_KEY must be provided via --dart-define=GEMINI_API_KEY=<key>');
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are AZ AI, a friendly and knowledgeable study buddy for university '
        'students in Ghana using the AZ Learner app. Be concise, encouraging, '
        'and use simple language. Keep responses under 300 words unless the '
        'student asks for a detailed explanation. Use emojis sparingly.',
      ),
    );
    return _model!;
  }

  void startTaskChat({required String taskTitle, required String course}) {
    _taskContext = 'Assignment: "$taskTitle" for $course.';
    _chatSession = _getModel.startChat(history: [
      Content.text('Context: I need help with this assignment — $_taskContext Please be specific and helpful.'),
      Content.model([TextPart('Got it! I\'ll help you specifically with: $_taskContext What aspect do you need help with?')]),
    ]);
  }

  void startGeneralChat() {
    _taskContext = '';
    _chatSession = _getModel.startChat();
  }

  void clearChat() {
    _chatSession = null;
  }

  Future<String> sendMessage(String message) async {
    try {
      _chatSession ??= _getModel.startChat();
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'No response received.';
    } catch (e) {
      debugPrint('[AiService] Error: $e');
      return 'Oops! Something went wrong. Please try again. 😅';
    }
  }

  Future<String> sendOneOffMessage(String message) async {
    try {
      final response = await _getModel.generateContent([Content.text(message)]);
      return response.text ?? 'No response received.';
    } catch (e) {
      debugPrint('[AiService] Error: $e');
      return 'Oops! Something went wrong. Please try again. 😅';
    }
  }
}
