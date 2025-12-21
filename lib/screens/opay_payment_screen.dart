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
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF)) // Set white background
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading state
            if (progress < 100) {
              setState(() => _isLoading = true);
            } else {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            // Log error but don't crash
            print("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print("Navigating to: $url"); // Debug log

            // 1. Intercept Success URL (Deep Link)
            if (url.startsWith('kasuwa://payment/success')) {
              print("Payment Successful (Deep Link Detected)");
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }

            // 2. Intercept Cancel URL
            if (url.startsWith('kasuwa://payment/cancelled')) {
              print("Payment Cancelled");
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            // 3. Fallback: Sometimes gateways redirect to a standard HTTP URL before the app link
            // If you have a web success page (e.g., your-backend.com/payment/success), add it here.

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Show confirmation dialog before closing to prevent accidental cancellations
            showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                      title: const Text("Cancel Payment?"),
                      content: const Text(
                          "Are you sure you want to cancel this transaction?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(), // Stay
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop(); // Close dialog
                            Navigator.of(context).pop(false); // Close screen
                          },
                          child: const Text("Yes, Cancel",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ));
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white, // Cover the WebView while loading
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text("Connecting to OPay...",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
