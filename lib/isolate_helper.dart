import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:potrace/potrace.dart';
import 'package:image/image.dart' as img;

String get inkscape => '/Applications/Inkscape.app/Contents/MacOS/inkscape';

@pragma('vm:entry-point')
Future<void> _processFilesInIsolate(List<dynamic> args) async {
  SendPort responsePort = args[0];
  List<String> fileNames = args[1];
  List<String?> filePaths = args[2];
  String? directoryPath = args[3];

  var futures = <Future<void>>[];
  for (var i = 0; i < fileNames.length; i++) {
    var fileName = fileNames[i];
    var filePath = filePaths[i];
    var isPng = fileName.toLowerCase().endsWith('.png');
    var output = directoryPath != null
        ? "$directoryPath$fileName"
        : getOutput(filePath, fileName);
    if (isPng) {
      try {
        var image = await img.decodeImageFile(filePath ?? "");
        if (image == null) continue;
        var svgStr = potrace(image);
        fileName = fileName.replaceAll(RegExp(r'(\.png)|(\.PNG)'), '.svg');
        output = output.replaceAll(RegExp(r'(\.png)|(\.PNG)'), '.svg');
        var svgFile = await File(output).writeAsString(svgStr);
        filePath = svgFile.path;
      } catch (e) {
        debugPrint(e.toString());
        continue;
      }
    }

    futures.add(processFile(filePath, fileName, output)
        .then((value) => responsePort.send([i, value, fileName])));
  }
  await Future.wait(futures);
  Isolate.exit(responsePort, true);
}

Future<String?> processFile(String? path, String name, String output) async {
  try {
    // var output = "$directoryPath$name";
    var process = await Process.run(
        inkscape, getArgs(path, name, output: output),
        runInShell: true);
    if (process.exitCode == 0) {
      return output;
    }
  } catch (e) {
    print(e);
  }
  return null;
}

List<String> getArgs(String? path, String name, {String? output}) {
  output ??= getOutput(path, name);
  return [
    '--actions=select-all;selection-ungroup;fit-canvas-to-selection;object-stroke-to-path;path-combine;vacuum-defs;export-filename:$output;export-do',
    '$path'
  ];
}

String getOutput(String? path, String name) {
  var currentMillis = DateTime.now().millisecondsSinceEpoch;
  return path?.replaceAll(name, "out/${currentMillis}_$name") ??
      "out/${currentMillis}_$name";
}

class IsolateResult {
  int index;
  String? path;
  String name;
  IsolateResult(this.index, this.path, this.name);
}

Future<Stream<IsolateResult>> processInBackground(
    List<PlatformFile> files, String? dir) async {
  final p = ReceivePort();
  final exitPort = ReceivePort();

  await Isolate.spawn(
      _processFilesInIsolate,
      [
        p.sendPort,
        files.map((e) => e.name).toList(),
        files.map((e) => e.path).toList(),
        dir,
      ],
      onExit: exitPort.sendPort);
  exitPort.listen((message) {
    p.close();
    exitPort.close();
  });
  return p
      .map((event) {
        return event is List
            ? IsolateResult(
                event[0] as int, event[1] as String?, event[2] as String)
            : null;
      })
      .where((element) => element != null)
      .cast<IsolateResult>();
}
