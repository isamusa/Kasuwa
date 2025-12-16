import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:kasuwa/theme/app_theme.dart';

class OpayPaymentScreen extends StatefulWidget {
  final String checkoutUrl;

  const OpayPaymentScreen({super.key, required this.checkoutUrl});

  @override
  _OpayPaymentScreenState createState() => _OpayPaymentScreenState();
}

class _OpayPaymentScreenState extends State<OpayPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You can use this to show a loading indicator
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            // This is the crucial part. We listen for the redirect back to our app.
            // The URL 'kasuwa://payment/success' must match the 'returnUrl' in your Laravel controller.
            if (request.url.startsWith('kasuwa://payment/success')) {
              print("Payment successful, navigating back.");
              // Pop the screen and return 'true' to signal success.
              Navigator.of(context).pop(true);
              return NavigationDecision
                  .prevent; // Stop the WebView from trying to load this URL
            }
            // You can add similar logic for failure or cancel URLs if needed.

            return NavigationDecision.navigate; // Allow all other navigation
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Pop the screen and return 'false' to signal cancellation.
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
