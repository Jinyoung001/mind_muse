import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 오개념 시뮬레이션을 전체화면으로 표시하는 페이지.
/// [html]: Gemini가 생성한 standalone HTML
/// [onStudentDoubt]: "이상한 것 같아..." 버튼 클릭 콜백
class AbsurdityFullscreenPage extends StatefulWidget {
  final String html;
  final VoidCallback onStudentDoubt;

  const AbsurdityFullscreenPage({
    super.key,
    required this.html,
    required this.onStudentDoubt,
  });

  @override
  State<AbsurdityFullscreenPage> createState() => _AbsurdityFullscreenPageState();
}

class _AbsurdityFullscreenPageState extends State<AbsurdityFullscreenPage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Stack(
          children: [
            // WebView (전체 화면)
            if (!_hasError)
              InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: widget.html,
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                ),
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                  disableContextMenu: true,
                  supportZoom: false,
                  javaScriptEnabled: true,
                ),
                onWebViewCreated: (controller) {
                  controller.addJavaScriptHandler(
                    handlerName: 'studentDoubt',
                    callback: (_) => _onDoubt(),
                  );
                },
                onReceivedError: (controller, request, error) {
                  if (mounted) setState(() => _hasError = true);
                },
              )
            else
              // 에러 시 대체 화면
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😅', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      '부조리한 세계를 표시하지 못했어요',
                      style: TextStyle(color: Color(0xFFeeeeee), fontSize: 16),
                    ),
                  ],
                ),
              ),

            // 하단 고정 버튼
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: ElevatedButton(
                  onPressed: _onDoubt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe94560),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    '나도 이상한 것 같아...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDoubt() {
    Navigator.of(context).pop();
    widget.onStudentDoubt();
  }
}
