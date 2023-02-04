import 'dart:math';

import 'package:svgpath/svgpath.dart';
import 'package:xml/xml.dart';

var namespacePrefixes = ['dc', 'rdf', 'sodipodi', 'cc', 'inkscape', 'defs'];

class SvgCleaner {
  String clean(String svgString, {bool prepareForFontello = false}) {
    final svgDoc = XmlDocument.parse(svgString);

    // Find all unused elements in the document
    final unusedElements = svgDoc.findAllElements('*').where((element) {
      if (namespacePrefixes
          .contains(element.name.prefix ?? element.name.local)) {
        return true;
      }
      return element.attributes.isEmpty &&
          element.children.isEmpty &&
          !element.text.trim().isNotEmpty;
    }).toList();

    for (var element in unusedElements) {
      element.parent?.children.remove(element);
    }

    /// scale svg for fontello compatibility
    /// and to remove padding around the icon
    if (prepareForFontello) {
      var svgElement = svgDoc.findElements('svg').first;
      double? width =
          double.tryParse(svgElement.getAttribute('width') ?? "1000");
      double? height =
          double.tryParse(svgElement.getAttribute('height') ?? "1000");
      double scale =
          1000 / (width == null ? height ?? 1000 : max(width, height ?? 0));
      var pathElement = svgDoc.findAllElements('path').first;
      String? pathData = pathElement.getAttribute('d');
      if (pathData != null) {
        var d =
            SvgPath(pathData).scale(scale, -scale).abs().round(1).toString();
        pathElement.setAttribute('d', d);
        svgElement.setAttribute(
            'width', width == null ? "1000" : (width * scale).toString());
        if (height != null) {
          svgElement.setAttribute('height', (height * scale).toString());
        }
      }
    }

    /// end scale

    return svgDoc.toXmlString(pretty: true);
  }
}
