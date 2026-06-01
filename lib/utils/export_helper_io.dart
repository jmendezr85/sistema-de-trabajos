import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

void downloadTextFile({
  required String filename,
  required String content,
  required String mimeType,
}) {
  // En desktop guardamos con selector
  saveBytesFile(
    filename: filename,
    bytes: Uint8List.fromList(content.codeUnits),
    mimeType: mimeType,
  );
}

Future<void> saveBytesFile({
  required String filename,
  required Uint8List bytes,
  String mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
}) async {
  final path = await getSaveLocation(
    suggestedName: filename,
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'Archivo',
        extensions: [filename.split('.').last],
        mimeTypes: [mimeType],
      ),
    ],
  );

  if (path == null) return;

  final file = File(path.path);
  await file.writeAsBytes(bytes, flush: true);
}
