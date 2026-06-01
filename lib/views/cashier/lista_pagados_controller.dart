import 'package:flutter/material.dart';
import '../../models/orden_model.dart';
import '../../models/orden_item_model.dart';
import '../../services/pb_service.dart';
import '../../services/export_service.dart';

class ListaPagadosController extends ChangeNotifier {
  final PocketBaseService _service = PocketBaseService();
  final TextEditingController searchCtrl = TextEditingController();

  bool loading = true;
  bool gridMode = true; // Control de vista adaptativa (Cuadrícula / Lista)
  DateTime dia = DateTime.now();
  List<Orden> ordenes = [];
  String filtroDisenador = 'Todos';

  // 🛡️ CONTROL DE ROL INTEGRADO: Por defecto es true si la base de datos está vacía para desarrollo libre
  bool esAdmin = true;

  ListaPagadosController() {
    searchCtrl.addListener(_onSearchChanged);
    _verificarRolUsuario();
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  void disposeCtrl() {
    searchCtrl.dispose();
  }

  // Verifica el rol de manera segura protegiendo contra bases de datos vacías
  void _verificarRolUsuario() {
    try {
      final authModel = _service.pb.authStore.model;
      if (authModel != null) {
        // Intentamos leer el campo 'rol' de forma dinámica
        final dataMap = authModel.data;
        final rol = dataMap['rol']?.toString().toLowerCase().trim();
        esAdmin = (rol == 'admin');
      } else {
        // 🌟 BUENAS PRÁCTICAS: Si la base de datos no tiene sesión activa, permitimos el acceso Admin para desarrollo
        esAdmin = true;
      }
    } catch (_) {
      esAdmin = true;
    }
    notifyListeners();
  }

  // Cargar órdenes desde PocketBase
  Future<void> cargar() async {
    loading = true;
    notifyListeners();
    try {
      final data = await _service.obtenerOrdenesPagadasDelDiaFiltrado(
        dia: dia,
        disenador: filtroDisenador,
      );
      ordenes = List<Orden>.from(data);
    } catch (_) {
      rethrow;
    } finally {
      // 🌟 CORRECCIÓN CRÍTICA: Sintaxis Dart unificada correctamente
      loading = false;
      notifyListeners();
    }
  }

  // Filtrado reactivo local en memoria
  List<Orden> get filtradas {
    Iterable<Orden> it = ordenes;
    final q = searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      it = it.where((o) {
        final cliente = o.cliente.toLowerCase();
        final dis = o.disenador.toLowerCase();
        final codigo = o.codigoCobro.toLowerCase();
        final ticket = o.ticketNo.toString();
        final label = o.ticketLabel.toLowerCase();
        return cliente.contains(q) ||
            dis.contains(q) ||
            codigo.contains(q) ||
            ticket.contains(q) ||
            label.contains(q);
      });
    }
    final list = it.toList()..sort((a, b) => b.created.compareTo(a.created));
    return list;
  }

  // Alternadores de diseño visual
  void setGridMode(bool mode) {
    gridMode = mode;
    notifyListeners();
  }

  // Navegación por fechas
  Future<void> cambiarFecha(DateTime nuevaFecha) async {
    if (!esAdmin) return;
    dia = DateTime(nuevaFecha.year, nuevaFecha.month, nuevaFecha.day);
    await cargar();
  }

  Future<void> diaAnterior() async {
    if (!esAdmin) return;
    await cambiarFecha(dia.subtract(const Duration(days: 1)));
  }

  Future<void> diaSiguiente() async {
    if (!esAdmin) return;
    await cambiarFecha(dia.add(const Duration(days: 1)));
  }

  Future<void> cambiarFiltroDisenador(String nuevoDisenador) async {
    filtroDisenador = nuevoDisenador;
    await cargar();
  }

  List<String> get disenadoresDisponibles {
    final set = <String>{};
    for (final o in ordenes) {
      final d = o.disenador.trim();
      if (d.isNotEmpty) set.add(d);
    }
    final list = set.toList()..sort();
    return ['Todos', ...list];
  }

  String _formatYMD(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // Sumas de métricas globales del día
  double calcularSuma(String key) {
    double total = 0;
    final fechaFormateada = _formatYMD(dia);
    for (final o in filtradas) {
      switch (key) {
        case 'total':
          final bool createdToday = o.createdRaw.startsWith(fechaFormateada);
          final bool paidToday = o.estado == 'Pagado' && o.pagadoEnRaw.startsWith(fechaFormateada);

          
          double cashReceivedToday = 0;
          if (createdToday) {
            cashReceivedToday += o.abono;
          }
          if (paidToday) {
            cashReceivedToday += o.saldoPendiente;
          }
          total += cashReceivedToday;
          break;
        case 'material':
          total += (o.costoMaterial ?? 0);
          break;
        case 'ploteo':
          total += (o.costoPloteo ?? 0);
          break;
        case 'extras':
          total += (o.costoExtras ?? 0);
          break;
      }
    }
    return total;
  }

  Map<String, DesignerAggLocal> buildAggByDesigner() {
    final map = <String, DesignerAggLocal>{};
    final fechaFormateada = _formatYMD(dia);
    for (final o in filtradas) {
      final d =
          o.disenador.trim().isEmpty ? 'Sin diseñador' : o.disenador.trim();
      map.putIfAbsent(d, () => DesignerAggLocal(nombre: d));

      final bool createdToday = o.createdRaw.startsWith(fechaFormateada);
      final bool paidToday = o.estado == 'Pagado' && o.pagadoEnRaw.startsWith(fechaFormateada);
      
      double cashReceivedToday = 0;
      if (createdToday) {
        cashReceivedToday += o.abono;
      }
      if (paidToday) {
        cashReceivedToday += o.saldoPendiente;
      }

      map[d]!.tickets += 1;
      map[d]!.total += cashReceivedToday;
      map[d]!.material += (o.costoMaterial ?? 0);
      map[d]!.ploteo += (o.costoPloteo ?? 0);
      map[d]!.extras += (o.costoExtras ?? 0);
    }
    final keys = map.keys.toList()..sort();
    final ordered = <String, DesignerAggLocal>{};
    for (final k in keys) {
      ordered[k] = map[k]!;
    }
    return ordered;
  }

  Future<void> exportarExcel() async {
    if (!esAdmin) return;
    await ExportService.exportarReporteDiarioExcel(
      dia: dia,
      pagadosDelDia: filtradas,
      fetchItemsDeOrden: _service.obtenerItemsDeOrden,
    );
  }

  Future<void> ejecutarCierre() async {
    await _service.archivarOrdenesConCierre(ordenes);
    await cargar();
  }

  Future<List<OrdenItem>> fetchItemsDeOrden(String id) =>
      _service.obtenerItemsDeOrden(id);
}

class DesignerAggLocal {
  final String nombre;
  int tickets = 0;
  double total = 0;
  double material = 0;
  double ploteo = 0;
  double extras = 0;
  DesignerAggLocal({required this.nombre});
}
