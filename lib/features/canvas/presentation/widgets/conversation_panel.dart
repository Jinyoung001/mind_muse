import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/alien_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'alien_character.dart';
import 'neon_container.dart';

/// 화면 우측에 고정되는 외계인 대화 패널 (워크벤치 레이아웃).
/// 대화 히스토리 + 답변 입력 포함.
class ConversationPanel extends ConsumerStatefulWidget {
  const ConversationPanel({super.key});

  @override
  ConsumerState<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<ConversationPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isAnimating = false;

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
    ref.listen(alienProvider, (prev, next) {
      if (next.turns.length > (prev?.turns.length ?? 0)) {
        _scrollToBottom();
        // 마지막 메시지가 AI 것이라면 애니메이션 시작
        if (next.turns.isNotEmpty && next.turns.last.aiQuestion.isNotEmpty) {
          setState(() => _isAnimating = true);
        }
      }
    });

    return NeonContainer(
      padding: EdgeInsets.zero,
      neonColor: AppTheme.neonGreen,
      borderRadius: 0, // 사이드 패널이므로 모서리 둥글기 제거 또는 조정
      blurRadius: 20,
      backgroundColor: AppTheme.spaceBlack.withOpacity(0.85),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMD,
                AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceSM),
            decoration: const BoxDecoration(
              color: AppTheme.panelBlack,
            ),
            child: Row(
              children: [
                const AlienCharacter(size: 40),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '외계인 조사관',
                        style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonGreen,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'ALIEN-TR-2024 / SECTOR-7',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!state.isLoading)
                  IconButton(
                    onPressed: () {
                      ref.read(alienProvider.notifier).dismiss();
                    },
                    icon:
                        const Icon(Icons.close, color: Colors.white54, size: 20),
                    tooltip: '통신 종료',
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.neonGreen.withOpacity(0.2)),

          // 대화 히스토리
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceMD),
              itemCount: state.turns.length,
              itemBuilder: (context, index) {
                final turn = state.turns[index];
                final isLast = index == state.turns.length - 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI 질문 (외계인 메시지)
                    if (turn.aiQuestion.isNotEmpty ||
                        (state.isLoading && isLast))
                      _AiMessage(
                        message: turn.aiQuestion,
                        animate: isLast && _isAnimating,
                        onFinished: () {
                          if (mounted) {
                            setState(() => _isAnimating = false);
                            _scrollToBottom();
                          }
                        },
                      ),

                    if (turn.userAnswer != null) ...[
                      const SizedBox(height: AppTheme.spaceMD),
                      _UserMessage(message: turn.userAnswer!),
                    ],

                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                );
              },
            ),
          ),

          // 로딩 인디케이터
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
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
          if (state.turns.isNotEmpty)
            _InputArea(
              controller: _controller,
              isEnabled: !state.isLoading && !_isAnimating,
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
  final bool animate;
  final VoidCallback? onFinished;

  const _AiMessage({
    required this.message,
    this.animate = false,
    this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    const messageStyle = TextStyle(
      fontSize: 15,
      height: 1.6,
      color: Colors.white,
      letterSpacing: 0.0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.neonGreen.withOpacity(0.5), width: 1),
          ),
          child: const AlienCharacter(size: 28),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.spaceBlack.withOpacity(0.85),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppTheme.spaceMD),
                  bottomLeft: Radius.circular(AppTheme.spaceMD),
                  bottomRight: Radius.circular(AppTheme.spaceMD),
                ),
                border: Border.all(
                  color: AppTheme.neonGreen.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonGreen.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: animate
                  ? DefaultTextStyle(
                      style: messageStyle,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            message,
                            speed: const Duration(milliseconds: 40),
                          ),
                        ],
                        totalRepeatCount: 1,
                        onFinished: onFinished,
                        displayFullTextOnTap: true,
                      ),
                    )
                  : Text(
                      message.isEmpty ? '...' : message,
                      style: messageStyle,
                      softWrap: true,
                      textAlign: TextAlign.start,
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
        const SizedBox(width: AppTheme.spaceXL),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: const BoxDecoration(
              color: AppTheme.neonGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.spaceMD),
                bottomLeft: Radius.circular(AppTheme.spaceMD),
                bottomRight: Radius.circular(AppTheme.spaceMD),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.spaceBlack,
                fontWeight: FontWeight.w600,
                height: 1.4,
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
  final bool isEnabled;
  final void Function(String) onSubmit;

  const _InputArea({
    required this.controller,
    required this.isEnabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMD, AppTheme.spaceSM, AppTheme.spaceMD, AppTheme.spaceLG),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Row(
          children: [
            // 답변 입력
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEnabled,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: AppTheme.neonGreen,
                decoration: InputDecoration(
                  hintText: isEnabled ? '오해를 정정해주세요...' : '분석 대기 중...',
                  hintStyle: TextStyle(
                      fontSize: 13, color: Colors.white.withOpacity(0.3)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.neonGreen, width: 1.5),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: isEnabled ? onSubmit : null,
                maxLines: null,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            // 전송 버튼
            IconButton(
              onPressed: isEnabled ? () => onSubmit(controller.text) : null,
              icon: const Icon(Icons.send_rounded),
              color: AppTheme.spaceBlack,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                disabledBackgroundColor: AppTheme.neonGreen.withOpacity(0.3),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

