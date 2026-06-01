import 'dart:typed_data';

Future<void> sendRawToPrinter({
  required String printerName,
  required Uint8List bytes,
  String docName = 'Ticket',
}) async {
  throw UnsupportedError('Platform not supported for raw printing');
}
