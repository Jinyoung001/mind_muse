class AlienMessage {
  final String role; // 'user' | 'model'
  final String content;

  const AlienMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory AlienMessage.fromJson(Map<String, dynamic> json) => AlienMessage(
        role: json['role'] as String,
        content: json['content'] as String,
      );
}

class AnalyzeRequest {
  final String message;
  final String? imageBase64;
  final List<AlienMessage> history;

  const AnalyzeRequest({
    required this.message,
    this.imageBase64,
    required this.history,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        if (imageBase64 != null) 'image_base64': imageBase64,
        'history': history.map((e) => e.toJson()).toList(),
      };
}
