// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class StreetViewPage extends StatefulWidget {
//   const StreetViewPage({super.key});

//   @override
//   State<StreetViewPage> createState() => _StreetViewPageState();
// }

// class _StreetViewPageState extends State<StreetViewPage> {

//   late final WebViewController controller;

//   @override
//   void initState() {
//     super.initState();

//     controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..loadRequest(
//         Uri.parse("https://last5sec.github.io/campus-navigation/streetview/index.html"),
//       );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Campus 360° View"),
//       ),
//       body: WebViewWidget(
//         controller: controller,
//       ),
//     );
//   }
// }
// import 'dart:html' as html;
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';

// class StreetViewPage extends StatefulWidget {
//   const StreetViewPage({super.key});

//   @override
//   State<StreetViewPage> createState() => _StreetViewPageState();
// }

// class _StreetViewPageState extends State<StreetViewPage> {

//   final String viewType = "street-view-iframe";

//   @override
//   void initState() {
//     super.initState();

//     // Register iframe for web
//     ui.platformViewRegistry.registerViewFactory(
//       viewType,
//       (int viewId) {
//         final iframe = html.IFrameElement()
//           ..src = "https://last5sec.github.io/campus-navigation/streetview/index.html"
//           ..style.border = "none"
//           ..width = "100%"
//           ..height = "100%";

//         return iframe;
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Campus 360° View"),
//       ),
//       body: HtmlElementView(
//         viewType: viewType,
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class StreetViewPage extends StatelessWidget {
  const StreetViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus 360° View"),
      ),
      body: WebViewX(
        initialContent: "https://last5sec.github.io/campus-navigation/streetview/index.html",
        initialSourceType: SourceType.url,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
      ),
    );
  }
}