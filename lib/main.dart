// ignore_for_file: depend_on_referenced_packages

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:path_provider/path_provider.dart';

import 'file_item.dart';
import 'isolate_helper.dart';

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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Icon svg'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const distance = Offset(30, 30);
const blur = 25.0;

class _MyHomePageState extends State<MyHomePage> {
  // String? _output;
  List<PlatformFile> _paths = [];
  Map<int, String> _processedFiles = {};

  double? loadingPercentage;
  bool preview = false;

  // void _incrementCounter() {
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _counter++;
  //   });
  // }

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
                        onPressed: runCommand,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            textStyle: const TextStyle(fontSize: 16)),
                        child: const Text('convert'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: browseOutput,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            textStyle: const TextStyle(fontSize: 16)),
                        child: const Text('Convert to folder'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (loadingPercentage != null)
            Positioned.fill(
                child: loadingPercentage != null
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child:
                              LinearProgressIndicator(value: loadingPercentage),
                        )))
                    : Container())
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
      runCommand(output: output);
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

  runCommand({String? output}) async {
    setState(() {
      loadingPercentage = 0.0;
    });
    var count = 0;
    var failed = <String>[];
    var slices = _paths.slices(10).toList();
    // var i = 0;
    for (var slice in slices) {
      var stream =
          await processInBackground(slice, output != null ? "$output/" : null);
      await for (var entry in stream) {
        if (entry.path != null) {
          setState(() {
            loadingPercentage = count / _paths.length;
          });
        } else {
          failed.add(entry.name);
        }
        count++;
      }
      // i += slice.length;
    }
    // for (var file in _paths) {
    //   try {
    //     var process = await Process.run(
    //         inkscape,
    //         getArgs(file.path, file.name,
    //             output: output != null ? "$output/${file.name}" : null),
    //         runInShell: true);
    //     if (process.exitCode != 0) {
    //       failed.add("${file.name} : ${process.stderr} ${process.stdout}");
    //     }
    //   } catch (e) {
    //     print(e);
    //     failed.add(file.name);
    //     showDialog(
    //         context: context,
    //         builder: (context) => AlertDialog(
    //               title: const Text('error'),
    //               content: Text(e.toString()),
    //             ));
    //   }
    //   count++;
    //   setState(() {
    //     loadingPercentage = count / _paths.length;
    //   });
    // }
    setState(() {
      loadingPercentage = null;
    });
    if (failed.isNotEmpty) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Failed'),
                content: Text(failed.join(',')),
              ));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All files converted successfully'),
          ),
        );
      }
    }
  }

  processFiles() async {
    var directory = await getTemporaryDirectory();
    var slices = _paths.slices(10).toList();
    var i = 0;
    for (var slice in slices) {
      // for(var file in slice) {
      //   _processedFiles[file.index] = file.path;
      // }
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
}
