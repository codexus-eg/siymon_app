import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SiymonApp());
}

class SiymonApp extends StatelessWidget {
  const SiymonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'siymon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF5722), // لون المتجر بتاعك
      ),
      home: const MainWebView(),
    );
  }
}

class MainWebView extends StatefulWidget {
  const MainWebView({super.key});

  @override
  State<MainWebView> createState() => _MainWebViewState();
}

class _MainWebViewState extends State<MainWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  bool _isLoading = true;

  // إعدادات المتصفح الأساسية والنظيفة
  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    geolocationEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (webViewController != null && await webViewController!.canGoBack()) {
          // الرجوع الطبيعي بين صفحات الموقع
          await webViewController!.goBack();
        } else {
          // يمكن هنا مستقبلاً إضافة رسالة "هل تود الخروج من التطبيق؟"
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(
                  url: WebUri('https://siymon7.com/'),
                ),
                initialSettings: settings,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                  });
                },
                onLoadStop: (controller, url) {
                  setState(() {
                    _isLoading = false;
                  });
                },
                // الإذن السحري: بيطلب الـ GPS فقط لما العميل يضغط على جلب العنوان
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  var status = await Permission.locationWhenInUse.request();
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: status.isGranted,
                    retain: true,
                  );
                },
                // التحكم في الروابط الخارجية (واتساب، مكالمات)
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (![
                    "http",
                    "https",
                    "file",
                    "chrome",
                    "data",
                    "javascript",
                    "about",
                  ].contains(uri.scheme)) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
