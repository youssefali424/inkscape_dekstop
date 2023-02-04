import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';

import 'custom_svg.dart';

class FileItem extends StatelessWidget {
  final int index;
  final PlatformFile file;
  final String? processedFileUrl;
  final bool preview;
  const FileItem(
      {super.key,
      required this.index,
      required this.file,
      this.preview = false,
      this.processedFileUrl});

  @override
  Widget build(BuildContext context) {
    var isPng = file.name.toLowerCase().endsWith('.png');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Text("${index + 1} - ${file.name}"),
          const SizedBox(width: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPng)
                DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      )),
                  child: file.bytes != null
                      ? SvgPicture.memory(
                          file.bytes ?? Uint8List(0),
                          semanticsLabel: file.name,
                          height: 20,
                          placeholderBuilder: (BuildContext context) =>
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator()),
                        )
                      : SvgPicture.file(
                          File(file.path ?? ""),
                          semanticsLabel: file.name,
                          height: 20,
                          placeholderBuilder: (BuildContext context) =>
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator()),
                        ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      )),
                  child: file.bytes != null
                      ? Image.memory(
                          file.bytes ?? Uint8List(0),
                          height: 20,
                        )
                      : Image.file(
                          File(file.path ?? ""),
                          height: 20,
                        ),
                ),
              if (preview && processedFileUrl != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("------>",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      )),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomSvg(fileUrl: processedFileUrl!)),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}
