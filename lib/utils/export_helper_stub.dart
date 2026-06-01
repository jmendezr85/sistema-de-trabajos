import 'dart:typed_data';

void downloadTextFile({
  required String filename,
  required String content,
  required String mimeType,
}) {
  throw UnsupportedError(
      'downloadTextFile no está soportado en esta plataforma');
}

Future<void> saveBytesFile({
  required String filename,
  required Uint8List bytes,
  String mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
}) async {
  throw UnsupportedError('saveBytesFile no está soportado en esta plataforma');
}
