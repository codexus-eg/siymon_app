import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:collection';

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
        primaryColor: const Color(0xFFFF5722),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5722)),
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

  // إعدادات المتصفح السريعة والمغلقة
  InAppWebViewSettings settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    geolocationEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    allowFileAccess: true,
    allowContentAccess: true,
    transparentBackground: true,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    supportZoom: false,
    builtInZoomControls: false,
    displayZoomControls: false,
  );

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'تنبيه الخروج',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'هل تريد الخروج من التطبيق',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('خروج'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (webViewController != null && await webViewController!.canGoBack()) {
          await webViewController!.goBack();
        } else {
          await _showExitDialog();
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
                initialUserScripts: UnmodifiableListView<UserScript>([
                  UserScript(
                    source: """
                      // 1. إخفاء الفوتر ومنع التحديد والنسخ
                      var style = document.createElement('style');
                      style.innerHTML = `
                        footer { display: none !important; }
                        
                        /* منع تحديد النصوص والصور في كل الموقع */
                        * {
                          -webkit-touch-callout: none !important; /* يمنع ظهور قائمة الضغط المطول في الآيفون */
                          -webkit-user-select: none !important;   /* سفاري وكروم */
                          -khtml-user-select: none !important;    /* متصفحات قديمة */
                          -moz-user-select: none !important;      /* فايرفوكس */
                          -ms-user-select: none !important;       /* إيدج */
                          user-select: none !important;           /* أساسي */
                        }

                        /* السماح بالكتابة فقط في مربعات الإدخال أثناء الطلب */
                        input, textarea {
                          -webkit-user-select: auto !important;
                          -khtml-user-select: auto !important;
                          -moz-user-select: auto !important;
                          -ms-user-select: auto !important;
                          user-select: auto !important;
                        }
                      `;
                      document.head.appendChild(style);

                      // 2. منع الزوم من الـ HTML
                      var meta = document.createElement('meta');
                      meta.name = 'viewport';
                      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                      document.getElementsByTagName('head')[0].appendChild(meta);
                    """,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                  ),
                ]),
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
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  var status = await Permission.locationWhenInUse.request();
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: status.isGranted,
                    retain: true,
                  );
                },
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
