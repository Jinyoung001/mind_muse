import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gemma_provider.dart';

/// WebView 기반 부조리 시뮬레이션 카드 위젯.
/// Gemini가 생성한 standalone HTML을 300px 높이의 카드로 표시한다.
/// "이상한 것 같아..." 버튼 클릭 시 onStudentDoubt()를 호출한다.
class AbsurdityWebviewBubble extends ConsumerStatefulWidget {
  final String html;

  const AbsurdityWebviewBubble({super.key, required this.html});

  @override
  ConsumerState<AbsurdityWebviewBubble> createState() =>
      _AbsurdityWebviewBubbleState();
}

class _AbsurdityWebviewBubbleState
    extends ConsumerState<AbsurdityWebviewBubble> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorCard(
        onDoubt: () =>
            ref.read(gemmaProvider.notifier).onStudentDoubt(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: 300,
          child: InAppWebView(
            initialData: InAppWebViewInitialData(
              data: widget.html,
              mimeType: 'text/html',
              encoding: 'utf-8',
            ),
            initialSettings: InAppWebViewSettings(
              transparentBackground: false,
              disableContextMenu: true,
              supportZoom: false,
              javaScriptEnabled: true,
            ),
            onWebViewCreated: (controller) {
              controller.addJavaScriptHandler(
                handlerName: 'studentDoubt',
                callback: (_) {
                  ref.read(gemmaProvider.notifier).onStudentDoubt();
                },
              );
            },
            onReceivedError: (controller, request, error) {
              if (mounted) {
                setState(() => _hasError = true);
              }
            },
          ),
        ),
      ),
    );
  }
}

/// 부조리 엔진 생성 중 로딩 카드
class AbsurdityLoadingCard extends StatelessWidget {
  const AbsurdityLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1a1a2e),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFe94560),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '부조리한 세계를 만드는 중...',
                style: TextStyle(
                  color: Color(0xFFeeeeee),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WebView 렌더링 에러 시 표시할 카드
class _ErrorCard extends StatelessWidget {
  final VoidCallback onDoubt;

  const _ErrorCard({required this.onDoubt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1a1a2e),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '😅',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              const Text(
                '부조리한 세계를 표시하지 못했어요',
                style: TextStyle(color: Color(0xFFeeeeee), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onDoubt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe94560),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('나도 이상한 것 같아...'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
