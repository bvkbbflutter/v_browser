import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'download_provider.dart';
import 'services/local_notification_service.dart';
import 'webview_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationServiceV().initNotifications();


  runApp(
    ChangeNotifierProvider(
      create: (_) => DownloadProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Browser',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WebViewScreen(),
    );
  }
}





















































// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'download_provider.dart';


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await FlutterDownloader.initialize(debug: true);

//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => DownloadProvider(),
//       child: MyBrowserApp(),
//     ),
//   );
// }


// Future<void> requestStoragePermission() async {
//   if (await Permission.storage.request().isGranted) {
//     print("✅ Storage Permission Granted");
//   } else if (await Permission.storage.isPermanentlyDenied) {
//     openAppSettings();
//   } else {
//     print("❌ Storage Permission Denied");
//   }
// }

// class MyBrowserApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Browser',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: WebViewScreen(),
//     );
//   }
// }

// class WebViewScreen extends StatefulWidget {
//   @override
//   _WebViewScreenState createState() => _WebViewScreenState();
// }

// class _WebViewScreenState extends State<WebViewScreen> {
//   InAppWebViewController? webViewController;
//   double progress = 0;
//   final String homePageUrl = "https://www.google.com";
//   final TextEditingController urlController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     requestStoragePermission();
//     urlController.text = homePageUrl;
//   }



//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: GestureDetector(
//           onTap: () async{
//             if (await webViewController!.canGoBack()){
//               webViewController!.goBack();
//             }
//           },
//           child: Icon(Icons.arrow_back)),
//         title: TextField(
//           controller: urlController,
//           keyboardType: TextInputType.url,
//           textInputAction: TextInputAction.go,
//           onSubmitted: (url) {
//             if (!url.startsWith("http")) {
//               url = "https://$url";
//             }
//             webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
//           },
//           decoration: const InputDecoration(hintText: "Enter URL", border: InputBorder.none, contentPadding: EdgeInsets.all(10)),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               webViewController?.reload();
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: () {
              
//             },
//           ),
//           const SizedBox(
//             width: 10,
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           LinearProgressIndicator(value: progress, color: Colors.blue),
//           Expanded(
//             child: InAppWebView(
//               initialUrlRequest: URLRequest(url: WebUri(homePageUrl)),
//               onWebViewCreated: (controller) {
//                 webViewController = controller;
//               },
//               onDownloadStartRequest: (controller, urlRequest) async {
//                 await _downloadFile(urlRequest.url.toString());
//               },
//               onProgressChanged: (controller, p) {
//                 setState(() {
//                   progress = p / 100.0;
//                 });
//               },
//               onUpdateVisitedHistory: (controller, url, androidIsReload) {
//                 setState(() {
//                   urlController.text = url.toString();
//                 });
//               },
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomAppBar(
//         shape: const CircularNotchedRectangle(),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
            // IconButton(
            //   icon: const Icon(Icons.arrow_back),
            //   onPressed: () async {
            //     if (await webViewController?.canGoBack() ?? false) {
            //       webViewController?.goBack();
            //     }
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.arrow_forward),
            //   onPressed: () async {
            //     if (await webViewController?.canGoForward() ?? false) {
            //       webViewController?.goForward();
            //     }
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.home),
            //   onPressed: () {
            //     webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(homePageUrl)));
            //     urlController.text = homePageUrl;
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.download),
            //   onPressed: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => DownloadsPage()));
            //   },
            // ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _downloadFile(String url) async {
//     if (await Permission.manageExternalStorage.request().isGranted) {
//       Directory? directory = await getExternalStorageDirectory();
//       String filePath = "${directory?.path}/${Uri.parse(url).pathSegments.last}";

//       try {
//         File file = File(filePath);
//         var request = await HttpClient().getUrl(Uri.parse(url));
//         var response = await request.close();
//         await response.pipe(file.openWrite());
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Downloaded: ${file.path}")));
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Download Failed: $e")));
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Storage Permission Denied")));
//     }
//   }
// }

// class DownloadsPage extends StatefulWidget {
//   @override
//   _DownloadsPageState createState() => _DownloadsPageState();
// }

// class _DownloadsPageState extends State<DownloadsPage> {
//   List<FileSystemEntity> files = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadDownloadedFiles();
//   }

//   Future<void> _loadDownloadedFiles() async {
//     Directory? directory = await getExternalStorageDirectory();
//     if (directory != null) {
//       setState(() {
//         files = directory.listSync();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Downloads")),
//       body: files.isEmpty
//           ? Center(child: Text("No Downloads"))
//           : ListView.builder(
//               itemCount: files.length,
//               itemBuilder: (context, index) {
//                 File file = File(files[index].path);
//                 return ListTile(
//                   title: Text(file.path.split('/').last),
//                   subtitle: Text("Tap to Open"),
//                   onTap: () {
//                     OpenFile.open(file.path);
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }
