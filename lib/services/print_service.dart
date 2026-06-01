import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../models/orden_model.dart';
import '../models/orden_item_model.dart';
import '../utils/print_helper.dart';

class PrintService {
  /// IMPORTANTÍSIMO:
  /// Pon aquí el nombre EXACTO como aparece en:
  /// Panel de control > Dispositivos e impresoras
  static String printerName = 'XP-58 (copy 1)';

  /// ✅ Switch global para mostrar/ocultar la sección debajo de cada item.
  static bool imprimirSeccionEnItems = false;

  static Future<void> imprimirOrden({
    required Orden orden,
    required List<OrdenItem> items,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm58, profile);

    final now = DateTime.now();
    final fecha =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final List<int> bytes = [];

    // ===== Header =====
    bytes.addAll(gen.text(
      'SISTEMA TRABAJOS',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    ));

    bytes.addAll(gen.text(
      'Ticket: ${orden.ticketLabel}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));

    bytes.addAll(gen.text(
      'Cod: ${orden.codigoCobro}',
      styles: const PosStyles(align: PosAlign.center),
      linesAfter: 1,
    ));

    bytes.addAll(gen.text('Fecha: $fecha'));
    bytes.addAll(gen.text('Cliente: ${orden.cliente}'));
    bytes.addAll(gen.text('Atiende: ${orden.disenador}'));
    bytes.addAll(gen.hr());

    // ===== Items =====
    if (items.isEmpty) {
      bytes.addAll(gen.text('(Sin items)'));
    } else {
      // 1. Agrupar los items idénticos
      final map = <String, Map<String, dynamic>>{};

      for (final it in items) {
        final key = '${it.seccion}__${it.descripcion}__${it.precioUnitario}';

        if (!map.containsKey(key)) {
          map[key] = {
            'desc': it.descripcion.trim(),
            'seccion': it.seccion,
            'qty': it.cantidad,
            'subtotal': it.subtotal,
            'costoLaser': it.costoLaser,
            'costoMaterial': it.costoMaterial,
            'meta': it.meta,
          };
        } else {
          map[key]!['qty'] = (map[key]!['qty'] as int) + it.cantidad;
          map[key]!['subtotal'] =
              (map[key]!['subtotal'] as double) + it.subtotal;
          map[key]!['costoLaser'] =
              (map[key]!['costoLaser'] as double) + it.costoLaser;
          map[key]!['costoMaterial'] =
              (map[key]!['costoMaterial'] as double) + it.costoMaterial;
        }
      }

      // 🏆 CALCULADORA GLOBAL PARA EL RESUMEN DE CONCEPTOS
      final resumenTotal = <String, double>{};

      // 2. Imprimir los items ya agrupados con desglose inteligente
      for (final groupedItem in map.values) {
        final desc = groupedItem['desc'] as String;
        final qty = groupedItem['qty'] as int;
        final subtotal = groupedItem['subtotal'] as double;
        final seccion = groupedItem['seccion'] as String;
        final costoLaser = groupedItem['costoLaser'] as double;
        final costoMaterial = groupedItem['costoMaterial'] as double;
        final meta = groupedItem['meta'] as Map<String, dynamic>? ?? {};

        // Renombramos visualmente Ploteo exterior/interior
        String descImpreso = desc
            .replaceAll(
                RegExp(r'Ploteo exterior', caseSensitive: false), 'Ploteo Ext')
            .replaceAll(
                RegExp(r'Ploteo interior', caseSensitive: false), 'Ploteo Int');

        // LÓGICA DE TÍTULO PARA EL ITEM
        if (seccion == 'diseno_corte') {
          bytes.addAll(gen.text(
            'Servicio Personalizado x$qty',
            styles: const PosStyles(bold: true),
          ));
        } else {
          bytes.addAll(gen.text(
            '$descImpreso x$qty',
            styles: const PosStyles(bold: true),
          ));
        }

        // CALCULADORA DE DESGLOSE POR SECCIÓN
        List<Map<String, dynamic>> desglose = [];

        if (seccion == 'laser_propalcote_opalina') {
          final tipoPapel = desc.toLowerCase().contains('propalcote')
              ? 'Propalcote'
              : 'Opalina';

          if (costoMaterial > 0) {
            desglose.add({'lbl': 'Papel $tipoPapel', 'val': costoMaterial});
          }

          bool tieneCorte = meta['corte'] == true;
          double valorCorte = 0;
          double valorLaser = costoLaser;

          if (tieneCorte) {
            valorCorte = 6000.0 * qty;
            valorLaser = costoLaser - valorCorte;
          }

          if (valorLaser > 0) {
            desglose.add({'lbl': 'Imp. Láser', 'val': valorLaser});
          }
          if (valorCorte > 0) {
            desglose.add({'lbl': 'Corte', 'val': valorCorte});
          }
        } else if (seccion == 'laser_bond') {
          // --- CAMBIO AQUÍ: En el desglose del ticket dice Impresión Bond para claridad del cliente ---
          desglose.add({'lbl': 'Impresión Bond', 'val': subtotal});
        } else if (seccion == 'ploteo_exterior') {
          if (meta['tipo'] == 'vinilo_corte') {
            if (costoMaterial > 0) {
              desglose.add({'lbl': 'Vinilo', 'val': costoMaterial});
            }
            if (costoLaser > 0) {
              desglose.add({'lbl': 'Corte', 'val': costoLaser});
            }
            final ploteo = subtotal - costoMaterial - costoLaser;
            if (ploteo > 0) {
              desglose.add({'lbl': 'Ploteo Ext', 'val': ploteo});
            }
          } else {
            String nombreMaterial = meta['material']?.toString() ?? 'Material';

            if (nombreMaterial == 'Pendón') {
              nombreMaterial = 'Lona';
            }

            if (costoMaterial > 0) {
              desglose.add({'lbl': nombreMaterial, 'val': costoMaterial});
            }

            final costoPerfiles = (meta['costo_extras'] ?? 0).toDouble() * qty;
            if (costoPerfiles > 0) {
              desglose.add({'lbl': 'Perfiles', 'val': costoPerfiles});
            }

            final costoOjaletes =
                (meta['costo_ojaletes'] ?? 0).toDouble() * qty;
            if (costoOjaletes > 0) {
              desglose.add({'lbl': 'Ojaletes', 'val': costoOjaletes});
            }

            final costoIva = (meta['costo_iva'] ?? 0).toDouble() * qty;
            if (costoIva > 0) {
              desglose.add({'lbl': 'IVA 19%', 'val': costoIva});
            }

            final ploteo = subtotal -
                costoMaterial -
                costoPerfiles -
                costoOjaletes -
                costoIva;
            if (ploteo > 0) {
              desglose.add({'lbl': 'Ploteo Ext', 'val': ploteo});
            }
          }
        } else if (seccion == 'ploteo_interior') {
          final ploteoBase = subtotal - costoMaterial;
          if (ploteoBase > 0) {
            desglose.add({'lbl': 'Ploteo Int', 'val': ploteoBase});
          }
          if (costoMaterial > 0) {
            String extraName = meta['extra_key']?.toString() ?? 'Adicional';
            if (extraName == 'Ninguno') {
              extraName = 'Material Adicional';
            }
            desglose.add({'lbl': extraName, 'val': costoMaterial});
          }
        } else if (seccion == 'diseno_corte') {
          desglose.add({'lbl': desc, 'val': subtotal});
        } else {
          desglose.add({'lbl': 'Valor', 'val': subtotal});
        }

        // IMPRIMIR EL DESGLOSE EN EL TICKET Y SUMARLO AL RESUMEN
        for (final d in desglose) {
          String lbl = d['lbl'] as String;
          final val = d['val'] as double;

          // 🌟 REGLA MAESTRA DE UNIFICACIÓN:
          // Si el concepto es "Impresión Bond", en la alcancía del RESUMEN se sumará a "Imp. Láser"
          if (lbl == 'Impresión Bond') {
            lbl = 'Imp. Láser';
          }

          resumenTotal[lbl] = (resumenTotal[lbl] ?? 0) + val;

          bytes.addAll(gen.row([
            PosColumn(
                text: '  > ${d['lbl']}:',
                width: 8,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: _money(val),
                width: 4,
                styles: const PosStyles(align: PosAlign.right)),
          ]));
        }

        if (imprimirSeccionEnItems && seccion.trim().isNotEmpty) {
          bytes.addAll(gen.text(
            '  ${_prettySeccion(seccion)}',
            styles: const PosStyles(align: PosAlign.left),
          ));
        }
      }

      bytes.addAll(gen.hr());

      // ===== RESUMEN DE CONCEPTOS ANTES DEL TOTAL =====
      if (resumenTotal.isNotEmpty) {
        bytes.addAll(gen.text(
          'RESUMEN DE CONCEPTOS',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ));

        final llavesOrdenadas = resumenTotal.keys.toList()..sort();

        for (final key in llavesOrdenadas) {
          bytes.addAll(gen.row([
            PosColumn(
                text: key,
                width: 8,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: _money(resumenTotal[key]!),
                width: 4,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]));
        }
        bytes.addAll(gen.hr());
      }
    }

    // ===== Total Final =====
    bytes.addAll(gen.row([
      PosColumn(
          text: 'TOTAL ORDEN', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: _money(orden.monto),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));

    // ===== Abono y Saldo si hay pago parcial =====
    if (orden.abono > 0) {
      bytes.addAll(gen.hr());
      bytes.addAll(gen.row([
        PosColumn(
            text: 'ABONO', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _money(orden.abono),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]));

      bytes.addAll(gen.row([
        PosColumn(
            text: 'SALDO', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _money(orden.saldoPendiente),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]));
    }

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    await sendRawToPrinter(
      printerName: printerName,
      bytes: Uint8List.fromList(bytes),
      docName: 'Ticket ${orden.ticketLabel}',
    );
  }

  static String _money(num v) {
    final n = v.toDouble();
    return '\$${n.toStringAsFixed(0)}';
  }

  static String _prettySeccion(String s) {
    switch (s) {
      case 'laser_bond':
        return 'Laser Bond';
      case 'laser_propalcote_opalina':
        return 'Laser Propalcote/Opalina';
      case 'diseno_corte':
        return 'Diseno/Corte';
      case 'ploteo_interior':
        return 'Ploteo Interior';
      case 'ploteo_exterior':
        return 'Ploteo Exterior';
      default:
        return s.replaceAll('_', ' ');
    }
  }
}
