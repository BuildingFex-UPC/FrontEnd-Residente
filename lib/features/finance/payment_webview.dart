import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app browser for Mercado Pago Checkout Pro [url].
///
/// When the checkout completes or is dismissed by the user in Mercado Pago,
/// it redirects to the back_urls callback with payment outcome parameters
/// (`payment_id`, `collection_id`, `status`, `collection_status`, `external_reference`).
///
/// We intercept the return redirect, pop the route returning the parameters,
/// and allow the controller to confirm the payment directly against the backend.
class PaymentWebView extends StatefulWidget {
  const PaymentWebView({super.key, required this.url, required this.title});

  final String url;
  final String title;

  static const returnParamKeys = [
    'payment_id',
    'collection_id',
    'status',
    'collection_status',
    'external_reference',
    'payment_type',
    'merchant_order_id',
    'preference_id',
    'payment',
  ];

  static bool isReturnUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    final isFinancePath = path.contains('/app/resident/finance') ||
        path.contains('/finance') ||
        path.contains('/checkout/return');

    final hasOutcomeParams = uri.queryParameters.containsKey('collection_status') ||
        uri.queryParameters.containsKey('payment_id') ||
        (uri.queryParameters.containsKey('status') &&
            (uri.queryParameters.containsKey('collection_id') ||
                uri.queryParameters.containsKey('external_reference')));

    return isFinancePath || hasOutcomeParams;
  }

  static Map<String, String> extractParams(Uri uri) => {
        for (final key in returnParamKeys)
          if (uri.queryParameters[key] != null) key: uri.queryParameters[key]!,
      };

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _handled = false;
  int _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _errorMessage = error.description);
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && !_handled && PaymentWebView.isReturnUrl(uri)) {
              _handled = true;
              final params = PaymentWebView.extractParams(uri);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(params);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cerrar / Cancelar',
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar la pasarela de pagos:\n$_errorMessage',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _controller.reload();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_progress < 100 && _errorMessage == null)
            LinearProgressIndicator(value: _progress / 100.0),
        ],
      ),
    );
  }
}
