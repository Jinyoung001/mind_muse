import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/alien_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
        color: AppTheme.spaceBlack.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppTheme.neonGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withOpacity(0.1),
            blurRadius: 20,
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
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.rocket_launch, 
                    color: AppTheme.neonGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '외계인 통신관',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonGreen,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (!state.isLoading)
                  TextButton(
                    onPressed: () {
                      ref.read(alienProvider.notifier).dismiss();
                    },
                    child: Text('통신 종료',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5), 
                          fontSize: 12,
                        )),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.neonGreen.withOpacity(0.2)),

          // 대화 히스토리
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (MediaQuery.of(context).size.height -
                          MediaQuery.of(context).viewInsets.bottom) *
                      0.4,
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.turns.length,
              itemBuilder: (context, index) {
                final turn = state.turns[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI 질문 (외계인 메시지)
                    if (turn.aiQuestion.isNotEmpty || (state.isLoading && index == state.turns.length - 1))
                      _AiMessage(message: turn.aiQuestion),
                    
                    if (turn.userAnswer != null) ...[
                      const SizedBox(height: 12),
                      _UserMessage(message: turn.userAnswer!),
                    ],

                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),

          // 로딩 인디케이터
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('외계 신호 분석 중...', 
                    style: TextStyle(color: AppTheme.neonGreen, fontSize: 13)),
                ],
              ),
            ),

          // 에러 메시지
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '통신 오류: ${state.error!}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.neonGreen, width: 1),
          ),
          child: const Text('👽', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.neonGreen.withOpacity(0.2),
              ),
            ),
            child: Text(
              message.isEmpty ? '...' : message,
              style: const TextStyle(
                fontSize: 15, 
                height: 1.5, 
                color: Colors.white,
              ),
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
        const SizedBox(width: 40),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15, 
                color: AppTheme.spaceBlack, 
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          // 답변 입력
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              cursorColor: AppTheme.neonGreen,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                hintStyle:
                    TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.3)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppTheme.neonGreen, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 10),
          // 전송 버튼
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonGreen,
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => onSubmit(controller.text),
              icon: const Icon(Icons.send_rounded),
              color: AppTheme.spaceBlack,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
