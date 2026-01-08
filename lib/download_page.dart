import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'download_provider.dart';



class DownloadsPage extends StatefulWidget {
  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      setState(() {
        files = directory.listSync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Downloads")),
      body: Consumer<DownloadProvider>(
        builder: (context, downloadProvider, child) {
          return files.isEmpty
              ? Center(child: Text("No Downloads"))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    File file = File(files[index].path);
                    String fileName = file.path.split('/').last;
                    double progress = downloadProvider.getProgress(file.path);

                    return ListTile(
                      title: Text(fileName),
                      subtitle: progress < 1.0
                          ? LinearProgressIndicator(value: progress)
                          : Text("Tap to Open"),
                      trailing: progress < 1.0
                          ? Text("${(progress * 100).toStringAsFixed(0)}%")
                          : IconButton(
                              icon: Icon(Icons.open_in_new),
                              onPressed: () {
                                OpenFile.open(file.path);
                              },
                            ),
                    );
                  },
                );
        },
      ),
    );
  }
}
