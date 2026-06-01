import 'package:flutter/foundation.dart';

Future<void> sendRawToPrinter({
  required String printerName,
  required Uint8List bytes,
  String docName = 'Ticket',
}) async {
  debugPrint('Impresión RAW no soportada en Web. Use HTML/JS print.');
}
