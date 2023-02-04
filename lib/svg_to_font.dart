// ignore_for_file: implementation_imports

import 'dart:io';

// import 'package:mrx_icon_font_gen/mrx_icon_font_gen.dart';
import 'package:inkscape_desktop/isolate_helper.dart';
import 'package:mrx_icon_font_gen/src/flutter_icon_client/flutter_icon_client.dart';
import 'package:mrx_icon_font_gen/src/config_generator/config_generator.dart';
import 'package:mrx_icon_font_gen/src/config_generator/model/icon_file.dart';
import 'package:mrx_icon_font_gen/src/config_generator/model/generator_options.dart';

import 'svg_clean.dart';

class SvgToFont {
  Future<void> run({
    required String from,
    required List<String> paths,
    required String out,
  }) async {
    var config = "$out${slash}config$slash";
    var fontDir = "${config}font$slash";
    final GeneratorOptions options = GeneratorOptions(
        from: from,
        outConfig: config,
        outFont: fontDir,
        outFlutter: fontDir,
        className: "AppIcons");
    // final String directory = options.from;
    // final DirectoryScanner scanner = DirectoryScanner(path: directory);
    // final List<File> files = await scanner.scanPath();

    final List<IconFile> iconFiles = [];
    for (final path in paths) {
      var file = File(path);
      var svgString = await file.readAsString();
      await file.writeAsString(
          SvgCleaner().clean(svgString, prepareForFontello: true));
      final IconFile iconFile = IconFile(
        file: file,
      )..parse();
      if (iconFile.error != null) {
        stderr.writeln(iconFile.error);
        continue;
      }
      iconFiles.add(iconFile);
    }

    final ConfigGenerator configGenerator = ConfigGenerator(
      options: options,
      files: iconFiles,
    );
    configGenerator.generate();

    final FlutterIconClient flutterIconClient = FlutterIconClient(
      options: options,
    );
    await flutterIconClient.generateFont();
  }
}
