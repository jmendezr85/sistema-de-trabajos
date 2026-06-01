import 'dart:math';
import 'dart:developer' as developer;
import 'package:pocketbase/pocketbase.dart';
import '../models/orden_model.dart';
import '../models/orden_item_model.dart';

class PocketBaseService {
  /// Si estás en emulador Android cambia a: http://10.0.2.2:8090
  final pb = PocketBase('http://127.0.0.1:8090');

  // ====== CONFIG (según tu JS) ======
  static const double _valorMetroCuadradoPloteo = 25000;
  static const double _valorMinimoPloteo = 10000;

  static const double _vinilo = 13600;
  static const double _lona = 21700;
  static const double _fotografico = 13000;
  static const double _propalcote = 8000;
  static const double _pergamino = 6000;
  static const double _lienzoM2 = 83000;

  static const double _valorMetroTuboAluminio = 6200;

  static const double _valorMetroPloteoLienzo = 50000;
  static const double _valorMinimoPloteoLienzo = 12500;
  static const double _valorMinimoMaterialLienzo = 12500;

  static const double _medidaMinima = 20;

  static int _ceilTo1000(num v) => (v / 1000).ceil() * 1000;

  // ====== Date helpers (PB field type: date) ======
  static String _asPbDate(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  static String _todayAsPbDate() => _asPbDate(DateTime.now());

  // ====== Record -> Map plano para Orden.fromRecord ======
  Map<String, dynamic> _recordToMap(RecordModel r) {
    return {
      ...r.data,
      'id': r.id,
      'created': r.created,
      'updated': r.updated,
    };
  }

  // ====== Safe parse created ======
  DateTime _parseCreated(dynamic created) {
    if (created is DateTime) return created;
    if (created is String) return DateTime.tryParse(created) ?? DateTime(1970);
    return DateTime(1970);
  }

  // ====== Ticket / código ======
  Future<int> _siguienteTicketNo() async {
    try {
      final res = await pb.collection('ordenes').getList(
            page: 1,
            perPage: 500,
          );

      if (res.items.isEmpty) return 1;

      int maxTicket = 0;
      for (final it in res.items) {
        final v = it.data['ticket_no'];
        final n =
            (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
        if (n > maxTicket) maxTicket = n;
      }
      return maxTicket + 1;
    } catch (_) {
      return 1;
    }
  }

  String _codigoCobro() {
    final rnd = Random();
    final n = rnd.nextInt(900000) + 100000; // 6 dígitos
    return n.toString();
  }

  // ====== Cálculo Exterior (según tu JS) ======
  Map<String, num> calcularExterior({
    required double anchoCm,
    required double altoCm,
    required String material,
  }) {
    if (anchoCm < _medidaMinima || altoCm < _medidaMinima) {
      throw Exception('Ambas medidas deben ser mínimo $_medidaMinima cm');
    }

    final areaM2 = (anchoCm / 100.0) * (altoCm / 100.0);

    double precioPloteo = areaM2 * _valorMetroCuadradoPloteo;
    precioPloteo = _ceilTo1000(precioPloteo).toDouble();
    if (precioPloteo < _valorMinimoPloteo) precioPloteo = _valorMinimoPloteo;

    double anchoMaximo;
    if (material == 'Vinilo') {
      anchoMaximo = 130;
    } else if (material == 'Lona') {
      anchoMaximo = 130;
    } else if (material == 'Fotográfico') {
      anchoMaximo = 70;
    } else if (material == 'Propalcote') {
      anchoMaximo = 130;
    } else if (material == 'Pergamino') {
      anchoMaximo = 90;
    } else if (material == 'Lienzo') {
      anchoMaximo = 125;
    } else if (material == 'Pendón') {
      anchoMaximo = 130;
    } else {
      anchoMaximo = 130;
    }

    if (anchoCm > anchoMaximo) {
      throw Exception(
          'El ancho excede el máximo permitido para $material: $anchoMaximo cm');
    }

    double valorMetroLineal;
    if (material == 'Vinilo') {
      valorMetroLineal = _vinilo;
    } else if (material == 'Lona') {
      valorMetroLineal = _lona;
    } else if (material == 'Fotográfico') {
      valorMetroLineal = _fotografico;
    } else if (material == 'Propalcote') {
      valorMetroLineal = _propalcote;
    } else if (material == 'Pergamino') {
      valorMetroLineal = _pergamino;
    } else if (material == 'Lienzo') {
      valorMetroLineal = _lienzoM2;
    } else if (material == 'Pendón') {
      valorMetroLineal = _lona;
    } else {
      valorMetroLineal = _lona;
    }

    // LIENZO (regla especial)
    if (material == 'Lienzo') {
      double pPloteoLienzo = (areaM2 * _valorMetroPloteoLienzo);
      pPloteoLienzo = ((pPloteoLienzo / 1000).round() * 1000).toDouble();
      if (pPloteoLienzo < _valorMinimoPloteoLienzo) {
        pPloteoLienzo = _valorMinimoPloteoLienzo;
      }

      double pMaterialLienzo =
          ((anchoCm + 10) / 100.0) * ((altoCm + 10) / 100.0) * _lienzoM2;
      pMaterialLienzo = _ceilTo1000(pMaterialLienzo).toDouble();
      if (pMaterialLienzo < _valorMinimoMaterialLienzo) {
        pMaterialLienzo = _valorMinimoMaterialLienzo;
      }

      final total = pMaterialLienzo + pPloteoLienzo;

      return {
        'costo_material': pMaterialLienzo,
        'costo_ploteo': pPloteoLienzo,
        'costo_extras': 0,
        'total': total,
      };
    }

    // Materiales normales (metro lineal)
    double base;
    if (anchoCm > anchoMaximo) {
      base = (anchoCm / 100.0) * valorMetroLineal;
    } else if (altoCm > anchoMaximo) {
      base = (altoCm / 100.0) * valorMetroLineal;
    } else if (anchoCm < altoCm) {
      base = (anchoCm / 100.0) * valorMetroLineal;
    } else {
      base = (altoCm / 100.0) * valorMetroLineal;
    }

    final double precioMaterial = _ceilTo1000(base).toDouble();

    double valorTubos = 0;
    if (material == 'Pendón') {
      valorTubos = _ceilTo1000((anchoCm / 100.0) * _valorMetroTuboAluminio * 2)
          .toDouble();
    }

    final total = precioMaterial + precioPloteo + valorTubos;

    return {
      'costo_material': precioMaterial,
      'costo_ploteo': precioPloteo,
      'costo_extras': valorTubos,
      'total': total,
    };
  }

  // ====== Crear Orden ======
  Future<void> crearOrden({
    required String cliente,
    required List<String> tipoTrabajo, // MULTI
    required String disenador,
    required String materiales,
    double costoExtras = 0, // extras manual
    double abono = 0, // abono

    double? anchoCm,
    double? altoCm,
    String? material,
    String? ploteoTipo,
    double? valorPloteoManual,
    String? extrasDetalle,
  }) async {
    final ticketNo = await _siguienteTicketNo();
    final codigo = _codigoCobro();

    double costoMaterial = 0;
    double costoPloteo = 0;
    double costoExtrasFinal = costoExtras;

    final incluyeExterior = tipoTrabajo.contains('Ploteo Exterior');
    final incluyeInterior = tipoTrabajo.contains('Ploteo Interior');

    if (incluyeExterior) {
      if (anchoCm == null || altoCm == null || material == null) {
        throw Exception('Faltan medidas/material para Ploteo Exterior');
      }

      final calc = calcularExterior(
        anchoCm: anchoCm,
        altoCm: altoCm,
        material: material,
      );

      costoMaterial = (calc['costo_material'] ?? 0).toDouble();
      costoPloteo = (calc['costo_ploteo'] ?? 0).toDouble();
      costoExtrasFinal += (calc['costo_extras'] ?? 0).toDouble();
      ploteoTipo = 'Exterior';
    }

    if (incluyeInterior) {
      if (valorPloteoManual == null || valorPloteoManual <= 0) {
        throw Exception('Ingresa el valor total manual del Ploteo Interior');
      }
      costoPloteo += valorPloteoManual;
      ploteoTipo = 'Interior';
    }

    final total = costoMaterial + costoPloteo + costoExtrasFinal;

    final body = <String, dynamic>{
      'cliente': cliente,
      'Tipo_de_trabajo': tipoTrabajo,
      'Monto': total,
      'abono': abono,
      'Estado': 'Pendiente',
      'disenador': disenador,
      'materiales': materiales,
      'ticket_no': ticketNo,
      'codigo_cobro': codigo,
      'pagado_en': null,
      'ancho_cm': anchoCm,
      'alto_cm': altoCm,
      'material': material,
      'ploteo_tipo': ploteoTipo,
      'valor_ploteo_manual': valorPloteoManual,
      'costo_material': costoMaterial,
      'costo_ploteo': costoPloteo,
      'costo_extras': costoExtrasFinal,
      'extras_detalle': extrasDetalle ?? '',
    };

    await pb.collection('ordenes').create(body: body);
  }

  // ====== ORDEN ITEMS (Detalle) ======
  Future<void> crearOrdenItems({
    required String ordenId,
    required List<OrdenItem> items,
  }) async {
    for (final it in items) {
      final body = OrdenItem(
        ordenId: ordenId,
        seccion: it.seccion,
        descripcion: it.descripcion,
        cantidad: it.cantidad,
        precioUnitario: it.precioUnitario,
        subtotal: it.subtotal,
        costoLaser: it.costoLaser,
        costoMaterial: it.costoMaterial,
        meta: it.meta,
      ).toCreateBody();

      await pb.collection('orden_items').create(body: body);
    }
  }

  Future<List<OrdenItem>> obtenerItemsDeOrden(String ordenId) async {
    final res = await pb.collection('orden_items').getList(
          page: 1,
          perPage: 500,
          filter: "orden='$ordenId'",
        );

    final items =
        res.items.map((r) => OrdenItem.fromRecord(_recordToMap(r))).toList();

    items.sort((a, b) {
      final ra = res.items.firstWhere((x) => x.id == a.id);
      final rb = res.items.firstWhere((x) => x.id == b.id);
      final da = _parseCreated(ra.created);
      final db = _parseCreated(rb.created);
      return da.compareTo(db);
    });

    return items;
  }

  Future<void> eliminarItem(String itemId) async {
    await pb.collection('orden_items').delete(itemId);
  }

  Future<Orden> crearOrdenV2ConItems({
    required String cliente,
    required String disenador,
    required List<OrdenItem> itemsSinOrdenId,
    String materiales = '',
    List<String> tipoTrabajo = const [],
    double abono = 0,
  }) async {
    final ticketNo = await _siguienteTicketNo();
    final codigo = _codigoCobro();

    double total = 0;
    double costoLaser = 0;
    double costoMaterial = 0;

    for (final it in itemsSinOrdenId) {
      total += it.subtotal;
      costoLaser += it.costoLaser;
      costoMaterial += it.costoMaterial;
    }

    final bodyOrden = <String, dynamic>{
      'cliente': cliente,
      'disenador': disenador,
      'Estado': 'Pendiente',
      'Monto': total,
      'abono': abono,
      'ticket_no': ticketNo,
      'codigo_cobro': codigo,
      'pagado_en': null,
      'Tipo_de_trabajo': tipoTrabajo,
      'materiales': materiales,
      'costo_material': costoMaterial,
      'costo_ploteo': costoLaser,
      'costo_extras': 0,
      'extras_detalle': '',
    };

    final created = await pb.collection('ordenes').create(body: bodyOrden);
    final ordenId = created.id;

    await crearOrdenItems(
      ordenId: ordenId,
      items: itemsSinOrdenId
          .map((it) => OrdenItem(
                ordenId: ordenId,
                seccion: it.seccion,
                descripcion: it.descripcion,
                cantidad: it.cantidad,
                precioUnitario: it.precioUnitario,
                subtotal: it.subtotal,
                costoLaser: it.costoLaser,
                costoMaterial: it.costoMaterial,
                meta: it.meta,
              ))
          .toList(),
    );

    return Orden.fromRecord(_recordToMap(created));
  }

  Future<List<Orden>> obtenerOrdenesPendientes() async {
    final res = await pb.collection('ordenes').getList(
          page: 1,
          perPage: 500,
          filter: "Estado='Pendiente'",
        );

    final ordenes =
        res.items.map((r) => Orden.fromRecord(_recordToMap(r))).toList();

    ordenes.sort((a, b) {
      final da = _parseCreated(a.created);
      final db = _parseCreated(b.created);
      return db.compareTo(da);
    });

    return ordenes;
  }

  Future<List<Orden>> obtenerOrdenesPagadasDelDiaFiltrado({
    required DateTime dia,
    String disenador = 'Todos',
  }) async {
    final fechaFormateada = _asPbDate(dia);

    var filter = "Estado='Pagado' && pagado_en ~ '$fechaFormateada'";

    if (disenador != 'Todos') {
      final safe = disenador.replaceAll("'", r"\'");
      filter = "($filter) && disenador='$safe'";
    }

    final res = await pb.collection('ordenes').getList(
          page: 1,
          perPage: 500,
          filter: filter,
        );

    final ordenes =
        res.items.map((r) => Orden.fromRecord(_recordToMap(r))).toList();

    ordenes.sort((a, b) {
      final pa = (a.pagadoEn ?? '').toString();
      final pb2 = (b.pagadoEn ?? '').toString();
      final cmp = pb2.compareTo(pa);
      if (cmp != 0) return cmp;

      final da = _parseCreated(a.created);
      final db = _parseCreated(b.created);
      return db.compareTo(da);
    });

    return ordenes;
  }

  Future<void> marcarComoPagada(String idOrden) async {
    await pb.collection('ordenes').update(idOrden, body: {
      'Estado': 'Pagado',
      'pagado_en': '${_todayAsPbDate()} 12:00:00.000Z',
    });
  }

  Future<void> marcarComoPendiente(String idOrden) async {
    await pb.collection('ordenes').update(idOrden, body: {
      'Estado': 'Pendiente',
      'pagado_en': null,
    });
  }

  Future<void> eliminarOrden(String idOrden) async {
    await pb.collection('ordenes').delete(idOrden);
  }

  // 🌟 CONEXIÓN FIEL: Enviamos 'Archivado' con mayúscula exacta para cumplir el esquema Web
  Future<void> archivarOrdenesConCierre(List<Orden> ordenesCierre) async {
    for (final orden in ordenesCierre) {
      await pb.collection('ordenes').update(orden.id, body: {
        'Estado': 'Archivado',
      });
    }
  }

  Future<void> cerrarCaja() async {
    return;
  }

  // ====== AUTENTICACIÓN ======
  Future<bool> iniciarSesion(String email, String password) async {
    try {
      final authData = await pb.collection('users').authWithPassword(
            email,
            password,
          );
      return authData.record != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> obtenerUsuarioActual() async {
    try {
      if (!pb.authStore.isValid) {
        throw Exception('No authenticated');
      }

      final model = pb.authStore.model;
      final roleValue = model?.getStringValue('rol') ?? 'cajero';
      
      developer.log('PocketBase Model ID: ${model?.id}');
      developer.log('PocketBase Email: ${model?.getStringValue('email')}');
      developer.log('PocketBase Role: $roleValue');
      developer.log('PocketBase All Data: ${model?.data}');
      
      return {
        'id': model?.id ?? '',
        'email': model?.getStringValue('email') ?? '',
        'role': roleValue,
        'username': model?.getStringValue('username') ?? '',
      };
    } catch (e) {
      developer.log('Error en obtenerUsuarioActual: $e');
      throw Exception('Error obteniendo usuario actual');
    }
  }

  void cerrarSesion() {
    pb.authStore.clear();
  }

  bool obtenerAutenticado() => pb.authStore.isValid;

  Future<List<Orden>> obtenerTodasLasOrdenes() async {
    try {
      final res = await pb.collection('ordenes').getList(
            page: 1,
            perPage: 1000,
          );

      final ordenes =
          res.items.map((r) => Orden.fromRecord(_recordToMap(r))).toList();

      ordenes.sort((a, b) {
        final da = _parseCreated(a.created);
        final db = _parseCreated(b.created);
        return db.compareTo(da);
      });

      return ordenes;
    } catch (_) {
      return [];
    }
  }
}
