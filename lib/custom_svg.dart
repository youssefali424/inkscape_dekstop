import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class CustomSvg extends StatefulWidget {
  final String fileUrl;
  const CustomSvg({super.key, required this.fileUrl});

  @override
  State<CustomSvg> createState() => _CustomSvgState();
}

class _CustomSvgState extends State<CustomSvg> {
  DrawableRoot? svgRoot;

  @override
  void initState() {
    super.initState();
    getSvg();
  }

  Future<void> getSvg() async {
    var str = await File(widget.fileUrl).readAsString();
    // final document = XmlDocument.parse(str);
    // print(document.toString());
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
    svg.fromSvgString(str, widget.fileUrl).then((svgd) {
      var temp = svgd.mergeStyle(const DrawableStyle(
          pathFillType: PathFillType.nonZero,
          fill: DrawablePaint(
            PaintingStyle.fill,
            color: Colors.black,
          )));
      if (mounted) {
        setState(() {
          svgRoot = temp;
        });
      }
    }).catchError(print);
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
    if (svgRoot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: _CustomSvgPainter(svgRoot!),
    );
  }
}

class _CustomSvgPainter extends CustomPainter {
  DrawableRoot svgRoot;
  _CustomSvgPainter(this.svgRoot);

  @override
  void paint(Canvas canvas, Size size) {
    svgRoot.scaleCanvasToViewBox(canvas, size);

    svgRoot.draw(canvas, Rect.fromLTRB(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(_CustomSvgPainter oldDelegate) {
    return svgRoot != (oldDelegate).svgRoot;
  }
}
