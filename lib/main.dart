// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:inkscape_desktop/loading_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'file_item.dart';
import 'isolate_helper.dart';
import 'svg_to_font.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
          PointerDeviceKind.invertedStylus,
          PointerDeviceKind.trackpad,
        },
        scrollbars: true,
      ),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Icon svg'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const distance = Offset(30, 30);
const blur = 25.0;

class _MyHomePageState extends State<MyHomePage> {
  List<PlatformFile> _paths = [];
  Map<int, String> _processedFiles = {};

  double? loadingPercentage;
  bool preview = false;
  bool? loadingFonts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    const Text("Selected files:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Checkbox(
                        value: preview,
                        onChanged: (_) {
                          var preview = !this.preview;
                          if (preview && _processedFiles.isEmpty) {
                            processFiles();
                          }
                          setState(() {
                            this.preview = preview;
                          });
                        }),
                    const Text("Preview",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _paths.isNotEmpty
                      ? [
                          Expanded(
                              child: ListView.builder(
                                  itemCount: _paths.length,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemBuilder: (_, i) {
                                    final file = _paths[i];
                                    return FileItem(
                                      file: file,
                                      index: i,
                                      processedFileUrl: _processedFiles[i],
                                      preview: preview,
                                    );
                                  }))
                        ]
                      : [],
                ),
              ),
              if (_paths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: browseOutput,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            textStyle: const TextStyle(fontSize: 16)),
                        child: const Text('Convert to enhanced svg'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: processFilesToFont,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            textStyle: const TextStyle(fontSize: 16)),
                        child: const Text('Convert to font'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          LoadingView(
            loadingPercentage: loadingPercentage,
            isLoadingFonts: loadingFonts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickFiles,
        tooltip: 'Pick files',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> browseOutput() async {
    var output = await FilePicker.platform.getDirectoryPath();
    if (output != null) {
      setState(() {
        loadingPercentage = 0.0;
      });
      runCommand(
        output: output,
        paths: _paths,
        onProcess: (progress) {
          setState(() {
            loadingPercentage = progress.precentage;
          });
          if (!progress.finished) return;
          if (progress.failed?.isNotEmpty ?? false) {
            if (mounted) {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Failed'),
                        content: Text(progress.failed!.join(',')),
                      ));
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All files converted successfully'),
                ),
              );
            }
          }
        },
      );
    } else {
      // User canceled the picker
    }
  }

  pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['svg', 'SVG', 'png', 'PNG'],
      type: FileType.custom,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _paths = result.files;
        _processedFiles = {};
      });
      if (preview) processFiles();
    }
  }

  processFiles() async {
    var directory = await getTemporaryDirectory();
    var slices = _paths.slices(10).toList();
    var i = 0;
    for (var slice in slices) {
      var stream = await processInBackground(slice,
          "${directory.path}/inkscape/${DateTime.now().millisecondsSinceEpoch}_");
      await for (var entry in stream) {
        if (entry.path != null) {
          setState(() {
            _processedFiles[entry.index + i] = entry.path!;
          });
        }
      }
      i += slice.length;
    }
  }

  Future<void> processFilesToFont() async {
    var output = await FilePicker.platform.getDirectoryPath();
    if (output == null) return;
    var directory = await getTemporaryDirectory();
    var tempDirPath = path.join(directory.path, "svfToFont");
    setState(() {
      loadingPercentage = 0.0;
    });
    var paths = await runCommand(
      output: tempDirPath,
      paths: _paths,
      onProcess: (progress) {
        setState(() {
          loadingPercentage = progress.precentage;
        });
        if (!progress.finished) return;
        if (progress.failed?.isNotEmpty ?? false) {
          if (mounted) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('Failed'),
                      content: Text(
                          "Please make sure you have inkscape installed \n\r${progress.failed!.join(',')}"),
                    ));
          }
        }
      },
    );
    setState(() {
      loadingFonts = true;
    });
    try {
      await SvgToFont().run(from: tempDirPath, paths: paths, out: output);
    } catch (e) {
      debugPrint("Failed to convert to font: $e");
      showDialog(
          context: context,
          builder: (context) => const AlertDialog(
                title: Text('Failed'),
                content: Text("Failed to convert to font try again"),
              ));
    }
    setState(() {
      loadingFonts = false;
    });
    Directory(tempDirPath).delete(recursive: true);
  }
}
