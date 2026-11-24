import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/i18n.dart';

/// Read-only viewer for the Terms & Conditions bundled with the app
/// (`assets/terms_and_conditions.html`).
///
/// Shown from the sign-up flow (so residents can read them before ticking
/// the acceptance checkbox) and from Settings › Account, any time later.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final WebViewController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // The document is styled for a white page (black text), so keep the
      // WebView background white even when the app is in dark theme.
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _errorMessage = error.description);
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/terms_and_conditions.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTexts.translate('set.terms.title'))),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      '${AppTexts.translate('terms.load_error')}\n$_errorMessage',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _controller.reload();
                      },
                      child: Text(AppTexts.translate('terms.retry')),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
