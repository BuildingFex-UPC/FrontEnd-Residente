import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app browser for the Mercado Pago Checkout Pro [url].
///
/// Mercado Pago appends the outcome as query params (`payment`, `status`,
/// `payment_id`, `collection_id`). When any of those appear we stop navigating
/// and pop the route with those params so the caller can confirm the payment.
class PaymentWebView extends StatefulWidget {
  const PaymentWebView({super.key, required this.url, required this.title});

  final String url;
  final String title;

  static const _paramKeys = ['payment', 'status', 'payment_id', 'collection_id'];

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && !_handled && _hasPaymentParams(uri)) {
              _handled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(_extractParams(uri));
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  static bool _hasPaymentParams(Uri uri) =>
      PaymentWebView._paramKeys.any(uri.queryParameters.containsKey);

  static Map<String, String> _extractParams(Uri uri) => {
        for (final key in PaymentWebView._paramKeys)
          if (uri.queryParameters[key] != null) key: uri.queryParameters[key]!,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
