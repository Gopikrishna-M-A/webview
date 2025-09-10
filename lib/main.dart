import 'dart:async';
// Required to use AppExitResponse for Flutter 3.10 or later
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_linux_webview/flutter_linux_webview.dart';

void main() {
  // ensureInitialized() is required if the plugin is initialized before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Run `LinuxWebViewPlugin.initialize()` first before creating a WebView.
  LinuxWebViewPlugin.initialize(
    options: <String, String?>{
      'user-agent': 'Flutter Linux WebView App',
      'remote-debugging-port': '8888',
      'autoplay-policy': 'no-user-gesture-required',
    },
  );

  // Configure [WebView] to use the [LinuxWebView].
  WebView.platform = LinuxWebView();

  runApp(const MaterialApp(home: WebViewExample()));
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({Key? key}) : super(key: key);

  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample>
    with WidgetsBindingObserver {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  /// Prior to Flutter 3.10, comment out the following code since
  /// [WidgetsBindingObserver.didRequestAppExit] does not exist.
  // ===== begin: For Flutter 3.10 or later =====
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await LinuxWebViewPlugin.terminate();
    return AppExitResponse.exit;
  }
  // ===== end: For Flutter 3.10 or later =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google WebView'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: WebView(
        initialUrl: 'https://google.com',
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
        javascriptMode: JavascriptMode.unrestricted,
        onPageStarted: (String url) {
          print('Page started loading: $url');
        },
        onPageFinished: (String url) {
          print('Page finished loading: $url');
        },
        onWebResourceError: (WebResourceError error) {
          print('Web resource error: ${error.description}');
        },
      ),
      floatingActionButton: refreshButton(),
    );
  }

  Widget refreshButton() {
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
            if (controller.hasData) {
              return FloatingActionButton(
                onPressed: () async {
                  await controller.data!.reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Page refreshed!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(Icons.refresh),
                tooltip: 'Refresh Page',
              );
            }
            return Container();
          },
    );
  }
}
