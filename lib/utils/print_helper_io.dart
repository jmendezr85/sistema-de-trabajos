import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

Future<void> sendRawToPrinter({
  required String printerName,
  required Uint8List bytes,
  String docName = 'Ticket',
}) async {
  if (defaultTargetPlatform != TargetPlatform.windows) {
    debugPrint('Impresión RAW solo soportada en Windows (nativa).');
    return;
  }

  final pPrinterName = printerName.toNativeUtf16();
  final phPrinter = calloc<HANDLE>();

  try {
    // 1. Abrir impresora
    final result = OpenPrinter(pPrinterName, phPrinter, nullptr);
    if (result == 0) {
      debugPrint('Error OpenPrinter: $result');
      return;
    }

    final hPrinter = phPrinter.value;

    // 2. Iniciar Documento
    final pDocName = docName.toNativeUtf16();
    final pDataType = 'RAW'.toNativeUtf16();

    final docInfo = calloc<DOC_INFO_1>();
    docInfo.ref.pDocName = pDocName;
    docInfo.ref.pOutputFile = nullptr;
    docInfo.ref.pDatatype = pDataType;

    final dwJob = StartDocPrinter(hPrinter, 1, docInfo);
    if (dwJob == 0) {
      debugPrint('Error StartDocPrinter');
      ClosePrinter(hPrinter);
      calloc.free(pDocName);
      calloc.free(pDataType);
      calloc.free(docInfo);
      return;
    }

    // 3. Iniciar Página
    StartPagePrinter(hPrinter);

    // 4. Escribir Bytes
    final pBytes = calloc<Uint8>(bytes.length);
    final byteList = pBytes.asTypedList(bytes.length);
    byteList.setAll(0, bytes);

    final pcWritten = calloc<DWORD>();
    final writeResult = WritePrinter(hPrinter, pBytes, bytes.length, pcWritten);

    if (writeResult == 0) {
      debugPrint('Error WritePrinter');
    }

    // 5. Finalizar y Limpiar
    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);

    calloc.free(pDocName);
    calloc.free(pDataType);
    calloc.free(docInfo);
    calloc.free(pBytes);
    calloc.free(pcWritten);
  } finally {
    calloc.free(pPrinterName);
    calloc.free(phPrinter);
  }
}
