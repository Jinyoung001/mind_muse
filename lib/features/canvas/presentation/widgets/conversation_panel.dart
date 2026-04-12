import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gemma_provider.dart';
import 'absurdity_webview_bubble.dart';

/// 화면 하단에 고정되는 소크라테스 대화 패널.
/// 대화 히스토리 + 답변 입력 + 힌트 버튼을 포함한다.
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
    final state = ref.watch(gemmaProvider);

    // 새 메시지가 추가되면 스크롤 아래로
    ref.listen(gemmaProvider, (_, __) => _scrollToBottom());

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
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFF4A90D9), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'MindMuse 튜터',
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
                      ref.read(gemmaProvider.notifier).dismiss();
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
              maxHeight: (state.isGeneratingAbsurdity ||
                      state.absurdityHtml != null)
                  ? (MediaQuery.of(context).size.height -
                          MediaQuery.of(context).viewInsets.bottom) *
                      0.65
                  : (MediaQuery.of(context).size.height -
                          MediaQuery.of(context).viewInsets.bottom) *
                      0.25,
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.turns.length,
              itemBuilder: (context, index) {
                final turn = state.turns[index];
                final isLastTurn = index == state.turns.length - 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI 질문
                    _AiMessage(message: turn.aiQuestion),
                    const SizedBox(height: 6),

                    // 공개된 힌트
                    for (int h = 0; h < turn.revealedHints; h++)
                      if (h < turn.hints.length)
                        _HintMessage(
                            hint: '힌트 ${h + 1}: ${turn.hints[h]}'),

                    // 사용자 답변
                    if (turn.userAnswer != null) ...[
                      const SizedBox(height: 6),
                      _UserMessage(message: turn.userAnswer!),
                    ],

                    // 마지막 턴: Absurdity Engine 로딩 카드
                    if (isLastTurn && state.isGeneratingAbsurdity) ...[
                      const SizedBox(height: 8),
                      const AbsurdityLoadingCard(),
                    ],

                    // 마지막 턴: Absurdity WebView 버블
                    if (isLastTurn && state.absurdityHtml != null) ...[
                      const SizedBox(height: 8),
                      AbsurdityWebviewBubble(html: state.absurdityHtml!),
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
                  Text('생각 중...', style: TextStyle(color: Colors.grey)),
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

          // 입력 영역 (완료·로딩·Absurdity 표시 중에는 숨김)
          if (!state.isFinished &&
              !state.isLoading &&
              !state.isGeneratingAbsurdity &&
              state.absurdityHtml == null &&
              state.turns.isNotEmpty)
            _InputArea(
              controller: _controller,
              canHint: () {
                final turn = state.currentTurn;
                if (turn == null) return false;
                return turn.revealedHints < turn.hints.length;
              },
              onHint: () => ref.read(gemmaProvider.notifier).revealNextHint(),
              onSubmit: (answer) {
                if (answer.trim().isEmpty) return;
                _controller.clear();
                ref.read(gemmaProvider.notifier).submitAnswer(answer.trim());
              },
            ),

          // 완료 메시지
          if (state.isFinished)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => ref.read(gemmaProvider.notifier).dismiss(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('학습 완료!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white,
                ),
              ),
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
          child: Icon(Icons.lightbulb_outline, size: 14, color: Colors.white),
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
              message,
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

class _HintMessage extends StatelessWidget {
  final String hint;
  const _HintMessage({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 32, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hint,
        style: TextStyle(
            fontSize: 12, color: Colors.amber.shade900, height: 1.4),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool Function() canHint;
  final VoidCallback onHint;
  final void Function(String) onSubmit;

  const _InputArea({
    required this.controller,
    required this.canHint,
    required this.onHint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // 힌트 버튼
          OutlinedButton.icon(
            onPressed: canHint() ? onHint : null,
            icon: const Icon(Icons.lightbulb, size: 16),
            label: const Text('힌트', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: BorderSide(color: Colors.amber.shade400),
              foregroundColor: Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 8),
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
              maxLines: 1,
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
