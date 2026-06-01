import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

void downloadTextFile({
  required String filename,
  required String content,
  required String mimeType,
}) {
  final bytes = utf8.encode(content);
  final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: mimeType));
  final url = URL.createObjectURL(blob);

  final anchor = document.createElement('a') as HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();

  URL.revokeObjectURL(url);
}

Future<void> saveBytesFile({
  required String filename,
  required Uint8List bytes,
  String mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
}) async {
  final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: mimeType));
  final url = URL.createObjectURL(blob);

  final anchor = document.createElement('a') as HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();

  URL.revokeObjectURL(url);
}
