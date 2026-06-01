import 'package:flutter/material.dart';
import '../../models/orden_model.dart';
import '../../services/pb_service.dart';
import 'ticket_card.dart';
import 'lista_pagados_view.dart';
import '../designer/formulario_pos_view.dart';
import '../shared/home_view.dart';

class ListaPendientesView extends StatefulWidget {
  const ListaPendientesView({super.key});

  @override
  State<ListaPendientesView> createState() => _ListaPendientesViewState();
}

class _ListaPendientesViewState extends State<ListaPendientesView> {
  final _service = PocketBaseService();

  final _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _gridMode = true;

  List<Orden> _ordenes = [];
  String _filtroDisenador = 'Todos';
  String _sortMode = 'Recientes';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await _service.obtenerOrdenesPendientes();
      setState(() => _ordenes = data);
    } catch (e) {
      _snack('Error cargando: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroDisenador = 'Todos';
      _sortMode = 'Recientes';
      _searchCtrl.clear();
    });
  }

  List<String> get _disenadoresDisponibles {
    final set = <String>{};
    for (final o in _ordenes) {
      final d = o.disenador.trim();
      if (d.isNotEmpty) set.add(d);
    }
    final list = set.toList()..sort();
    return ['Todos', ...list];
  }

  /// Búsqueda robusta:
  /// - OT 4, 0004, #4, OT #0004, etc.
  /// - código, cliente, diseñador, label
  bool _matchQuery(Orden o, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return true;

    final cliente = o.cliente.toLowerCase();
    final dis = o.disenador.toLowerCase();
    final codigo = o.codigoCobro.toLowerCase();
    final ticket = o.ticketNo.toString();
    final label = o.ticketLabel.toLowerCase();

    // Si parece un query de OT (ej: "ot 0004", "#4", "0004")
    final cleaned = query
        .replaceAll('ot', '')
        .replaceAll('#', '')
        .replaceAll(' ', '')
        .trim();

    final maybeOt = int.tryParse(cleaned);
    if (maybeOt != null) {
      // match exact o contains (por si escriben 4 y el ticket es 00004)
      return o.ticketNo == maybeOt ||
          ticket.contains(cleaned) ||
          label.contains(cleaned);
    }

    return cliente.contains(query) ||
        dis.contains(query) ||
        codigo.contains(query) ||
        ticket.contains(query) ||
        label.contains(query);
  }

  List<Orden> get _filtradas {
    Iterable<Orden> it = _ordenes;

    // 1) Filtro por diseñador
    if (_filtroDisenador != 'Todos') {
      it = it.where((o) => o.disenador == _filtroDisenador);
    }

    // 2) Búsqueda
    final q = _searchCtrl.text;
    if (q.trim().isNotEmpty) {
      it = it.where((o) => _matchQuery(o, q));
    }

    // 3) Orden
    final list = it.toList();
    switch (_sortMode) {
      case 'OT # (asc)':
        list.sort((a, b) => a.ticketNo.compareTo(b.ticketNo));
        break;
      case 'OT # (desc)':
        list.sort((a, b) => b.ticketNo.compareTo(a.ticketNo));
        break;
      case 'Total (mayor)':
        list.sort((a, b) => b.monto.compareTo(a.monto));
        break;
      case 'Total (menor)':
        list.sort((a, b) => a.monto.compareTo(b.monto));
        break;
      case 'Recientes':
      default:
        list.sort((a, b) => b.created.compareTo(a.created));
        break;
    }
    return list;
  }

  double _sum(String key, List<Orden> list) {
    double total = 0;
    for (final o in list) {
      switch (key) {
        case 'total':
          total += o.monto;
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

  /// Resumen por diseñador (para dashboard)
  List<_DesignerResume> _resumeByDesigner(List<Orden> list) {
    final map = <String, _DesignerResume>{};
    for (final o in list) {
      final d =
          o.disenador.trim().isEmpty ? 'Sin diseñador' : o.disenador.trim();
      map.putIfAbsent(d, () => _DesignerResume(disenador: d));
      map[d]!.count += 1;
      map[d]!.total += o.monto;
      map[d]!.material += (o.costoMaterial ?? 0);
      map[d]!.ploteo += (o.costoPloteo ?? 0);
      map[d]!.extras += (o.costoExtras ?? 0);
    }
    final res = map.values.toList();
    // Por defecto: ordenado por total desc
    res.sort((a, b) => b.total.compareTo(a.total));
    return res;
  }

  Future<void> _confirmarCobro(Orden orden) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirmar cobro'),
          content: Text(
            '¿Marcar como PAGADA?\n\n'
            '${orden.ticketLabel}\n'
            'Cliente: ${orden.cliente}\n'
            'Total: \$${orden.monto.toStringAsFixed(0)}\n'
            'Código: ${orden.codigoCobro}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cobrar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.marcarComoPagada(orden.id);
      _snack('Cobro registrado ✅');
      await _cargar();
    } catch (e) {
      _snack('Error al cobrar: $e');
    }
  }

  Future<void> _anularOrden(Orden orden) async {
    try {
      await _service.eliminarOrden(orden.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket eliminado correctamente 🗑️'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _cargar(); // Esto refresca la lista automáticamente
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtradas;

    final total = _sum('total', list);
    final material = _sum('material', list);
    final ploteo = _sum('ploteo', list);
    final extras = _sum('extras', list);

    final resume = _resumeByDesigner(list);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final isWide = w >= 1100;

                  return Column(
                    children: [
                      _TopBar(
                        title: 'Caja • Pendientes',
                        subtitle: 'Control y cobro de órdenes',
                        searchCtrl: _searchCtrl,
                        sortMode: _sortMode,
                        onSortChanged: (v) => setState(() => _sortMode = v),
                        gridMode: _gridMode,
                        onToggleView: () =>
                            setState(() => _gridMode = !_gridMode),
                        onRefresh: _cargar,
                        onClear: _limpiarFiltros,
                        visibleCount: list.length,
                        totalCount: _ordenes.length,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 380,
                                      child: _LeftPanel(
                                        pendientes: list.length,
                                        total: total,
                                        material: material,
                                        ploteo: ploteo,
                                        extras: extras,
                                        filtroDisenador: _filtroDisenador,
                                        disenadores: _disenadoresDisponibles,
                                        onDisenadorChanged: (v) => setState(
                                            () => _filtroDisenador = v),
                                        gridMode: _gridMode,
                                        resume: resume,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _MainPanel(
                                        list: list,
                                        gridMode: _gridMode,
                                        onCobrar: _confirmarCobro,
                                        onAnular: _anularOrden,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _KpiGridCompact(
                                      pendientes: list.length,
                                      total: total,
                                      material: material,
                                      ploteo: ploteo,
                                      extras: extras,
                                    ),
                                    const SizedBox(height: 12),
                                    _FilterCard(
                                      filtroDisenador: _filtroDisenador,
                                      disenadores: _disenadoresDisponibles,
                                      onChanged: (v) =>
                                          setState(() => _filtroDisenador = v),
                                      gridMode: _gridMode,
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: _MainPanel(
                                        list: list,
                                        gridMode: _gridMode,
                                        onCobrar: _confirmarCobro,
                                        onAnular: _anularOrden,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _DesignerResume {
  final String disenador;
  int count = 0;
  double total = 0;
  double material = 0;
  double ploteo = 0;
  double extras = 0;

  _DesignerResume({required this.disenador});
}

// ===================== TOP BAR =====================

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController searchCtrl;
  final String sortMode;
  final ValueChanged<String> onSortChanged;
  final bool gridMode;
  final VoidCallback onToggleView;
  final VoidCallback onRefresh;
  final VoidCallback onClear;
  final int visibleCount;
  final int totalCount;

  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.searchCtrl,
    required this.sortMode,
    required this.onSortChanged,
    required this.gridMode,
    required this.onToggleView,
    required this.onRefresh,
    required this.onClear,
    required this.visibleCount,
    required this.totalCount,
  });

  static const _sortOptions = <String>[
    'Recientes',
    'OT # (asc)',
    'OT # (desc)',
    'Total (mayor)',
    'Total (menor)',
  ];

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
            bottom: BorderSide(
              color: isDarkMode 
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            )),
        boxShadow: [
          if (isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.point_of_sale, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 12),

          // Title + sub + counter
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode
                                ? const Color(0xFFF1F5F9)
                                : Colors.black87)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        border: isDarkMode
                            ? Border.all(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.2),
                                width: 1,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Mostrando $visibleCount / $totalCount',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: isDarkMode
                                ? const Color(0xFFCBD5E1)
                                : Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFF94A3B8)
                            : Colors.black.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2A3F5F)
                          : const Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: isDarkMode
                                ? const Color(0xFF64748B)
                                : Colors.black.withValues(alpha: 0.45)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFF1F5F9)
                                  : Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar (OT, código, cliente...)',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? const Color(0xFF64748B)
                                    : Colors.black.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w700,
                              ),
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        if (searchCtrl.text.trim().isNotEmpty)
                          IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () => searchCtrl.clear(),
                            icon: Icon(Icons.close,
                                size: 18,
                                color: Colors.black.withValues(alpha: 0.55)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortOptions.contains(sortMode)
                          ? sortMode
                          : 'Recientes',
                      items: _sortOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        onSortChanged(v);
                      },
                      icon: Icon(Icons.sort,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.black.withValues(alpha: 0.65)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          IconButton(
            tooltip: 'Limpiar filtros',
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
          IconButton(
            tooltip: gridMode ? 'Ver lista' : 'Ver cuadrícula',
            onPressed: onToggleView,
            icon: Icon(gridMode ? Icons.view_agenda : Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: 'Refrescar',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

// ===================== LEFT PANEL =====================

// ===================== LEFT PANEL (UX/UI OPTIMIZADO) =====================

class _LeftPanel extends StatelessWidget {
  final int pendientes;
  final double total;
  final double material;
  final double ploteo;
  final double extras;

  final String filtroDisenador;
  final List<String> disenadores;
  final ValueChanged<String> onDisenadorChanged;
  final bool gridMode;

  final List<_DesignerResume> resume;

  const _LeftPanel({
    required this.pendientes,
    required this.total,
    required this.material,
    required this.ploteo,
    required this.extras,
    required this.filtroDisenador,
    required this.disenadores,
    required this.onDisenadorChanged,
    required this.gridMode,
    required this.resume,
  });

  String _money(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    // 🌟 PERFECCIÓN UI: ScrollConfiguration oculta las barras feas de Windows/Web.
    // SingleChildScrollView + BouncingScrollPhysics da un rebote nativo y suave.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KpiGridWide(
              pendientes: pendientes,
              total: total,
              material: material,
              ploteo: ploteo,
              extras: extras,
            ),
            const SizedBox(height: 12),
            _FilterCard(
              filtroDisenador: filtroDisenador,
              disenadores: disenadores,
              onChanged: onDisenadorChanged,
              gridMode: gridMode,
            ),
            const SizedBox(height: 12),

            // ✅ Resumen por diseñador (dashboard a prueba de desbordes)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Resumen por diseñador',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (resume.isEmpty)
                    Text(
                      'Sin datos.',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    ...resume.take(8).map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A3F5F)
                              : const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person,
                                  size: 18, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.disenador,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color:
                                          Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.count} tickets • Material ${_money(r.material)} • Ploteo ${_money(r.ploteo)} • Extras ${_money(r.extras)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF94A3B8)
                                          : Colors.black.withValues(alpha: 0.55),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _money(r.total),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const _QuickActions(),

            // 🌟 Pad inferior para que el último botón no quede pegado al borde del monitor al hacer scroll
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===================== MAIN PANEL =====================

class _MainPanel extends StatelessWidget {
  final List<Orden> list;
  final bool gridMode;
  final Future<void> Function(Orden) onCobrar;
  final Future<void> Function(Orden) onAnular;

  const _MainPanel({
    required this.list,
    required this.gridMode,
    required this.onCobrar,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Text('Tickets pendientes',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    )),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    border: isDark
                        ? Border.all(
                            color: const Color(0xFF3B82F6)
                                .withValues(alpha: 0.2),
                            width: 1,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    gridMode ? 'CUADRÍCULA' : 'LISTA',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          Expanded(
            child: list.isEmpty
                ? const _EmptyState()
                : gridMode
                    ? _TicketsGrid(
                        list: list, onCobrar: onCobrar, onAnular: onAnular)
                    : _TicketsList(
                        list: list, onCobrar: onCobrar, onAnular: onAnular),
          ),
        ],
      ),
    );
  }
}

class _TicketsList extends StatelessWidget {
  final List<Orden> list;
  final Future<void> Function(Orden) onCobrar;
  final Future<void> Function(Orden) onAnular;

  const _TicketsList({
    required this.list,
    required this.onCobrar,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // 🌟 CORRECCIÓN 1: Eliminamos la restricción de ancho máximo de 780 para que use toda la pantalla
      child: ListView.separated(
        // 🌟 CORRECCIÓN 2: Relleno solo vertical (8) y CERO (0) a los lados para ir de borde a borde
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        itemCount: list.length,
        // 🌟 CORRECCIÓN 3: Cambiamos el separador por una línea divisoria elegante y delgada
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
        ),
        itemBuilder: (_, i) {
          final o = list[i];
          return TicketCard(
            orden: o,
            compact: false,
            onCobrar: () async => onCobrar(o),
            onAnular: () async => onAnular(o),
          );
        },
      ),
    );
  }
}

class _TicketsGrid extends StatelessWidget {
  final List<Orden> list;
  final Future<void> Function(Orden) onCobrar;
  final Future<void> Function(Orden) onAnular;

  const _TicketsGrid({
    required this.list,
    required this.onCobrar,
    required this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;

        int cols = 2;
        if (w >= 1400) {
          cols = 4;
        } else if (w >= 1050) {
          cols = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 670,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final o = list[i];
            return TicketCard(
              orden: o,
              compact: true,
              onCobrar: () async => onCobrar(o),
              onAnular: () async => onAnular(o),
            );
          },
        );
      },
    );
  }
}

// ===================== KPI GRIDS =====================

class _KpiGridWide extends StatelessWidget {
  final int pendientes;
  final double total;
  final double material;
  final double ploteo;
  final double extras;

  const _KpiGridWide({
    required this.pendientes,
    required this.total,
    required this.material,
    required this.ploteo,
    required this.extras,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Pendientes',
                value: '$pendientes',
                icon: Icons.receipt_long,
                color: const Color(0xFF6D28D9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Total',
                value: '\$${total.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Material',
                value: '\$${material.toStringAsFixed(0)}',
                icon: Icons.category,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Ploteo',
                value: '\$${ploteo.toStringAsFixed(0)}',
                icon: Icons.print,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Extras',
          value: '\$${extras.toStringAsFixed(0)}',
          icon: Icons.add_box,
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }
}

class _KpiGridCompact extends StatelessWidget {
  final int pendientes;
  final double total;
  final double material;
  final double ploteo;
  final double extras;

  const _KpiGridCompact({
    required this.pendientes,
    required this.total,
    required this.material,
    required this.ploteo,
    required this.extras,
  });

  @override
  Widget build(BuildContext context) {
    return _KpiGridWide(
      pendientes: pendientes,
      total: total,
      material: material,
      ploteo: ploteo,
      extras: extras,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
          ),
          if (isDark)
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 0),
              color: color.withValues(alpha: 0.05),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.black.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== FILTER CARD =====================

class _FilterCard extends StatelessWidget {
  final String filtroDisenador;
  final List<String> disenadores;
  final ValueChanged<String> onChanged;
  final bool gridMode;

  const _FilterCard({
    required this.filtroDisenador,
    required this.disenadores,
    required this.onChanged,
    required this.gridMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtros',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleLarge?.color,
              )),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.filter_alt_outlined,
                  color: isDark
                      ? const Color(0xFF3B82F6)
                      : Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: disenadores.contains(filtroDisenador)
                        ? filtroDisenador
                        : 'Todos',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    items: disenadores
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('Diseñador: $d')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      onChanged(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  border: isDark
                      ? Border.all(
                          color: const Color(0xFF3B82F6)
                              .withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  gridMode ? 'CUADRÍCULA' : 'LISTA',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== QUICK ACTIONS =====================

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Acciones rápidas',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleLarge?.color,
              )),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.receipt_long,
            title: 'Ver Pagados (hoy)',
            subtitle: 'Ir a inventario del día',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ListaPagadosView()),
              );
            },
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.add_circle_outline,
            title: 'Crear nueva orden',
            subtitle: 'Ir al formulario de diseño',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FormularioPosView()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A3F5F)
              : const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? const Color(0xFF3B82F6) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.black.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: isDark ? const Color(0xFF64748B) : null),
          ],
        ),
      ),
    );
  }
}

// ===================== EMPTY =====================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 44,
                color: isDark ? const Color(0xFF64748B) : null,
              ),
              const SizedBox(height: 10),
              Text('No hay tickets pendientes',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  )),
              const SizedBox(height: 6),
              Text(
                'Cuando se creen órdenes, aparecerán aquí.',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
