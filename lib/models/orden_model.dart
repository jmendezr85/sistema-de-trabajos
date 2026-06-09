class Orden {
  final String id;

  final String cliente;
  final List<String> tipoTrabajo; // MULTI
  final double monto; // TOTAL (Monto)
  final double abono;

  double get saldoPendiente => monto - abono;

  final String estado;
  final String disenador;
  final String materiales;
  final String? whatsappCliente; // WhatsApp del cliente (sin +57)
  final String estadoDiseno; // Estado del flujo de diseño: Asignado, En Proceso, Completado

  final int ticketNo;
  final String codigoCobro;
  final DateTime? pagadoEn;

  final double? anchoCm;
  final double? altoCm;
  final String? material;
  final String? ploteoTipo; // Interior / Exterior

  final double? valorPloteoManual; // total manual interior

  final double? costoMaterial;
  final double? costoPloteo;
  final double? costoExtras;
  final String? extrasDetalle;

  final DateTime created;
  final String pagadoEnRaw;
  final String createdRaw;

  Orden({
    required this.id,
    required this.cliente,
    required this.tipoTrabajo,
    required this.monto,
    required this.abono,
    required this.estado,
    required this.disenador,
    required this.materiales,
    this.whatsappCliente,
    this.estadoDiseno = '',
    required this.ticketNo,
    required this.codigoCobro,
    required this.pagadoEn,
    required this.anchoCm,
    required this.altoCm,
    required this.material,
    required this.ploteoTipo,
    required this.valorPloteoManual,
    required this.costoMaterial,
    required this.costoPloteo,
    required this.costoExtras,
    required this.extrasDetalle,
    required this.created,
    required this.pagadoEnRaw,
    required this.createdRaw,
  });

  String get ticketLabel => 'OT #${ticketNo.toString().padLeft(5, '0')}';

  factory Orden.fromRecord(Map<String, dynamic> record) {
    List<String> parseTipoTrabajo(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.trim().isNotEmpty) return [v.trim()];
      return [];
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return double.tryParse(s);
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime safeDate(dynamic v) {
      final s = (v ?? '').toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? safeDateNullable(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return Orden(
      id: record['id'] ?? '',
      cliente: record['cliente'] ?? 'Sin nombre',
      tipoTrabajo: parseTipoTrabajo(record['Tipo_de_trabajo']),
      monto: (record['Monto'] as num?)?.toDouble() ?? 0.0,
      abono: (record['abono'] as num?)?.toDouble() ?? 0.0,
      estado: record['Estado'] ?? 'Pendiente',
      disenador: record['disenador'] ?? '',
      materiales: record['materiales'] ?? '',
      whatsappCliente: (record['whatsapp_cliente'] ?? '').toString().isEmpty
          ? null
          : record['whatsapp_cliente'].toString(),
      estadoDiseno: record['estado_diseno'] ?? '',
      ticketNo: parseInt(record['ticket_no']),
      codigoCobro: record['codigo_cobro'] ?? '',
      pagadoEn: safeDateNullable(record['pagado_en']),
      anchoCm: parseDouble(record['ancho_cm']),
      altoCm: parseDouble(record['alto_cm']),
      material: (record['material'] ?? '').toString().isEmpty
          ? null
          : record['material'].toString(),
      ploteoTipo: (record['ploteo_tipo'] ?? '').toString().isEmpty
          ? null
          : record['ploteo_tipo'].toString(),
      valorPloteoManual: parseDouble(record['valor_ploteo_manual']),
      costoMaterial: parseDouble(record['costo_material']),
      costoPloteo: parseDouble(record['costo_ploteo']),
      costoExtras: parseDouble(record['costo_extras']),
      extrasDetalle: (record['extras_detalle'] ?? '').toString().isEmpty
          ? null
          : record['extras_detalle'].toString(),
      created: safeDate(record['created']),
      pagadoEnRaw: (record['pagado_en'] ?? '').toString(),
      createdRaw: (record['created'] ?? '').toString(),
    );
  }
}
