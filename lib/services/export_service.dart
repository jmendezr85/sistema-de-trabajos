import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/orden_item_model.dart';
import '../models/orden_model.dart';
import '../utils/export_helper.dart';

class ExportService {
  // ==========================
  // Config
  // ==========================
  static const double _umbralAlto = 300000.0;

  static final DateFormat _dfDia = DateFormat('yyyy-MM-dd');
  static final DateFormat _dfFile = DateFormat('yyyyMMdd');

  static CellIndex _ci(int col, int row) =>
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

  // ==========================
  // Styles (compatibles con tu paquete excel)
  // ==========================
  static void _applyThinBorder(CellStyle s) {
    s.leftBorder = Border(borderStyle: BorderStyle.Thin);
    s.rightBorder = Border(borderStyle: BorderStyle.Thin);
    s.topBorder = Border(borderStyle: BorderStyle.Thin);
    s.bottomBorder = Border(borderStyle: BorderStyle.Thin);
  }

  static CellStyle _styleHeader() {
    final s = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    s.backgroundColor = ExcelColor.fromHexString('#1E88E5');
    s.fontColor = ExcelColor.fromHexString('#FFFFFF');
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _styleTitleBar() {
    final s = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    s.backgroundColor = ExcelColor.fromHexString('#E3F2FD');
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _styleNoCell() {
    final s = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _styleMoneyBase() {
    final s = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _styleMoneyZero() {
    final s = _styleMoneyBase();
    s.fontColor = ExcelColor.fromHexString('#9E9E9E'); // gris
    return s;
  }

  static CellStyle _styleMoneyHigh() {
    final s = _styleMoneyBase();
    s.isBold = true;
    s.backgroundColor = ExcelColor.fromHexString('#E8F5E9'); // verde suave
    return s;
  }

  static CellStyle _styleTotalCell() {
    final s = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    s.backgroundColor = ExcelColor.fromHexString('#E3F2FD');
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _styleKpiCell() {
    final s = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 13,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    s.backgroundColor =
        ExcelColor.fromHexString('#C8E6C9'); // verde más marcado
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _styleLabelBoldLeft() {
    return CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _stylePercentCell() {
    final s = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    _applyThinBorder(s);
    return s;
  }

  static CellStyle _moneyStyleFor(double v) {
    if (v == 0) return _styleMoneyZero();
    if (v >= _umbralAlto) return _styleMoneyHigh();
    return _styleMoneyBase();
  }

  // ==========================
  // Setters (números como números => sin triángulos verdes)
  // ==========================
  static void _setText(Sheet sh, int col, int row, String value,
      {CellStyle? style}) {
    final cell = sh.cell(_ci(col, row));
    cell.value = TextCellValue(value);
    if (style != null) cell.cellStyle = style;
  }

  static void _setInt(Sheet sh, int col, int row, int value,
      {CellStyle? style}) {
    final cell = sh.cell(_ci(col, row));
    cell.value = IntCellValue(value);
    if (style != null) cell.cellStyle = style;
  }

  static void _setNum(Sheet sh, int col, int row, num value,
      {CellStyle? style}) {
    final cell = sh.cell(_ci(col, row));
    cell.value = DoubleCellValue(value.toDouble());
    if (style != null) cell.cellStyle = style;
  }

  static void _setPercentAsText(Sheet sh, int col, int row, double fraction,
      {CellStyle? style}) {
    final p = fraction * 100.0;
    final s = '${p.toStringAsFixed(2)}%';
    _setText(sh, col, row, s, style: style);
  }

  // ==========================
  // Cálculo REAL por items
  // ==========================
  static _ReporteTotales _calcTotalesDesdeItems(List<OrdenItem> items) {
    double laser = 0;
    double ploteo = 0;
    double diseno = 0;
    double scanner = 0; // si no lo usas, queda 0

    for (final it in items) {
      final sec = it.seccion.trim().toLowerCase();
      final meta = it.meta;

      // ✅ DISEÑO: SOLO diseno/diseno_corte
      if (sec == 'diseno' || sec == 'diseno_corte') {
        diseno += it.subtotal;
        continue;
      }

      // ✅ IMPRESIÓN/LASER: SOLO la parte de laser (NO material)
      if (sec.startsWith('laser_')) {
        if (it.costoLaser > 0) {
          laser += it.costoLaser;
        } else {
          final unitLaser = (meta['unit_laser'] is num)
              ? (meta['unit_laser'] as num).toDouble()
              : 0.0;
          if (unitLaser > 0) {
            laser += unitLaser * it.cantidad;
          } else {
            laser += it.subtotal; // fallback
          }
        }
        continue;
      }

      // ✅ PLOTEO INTERIOR: SOLO base (ploteo real)
      if (sec == 'ploteo_interior') {
        final base =
            (meta['base'] is num) ? (meta['base'] as num).toDouble() : 0.0;
        ploteo += (base > 0 ? base : it.subtotal);
        continue;
      }

      // ✅ PLOTEO EXTERIOR: SOLO costo_ploteo
      if (sec == 'ploteo_exterior') {
        final costoPloteo = (meta['costo_ploteo'] is num)
            ? (meta['costo_ploteo'] as num).toDouble()
            : 0.0;
        ploteo += (costoPloteo > 0 ? costoPloteo : it.subtotal);
        continue;
      }

      // ✅ OBS/ANILLADO/OTROS: no cuentan en este reporte
      if (sec == 'observacion' || sec == 'obs' || sec.contains('observ')) {
        continue;
      }
    }

    return _ReporteTotales(
      laser: laser,
      ploteo: ploteo,
      diseno: diseno,
      scanner: scanner,
    );
  }

  // ==========================
  // Hoja: REPORTE DIARIO por diseñador
  // ==========================
  static void _buildHojaReporteDiario({
    required Sheet sh,
    required DateTime dia,
    required String disenador,
    required _ReporteTotales tot,
  }) {
    final header = _styleHeader();
    final titleBar = _styleTitleBar();
    final noStyle = _styleNoCell();
    final labelBold = _styleLabelBoldLeft();
    final totalCell = _styleTotalCell();
    final percentStyle = _stylePercentCell();
    final kpiStyle = _styleKpiCell();

    // Barra de título
    _setText(sh, 1, 0,
        'REPORTE DIARIO  •  $disenador  •  Día: ${_dfDia.format(dia)}',
        style: titleBar);

    // Encabezados
    _setText(sh, 1, 1, 'No.', style: header);
    _setText(sh, 2, 1, 'IMPRESIÓN/LASER', style: header);
    _setText(sh, 3, 1, 'SCANNER', style: header);
    _setText(sh, 4, 1, 'PLOTEO', style: header);
    _setText(sh, 5, 1, 'DISEÑO', style: header);

    // Cuadro 1..22
    for (int i = 1; i <= 22; i++) {
      final row = 1 + i; // 2..23
      _setInt(sh, 1, row, i, style: noStyle);

      _setNum(sh, 2, row, 0, style: _moneyStyleFor(0));
      _setNum(sh, 3, row, 0, style: _moneyStyleFor(0));
      _setNum(sh, 4, row, 0, style: _moneyStyleFor(0));
      _setNum(sh, 5, row, 0, style: _moneyStyleFor(0));
    }

    // Primera fila de datos (fila 3 -> rowIndex=2)
    _setNum(sh, 2, 2, tot.laser, style: _moneyStyleFor(tot.laser));
    _setNum(sh, 3, 2, tot.scanner, style: _moneyStyleFor(tot.scanner));
    _setNum(sh, 4, 2, tot.ploteo, style: _moneyStyleFor(tot.ploteo));
    _setNum(sh, 5, 2, tot.diseno, style: _moneyStyleFor(tot.diseno));

    final totalDia = tot.totalDia;

    // TOT (rowIndex=24)
    _setText(sh, 1, 24, 'TOT', style: labelBold);
    _setNum(sh, 2, 24, tot.laser, style: totalCell);
    _setNum(sh, 3, 24, tot.scanner, style: totalCell);
    _setNum(sh, 4, 24, tot.ploteo, style: totalCell);
    _setNum(sh, 5, 24, tot.diseno, style: totalCell);

    // % (rowIndex=25) como texto para no pelear con formatos internos del paquete
    _setText(sh, 1, 25, '%', style: labelBold);
    _setPercentAsText(sh, 2, 25, totalDia <= 0 ? 0 : (tot.laser / totalDia),
        style: percentStyle);
    _setPercentAsText(sh, 3, 25, totalDia <= 0 ? 0 : (tot.scanner / totalDia),
        style: percentStyle);
    _setPercentAsText(sh, 4, 25, totalDia <= 0 ? 0 : (tot.ploteo / totalDia),
        style: percentStyle);
    _setPercentAsText(sh, 5, 25, totalDia <= 0 ? 0 : (tot.diseno / totalDia),
        style: percentStyle);

    // DIA (rowIndex=27)
    _setText(sh, 1, 27, 'DÍA', style: labelBold);
    _setNum(sh, 2, 27, totalDia, style: kpiStyle);
  }

  // ==========================
  // Hoja: RESUMEN general
  // ==========================
  static void _buildHojaResumen({
    required Sheet sh,
    required DateTime dia,
    required Map<String, _ReporteTotales> totalesPorDisenador,
  }) {
    final header = _styleHeader();
    final titleBar = _styleTitleBar();
    final labelBold = _styleLabelBoldLeft();
    final totalCell = _styleTotalCell();
    final percentStyle = _stylePercentCell();
    final kpiStyle = _styleKpiCell();

    // Totales generales
    final totalGeneral = totalesPorDisenador.values.fold<_ReporteTotales>(
      const _ReporteTotales(laser: 0, ploteo: 0, diseno: 0, scanner: 0),
      (acc, t) => _ReporteTotales(
        laser: acc.laser + t.laser,
        ploteo: acc.ploteo + t.ploteo,
        diseno: acc.diseno + t.diseno,
        scanner: acc.scanner + t.scanner,
      ),
    );

    // Barra de título
    _setText(sh, 1, 0, 'RESUMEN  •  Día: ${_dfDia.format(dia)}',
        style: titleBar);

    // KPI Total día (general)
    _setText(sh, 1, 2, 'TOTAL DÍA (GENERAL)', style: labelBold);
    _setNum(sh, 2, 2, totalGeneral.totalDia, style: kpiStyle);

    // Bloque “Totales por categoría”
    _setText(sh, 1, 4, 'TOTALES POR CATEGORÍA', style: labelBold);

    _setText(sh, 1, 5, 'IMPRESIÓN/LASER', style: header);
    _setText(sh, 2, 5, 'SCANNER', style: header);
    _setText(sh, 3, 5, 'PLOTEO', style: header);
    _setText(sh, 4, 5, 'DISEÑO', style: header);
    _setText(sh, 5, 5, 'TOTAL', style: header);

    _setNum(sh, 1, 6, totalGeneral.laser,
        style: _moneyStyleFor(totalGeneral.laser));
    _setNum(sh, 2, 6, totalGeneral.scanner,
        style: _moneyStyleFor(totalGeneral.scanner));
    _setNum(sh, 3, 6, totalGeneral.ploteo,
        style: _moneyStyleFor(totalGeneral.ploteo));
    _setNum(sh, 4, 6, totalGeneral.diseno,
        style: _moneyStyleFor(totalGeneral.diseno));
    _setNum(sh, 5, 6, totalGeneral.totalDia, style: totalCell);

    // Porcentajes (texto)
    _setText(sh, 0, 7, '%', style: labelBold);
    final tg = totalGeneral.totalDia <= 0 ? 1.0 : totalGeneral.totalDia;
    _setPercentAsText(sh, 1, 7, totalGeneral.laser / tg, style: percentStyle);
    _setPercentAsText(sh, 2, 7, totalGeneral.scanner / tg, style: percentStyle);
    _setPercentAsText(sh, 3, 7, totalGeneral.ploteo / tg, style: percentStyle);
    _setPercentAsText(sh, 4, 7, totalGeneral.diseno / tg, style: percentStyle);
    _setText(sh, 5, 7, '100%', style: percentStyle);

    // Bloque “Totales por diseñador”
    _setText(sh, 1, 9, 'TOTALES POR DISEÑADOR', style: labelBold);

    _setText(sh, 0, 10, 'DISEÑADOR', style: header);
    _setText(sh, 1, 10, 'IMPRESIÓN/LASER', style: header);
    _setText(sh, 2, 10, 'SCANNER', style: header);
    _setText(sh, 3, 10, 'PLOTEO', style: header);
    _setText(sh, 4, 10, 'DISEÑO', style: header);
    _setText(sh, 5, 10, 'TOTAL', style: header);

    final disenadores = totalesPorDisenador.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    int row = 11;
    for (final d in disenadores) {
      final t = totalesPorDisenador[d]!;
      _setText(sh, 0, row, d, style: _styleNoCell());
      _setNum(sh, 1, row, t.laser, style: _moneyStyleFor(t.laser));
      _setNum(sh, 2, row, t.scanner, style: _moneyStyleFor(t.scanner));
      _setNum(sh, 3, row, t.ploteo, style: _moneyStyleFor(t.ploteo));
      _setNum(sh, 4, row, t.diseno, style: _moneyStyleFor(t.diseno));
      _setNum(sh, 5, row, t.totalDia, style: totalCell);
      row++;
    }
  }

  // ==========================
  // Export principal: Reporte diario + Resumen
  // ==========================
  static Future<void> exportarReporteDiarioExcel({
    required DateTime dia,
    required List<Orden> pagadosDelDia,
    required Future<List<OrdenItem>> Function(String ordenId) fetchItemsDeOrden,
  }) async {
    // Agrupar por diseñador
    final porDisenador = <String, List<Orden>>{};
    for (final o in pagadosDelDia) {
      final d =
          (o.disenador.trim().isEmpty) ? 'Sin diseñador' : o.disenador.trim();
      porDisenador.putIfAbsent(d, () => []);
      porDisenador[d]!.add(o);
    }

    final excel = Excel.createExcel();

    // Borrar hoja por defecto si existe
    if (excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Calculamos totales por diseñador (una sola pasada)
    final totalesPorDisenador = <String, _ReporteTotales>{};

    for (final entry in porDisenador.entries) {
      final disenador = entry.key;
      final ordenes = entry.value;

      double laser = 0, ploteo = 0, diseno = 0, scanner = 0;

      for (final o in ordenes) {
        final items = await fetchItemsDeOrden(o.id);
        final t = _calcTotalesDesdeItems(items);
        laser += t.laser;
        ploteo += t.ploteo;
        diseno += t.diseno;
        scanner += t.scanner;
      }

      totalesPorDisenador[disenador] = _ReporteTotales(
        laser: laser,
        ploteo: ploteo,
        diseno: diseno,
        scanner: scanner,
      );
    }

    // Hoja RESUMEN
    final resumen = excel['RESUMEN'];
    _buildHojaResumen(
      sh: resumen,
      dia: dia,
      totalesPorDisenador: totalesPorDisenador,
    );

    // Hojas por diseñador
    for (final entry in totalesPorDisenador.entries) {
      final disenador = entry.key;
      final tot = entry.value;

      final sheetName =
          disenador.length > 25 ? disenador.substring(0, 25) : disenador;
      final sh = excel[sheetName];

      _buildHojaReporteDiario(
        sh: sh,
        dia: dia,
        disenador: disenador,
        tot: tot,
      );
    }

    // Guardar bytes xlsx
    final Uint8List bytes = Uint8List.fromList(excel.encode() ?? []);
    final f = _dfFile.format(dia);

    await saveBytesFile(
      filename: 'reporte_diario_$f.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}

class _ReporteTotales {
  final double laser;
  final double ploteo;
  final double diseno;
  final double scanner;

  const _ReporteTotales({
    required this.laser,
    required this.ploteo,
    required this.diseno,
    required this.scanner,
  });

  double get totalDia => laser + ploteo + diseno + scanner;
}
