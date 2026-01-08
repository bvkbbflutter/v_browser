import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:v_browser/main.dart';

import 'download_page.dart';
import 'download_provider.dart';
import 'services/local_notification_service.dart';

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  double progress = 0;
  // final String homePageUrl = "https://www.google.com";
  final String homePageUrl = "http://45.198.59.40/dicom/DirectDicomGrid.htm?dHlwZT1VJnZhbHVlPVNSSDAwMDAwMDE=";
  final TextEditingController urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    urlController.text = homePageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            if (await webViewController!.canGoBack()) {
              webViewController!.goBack();
            }
          },
        ),
        title: TextField(
          controller: urlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (url) {
            if (!url.startsWith("http")) {
              url = "https://$url";
            }
            webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
          },
          decoration: const InputDecoration(
            hintText: "Enter URL",
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(10),
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => webViewController?.reload()),

          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {

            }
          ),

          const SizedBox(width: 10,)
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, color: Colors.blue),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(homePageUrl)),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onDownloadStartRequest: (controller, urlRequest) async {
                await _downloadFile(context, urlRequest.url.toString());
              },
              onProgressChanged: (controller, p) {
                setState(() {
                  progress = p / 100.0;
                });
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                setState(() {
                  urlController.text = url.toString();
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await webViewController?.canGoBack() ?? false) {
                  webViewController?.goBack();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () async {
                if (await webViewController?.canGoForward() ?? false) {
                  webViewController?.goForward();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(homePageUrl)));
                urlController.text = homePageUrl;
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DownloadsPage()));
              },
            ),
          ],
        ),
      ),
    );
  }


Future<void> _downloadFile(BuildContext context, String url) async {
  if (await _requestPermissions()) {
    Directory? directory = await getExternalStorageDirectory();
    String filePath = "${directory?.path}/${Uri.parse(url).pathSegments.last}";

    try {
      File file = File(filePath);
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      var sink = file.openWrite();
      await for (var chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        double progress = (receivedBytes / totalBytes);

        // Update progress in Provider
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        downloadProvider.updateProgress(url, progress);

        // Update progress in notification
        LocalNotificationServiceV().showDownloadNotificationProgress(url, progress);
      }

      await sink.close();

      // Show completion notification
      LocalNotificationServiceV().showDownloadCompleteNotification(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Downloaded: ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Download Failed: $e")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Storage Permission Denied")),
    );
  }
}




  Future<void> _showDownloadNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel', 'Downloads',
      importance: Importance.high, priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      "Download Complete",
      "Tap to view downloads",
      platformChannelSpecifics,
      payload: "open_downloads",
    );
  }
}




// Request Storage Permissions for Android 11+
Future<bool> _requestPermissions() async {
  if (await Permission.storage.request().isGranted) {
    return true;
  } else if (await Permission.manageExternalStorage.request().isGranted) {
    return true;
  } else {
    return false;
  }
}




// Future<void> requestStoragePermission() async {
//   if (await Permission.storage.request().isGranted) {
//     print("✅ Storage Permission Granted");
//   } else if (await Permission.storage.isPermanentlyDenied) {
//     openAppSettings();
//   } else {
//     print("❌ Storage Permission Denied");
//   }
// }



// Future<void> _downloadFile(BuildContext context, String url) async {
  //   await Permission.storage.request();
  //   if (await Permission.storage.request().isGranted) {
  //     Directory? directory = await getExternalStorageDirectory();
  //     String filePath = "${directory?.path}/${Uri.parse(url).pathSegments.last}";

  //     try {
  //       File file = File(filePath);
  //       var request = await HttpClient().getUrl(Uri.parse(url));
  //       var response = await request.close();
  //       await response.pipe(file.openWrite());

  //       Provider.of<DownloadProvider>(context, listen: false)
  //           .updateProgress(url, 1);
  //       _showDownloadNotification(filePath);

  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Download Failed: $e")));
  //     }
  //   } else {
  //     await requestStoragePermission();
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Storage Permission Denied")));
  //   }
  // }
