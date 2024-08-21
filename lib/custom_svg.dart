import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvg extends StatefulWidget {
  final String fileUrl;
  const CustomSvg({super.key, required this.fileUrl});

  @override
  State<CustomSvg> createState() => _CustomSvgState();
}

class _CustomSvgState extends State<CustomSvg> {
  PictureInfo? pictureInfo;
  @override
  void initState() {
    super.initState();
    getSvg();
  }

  Future<void> getSvg() async {
    // var str = await File(widget.fileUrl).readAsString();
    // final document = XmlDocument.parse(str);
    // debugPrint(str);
    // document.children.initialize(parent, nodeTypes);
    // document.children.forEach((element) {
    //   if (element.nodeType == XmlNodeType.ELEMENT &&
    //       (element as XmlElement).name.local.toLowerCase() == "path") {
    //     print(element.getAttribute("d"));
    //   }
    // });
    // var svgEl = document.findAllElements("svg");
    // if (svgEl.isNotEmpty) {
    //   svgEl.first;
    // }

    // var paths = document.findAllElements("path");
    // if (paths.isNotEmpty) {
    //   paths.forEach((element) {
    //     print(element.getAttribute("d"));
    //     // element.setAttribute(name, value)
    //   });
    // }
    // SvgStringLoader
    // var parsed = parse(str, key: widget.fileUrl);
    // parsed.toString();

    //     pictureInfo.picture.;
    // svg.fromSvgString(str, widget.fileUrl).then((svgd) {
    //   var temp = svgd.mergeStyle(const DrawableStyle(
    //       pathFillType: PathFillType.nonZero,
    //       fill: DrawablePaint(
    //         PaintingStyle.fill,
    //         color: Colors.black,
    //       )));

    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgFileLoader(File(widget.fileUrl),
          colorMapper: const CustomColorMapper()),
      null,
    );
    if (mounted) {
      setState(() {
        this.pictureInfo = pictureInfo;
      });
    }
    //   }
    // }).catchError(print);
  }

  @override
  void didUpdateWidget(covariant CustomSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileUrl != widget.fileUrl) {
      getSvg();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pictureInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: _CustomSvgPainter(pictureInfo!),
    );
  }
}

class _CustomSvgPainter extends CustomPainter {
  PictureInfo pictureInfo;
  _CustomSvgPainter(this.pictureInfo);

  @override
  void paint(Canvas canvas, Size size) {
    // svgRoot.scaleCanvasToViewBox(canvas, size);
    canvas.scale(size.width / pictureInfo.size.width,
        size.height / pictureInfo.size.height);
    canvas.drawPicture(pictureInfo.picture);
    // canvas.drawImage(
    //     pictureInfo.picture
    //         .toImageSync(size.width.floor(), size.height.floor()),
    //     Offset.zero,
    //     Paint());
    // pictureInfo.size.width;

    // svgRoot.draw(canvas, Rect=C.fromLTRB(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(_CustomSvgPainter oldDelegate) {
    return pictureInfo != oldDelegate.pictureInfo;
  }
}

class CustomColorMapper extends ColorMapper {
  const CustomColorMapper();

  @override
  Color substitute(
      String? id, String elementName, String attributeName, Color color) {
    return Colors.black;
  }
}
