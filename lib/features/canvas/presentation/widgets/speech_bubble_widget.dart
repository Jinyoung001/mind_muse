import 'package:flutter/material.dart';

/// 화면의 특정 좌표 근처에 말풍선 형태로 AI 질문을 표시하는 위젯.
class SpeechBubbleWidget extends StatefulWidget {
  final String message;

  /// 말풍선의 꼬리가 가리킬 화면 좌표 (드로잉 중심)
  final Offset targetPosition;

  final VoidCallback onDismiss;

  const SpeechBubbleWidget({
    super.key,
    required this.message,
    required this.targetPosition,
    required this.onDismiss,
  });

  @override
  State<SpeechBubbleWidget> createState() => _SpeechBubbleWidgetState();
}

class _SpeechBubbleWidgetState extends State<SpeechBubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 말풍선 너비
    const bubbleWidth = 280.0;
    const bubbleHeight = 120.0;

    // 화면 경계를 벗어나지 않도록 말풍선 위치 조정
    double left = widget.targetPosition.dx - bubbleWidth / 2;
    double top = widget.targetPosition.dy - bubbleHeight - 20;

    // 왼쪽/오른쪽 경계 보정 (화면이 매우 좁은 경우 음수 방지)
    left = left.clamp(8.0, (screenSize.width - bubbleWidth - 8).clamp(8.0, double.infinity));

    // 위쪽 경계 보정 — 공간 없으면 아래에 표시, 하단 경계도 보정
    if (top < 60) top = widget.targetPosition.dy + 20;
    if (top + bubbleHeight > screenSize.height - 8) {
      top = screenSize.height - bubbleHeight - 8;
    }

    return Positioned(
      left: left,
      top: top,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            width: bubbleWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF4A90D9),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'MindMuse',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A90D9),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '탭하여 닫기',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
