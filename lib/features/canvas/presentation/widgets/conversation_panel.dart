import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/alien_provider.dart';

/// 화면 하단에 고정되는 외계인 대화 패널.
/// 대화 히스토리 + 답변 입력 포함.
class ConversationPanel extends ConsumerStatefulWidget {
  const ConversationPanel({super.key});

  @override
  ConsumerState<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<ConversationPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alienProvider);

    // 새 메시지가 추가되면 스크롤 아래로
    ref.listen(alienProvider, (_, __) => _scrollToBottom());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.adb, // 외계인 느낌의 아이콘
                    color: Color(0xFF4A90D9), size: 18),
                const SizedBox(width: 6),
                const Text(
                  '외계인 조사관',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90D9),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (!state.isLoading)
                  TextButton(
                    onPressed: () {
                      ref.read(alienProvider.notifier).dismiss();
                    },
                    child: const Text('닫기',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 대화 히스토리
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (MediaQuery.of(context).size.height -
                          MediaQuery.of(context).viewInsets.bottom) *
                      0.35,
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.turns.length,
              itemBuilder: (context, index) {
                final turn = state.turns[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI 질문 (외계인 메시지)
                    if (turn.aiQuestion.isNotEmpty || state.isLoading && index == state.turns.length - 1)
                      _AiMessage(message: turn.aiQuestion),
                    
                    if (turn.userAnswer != null) ...[
                      const SizedBox(height: 6),
                      _UserMessage(message: turn.userAnswer!),
                    ],

                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),

          // 로딩 인디케이터
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('분석 중...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // 에러 메시지
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // 입력 영역
          if (!state.isLoading && state.turns.isNotEmpty)
            _InputArea(
              controller: _controller,
              onSubmit: (answer) {
                if (answer.trim().isEmpty) return;
                _controller.clear();
                ref.read(alienProvider.notifier).submitAnswer(answer.trim());
              },
            ),
        ],
      ),
    );
  }
}

class _AiMessage extends StatelessWidget {
  final String message;
  const _AiMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 12,
          backgroundColor: Color(0xFF4A90D9),
          child: Text('👽', style: TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.isEmpty ? '...' : message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMessage extends StatelessWidget {
  final String message;
  const _UserMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmit;

  const _InputArea({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // 답변 입력
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '답변을 입력하세요...',
                hintStyle:
                    const TextStyle(fontSize: 14, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              maxLines: null, // 여러 줄 입력 지원
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          IconButton(
            onPressed: () => onSubmit(controller.text),
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFF4A90D9),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE8F0FE),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }
}
