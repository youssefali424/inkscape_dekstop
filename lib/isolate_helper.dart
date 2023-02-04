import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:potrace/potrace.dart';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;
import 'package:collection/collection.dart';

import 'svg_clean.dart';

String get inkscape => Platform.isMacOS
    ? '/Applications/Inkscape.app/Contents/MacOS/inkscape'
    : 'inkscape';
String get workingDirectory =>
    Platform.isWindows ? "C:/Program Files/Inkscape/bin" : "";
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
        var svgFile = File(output)
          ..createSync(recursive: true)
          ..writeAsStringSync(svgStr, flush: true);
        filePath = svgFile.path;
      } catch (e) {
        debugPrint("png error: $e");
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
    // debugPrint('$inkscape" ' + getArgs(path, name, output: output).join(" "));
    var process = await Process.run(
        inkscape, getArgs(path, name, output: output),
        workingDirectory: workingDirectory, runInShell: true);
    if (process.exitCode == 0) {
      var svgFile = await File(output).readAsString();
      await File(output).writeAsString(SvgCleaner().clean(svgFile));
      return output;
    } else if (process.stderr != null) {
      debugPrint("processFile stderr: ${process.stderr}");
    }
  } catch (e) {
    debugPrint("processFile error: $e");
  }
  return null;
}

List<String> getArgs(String? path, String name, {String? output}) {
  output ??= getOutput(path, name);
  return [
    '--actions=select-all;selection-ungroup;fit-canvas-to-selection;object-stroke-to-path;path-combine;select-all;fit-canvas-to-selection;vacuum-defs;export-filename:$output;export-overwrite;export-plain-svg;export-do',
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

final slash = Platform.isWindows ? r'\' : r'/';
Future<List<String>> runCommand(
    {required List<PlatformFile> paths,
    String? output,
    void Function(ProcessProgress)? onProcess}) async {
  var count = 0;
  var failed = <String>[];
  var slices = paths.slices(10).toList();
  var successPaths = <String>[];
  for (var slice in slices) {
    var stream = await processInBackground(
        slice, output != null ? "$output$slash" : null);
    await for (var entry in stream) {
      if (entry.path != null) {
        successPaths.add(entry.path!);

        if (onProcess != null) {
          onProcess(ProcessProgress(precentage: count / paths.length));
        }
      } else {
        failed.add(entry.name);
      }
      count++;
    }
  }
  if (onProcess != null) {
    onProcess(
        ProcessProgress(precentage: null, finished: true, failed: failed));
  }

  return successPaths;
}

class ProcessProgress {
  double? precentage;
  bool finished;
  List<String>? failed;
  ProcessProgress({this.precentage, this.finished = false, this.failed});
}
