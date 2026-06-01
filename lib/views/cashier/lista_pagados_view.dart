import 'package:flutter/material.dart';
import 'lista_pagados_controller.dart';
import '../../models/orden_model.dart';
import '../../models/orden_item_model.dart';
import '../../services/print_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ListaPagadosView extends StatefulWidget {
  const ListaPagadosView({super.key});

  @override
  State<ListaPagadosView> createState() => _ListaPagadosViewState();
}

class _ListaPagadosViewState extends State<ListaPagadosView> {
  late final ListaPagadosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ListaPagadosController();
    _controller.addListener(_refrescarUI);
    _controller.cargar();
  }

  @override
  void dispose() {
    _controller.removeListener(_refrescarUI);
    _controller.disposeCtrl();
    super.dispose();
  }

  void _refrescarUI() {
    if (mounted) {
      setState(() {});
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }

  String _money(num v) => '\$${v.toStringAsFixed(0)}';

  void _abrirCierreCaja() {
    final total = _controller.calcularSuma('total');
    final list = _controller.filtradas;

    final efectivoRealCtrl = TextEditingController();
    double efectivoIngresado = 0;
    bool procesandoCierre = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final diferencia = efectivoIngresado - total;

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded,
                      color: Color(0xFF6D28D9), size: 26),
                  const SizedBox(width: 10),
                  Text('Cierre de Caja — ${_fmtDate(_controller.dia)}',
                      style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tickets Cobrados:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.black54)),
                                Text('${list.length}',
                                    style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total en Sistema:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFFF1F5F9) : Colors.black87)),
                                Text(_money(total),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Color(0xFF6D28D9))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Efectivo Real en Caja:',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: efectivoRealCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w900, fontSize: 16),
                        decoration: const InputDecoration(
                          prefixIcon:
                              Icon(Icons.payments_rounded, color: Colors.green),
                          hintText: '0',
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            efectivoIngresado =
                                double.tryParse(val.trim()) ?? 0;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (efectivoRealCtrl.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: diferencia == 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : diferencia > 0
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                diferencia == 0
                                    ? Icons.check_circle_rounded
                                    : diferencia > 0
                                        ? Icons.add_circle_rounded
                                        : Icons.remove_circle_rounded,
                                color: diferencia == 0
                                    ? Colors.green
                                    : diferencia > 0
                                        ? Colors.blue
                                        : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  diferencia == 0
                                      ? 'Caja cuadrada perfectamente ✨'
                                      : diferencia > 0
                                          ? 'Sobra en caja física: ${_money(diferencia)}'
                                          : 'Falta en caja física: ${_money(diferencia.abs())}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      color: diferencia == 0
                                          ? Colors.green
                                          : diferencia > 0
                                              ? Colors.blue
                                              : Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      procesandoCierre ? null : () => Navigator.pop(context),
                  child: const Text('CANCELAR',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (procesandoCierre || list.isEmpty)
                      ? null
                      : () async {
                          setModalState(() {
                            procesandoCierre = true;
                          });
                          try {
                            if (_controller.esAdmin) {
                              await _controller.exportarExcel();
                            }
                            await _controller.ejecutarCierre();
                            if (context.mounted) {
                              Navigator.pop(context);
                              _snack(
                                  'Caja cerrada de forma persistente. Proceso completado ✅📊');
                            }
                          } catch (e) {
                            _snack('Error al procesar el cierre: $e');
                          } finally {
                            setModalState(() {
                              procesandoCierre = false;
                            });
                          }
                        },
                  child: procesandoCierre
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('CONFIRMAR Y GENERAR REPORTE',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _controller.filtradas;
    final total = _controller.calcularSuma('total');
    final material = _controller.calcularSuma('material');
    final ploteo = _controller.calcularSuma('ploteo');
    final extras = _controller.calcularSuma('extras');
    final agg = _controller.buildAggByDesigner();

    String trabajosLabel(Orden o) => o.tipoTrabajo.join(' + ');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Inventario del día (Pagados)')),
      body: Row(
        children: [
          // Sidebar Fijo Izquierdo
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _kpiCard(
                    title: 'Tickets',
                    value: '${list.length}',
                    icon: Icons.receipt_long),
                const SizedBox(height: 10),
                _kpiCard(
                    title: 'Total',
                    value: _money(total),
                    icon: Icons.attach_money),
                const SizedBox(height: 10),
                _kpiCard(
                    title: 'Material',
                    value: _money(material),
                    icon: Icons.category),
                const SizedBox(height: 10),
                _kpiCard(
                    title: 'Ploteo', value: _money(ploteo), icon: Icons.print),
                const SizedBox(height: 10),
                _kpiCard(
                    title: 'Extras',
                    value: _money(extras),
                    icon: Icons.add_box),
                const SizedBox(height: 14),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A3F5F)
                        : const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : Colors.black.withValues(alpha: 0.45)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller.searchCtrl,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : Colors.black87,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar (OT, código, cliente...)',
                            hintStyle: TextStyle(
                              color: isDark
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
                      if (_controller.searchCtrl.text.trim().isNotEmpty)
                        IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () => _controller.searchCtrl.clear(),
                          icon: Icon(Icons.close,
                              size: 18,
                              color: Colors.black.withValues(alpha: 0.55)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Filtros', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.titleLarge?.color)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Diseñador:', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color))),
                          DropdownButton<String>(
                            value: _controller.filtroDisenador,
                            items: _controller.disenadoresDisponibles
                                .map((d) =>
                                    DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                _controller.cambiarFiltroDisenador(v);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Ocultar bloque por diseñador a los cajeros
                if (_controller.esAdmin)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Por diseñador', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.titleLarge?.color)),
                        const SizedBox(height: 10),
                        ...agg.values.map((a) => _designerRow(a, _money)),
                      ],
                    ),
                  ),
                if (_controller.esAdmin) const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Acciones', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.titleLarge?.color)),
                      const SizedBox(height: 10),
                      if (_controller.esAdmin)
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _controller.exportarExcel();
                              _snack('Reporte diario exportado Excel ✅');
                            } catch (e) {
                              _snack('Error exportando: $e');
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Exportar Excel'),
                        ),
                      if (_controller.esAdmin) const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _abrirCierreCaja,
                        icon: const Icon(Icons.lock),
                        label: const Text('Cerrar caja'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Área de Contenido Principal Adaptativo
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: _controller.esAdmin
                              ? _controller.diaAnterior
                              : null,
                          icon: const Icon(Icons.chevron_left)),
                      Text('Día: ${_fmtDate(_controller.dia)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
                      IconButton(
                          onPressed: _controller.esAdmin
                              ? _controller.diaSiguiente
                              : null,
                          icon: const Icon(Icons.chevron_right)),
                      const SizedBox(width: 10),
                      if (_controller.esAdmin)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _controller.dia,
                              firstDate: DateTime(2020, 1, 1),
                              lastDate: DateTime(2100, 12, 31),
                            );
                            if (picked != null) {
                              _controller.cambiarFecha(picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Fecha'),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded,
                            color: _controller.gridMode
                                ? const Color(0xFF6D28D9)
                                : Colors.black54),
                        onPressed: () => _controller.setGridMode(true),
                        tooltip: 'Ver como Cuadrícula',
                      ),
                      IconButton(
                        icon: Icon(Icons.view_list_rounded,
                            color: !_controller.gridMode
                                ? const Color(0xFF6D28D9)
                                : Colors.black54),
                        onPressed: () => _controller.setGridMode(false),
                        tooltip: 'Ver como Lista',
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                          onPressed: _controller.cargar,
                          icon: const Icon(Icons.refresh)),
                    ],
                  ),
                ),
                Expanded(
                  child: _controller.loading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                          ? const Center(child: Text('No hay tickets pagados.'))
                          : _controller.gridMode
                              ? GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 340,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: 260,
                                  ),
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => _OrdenCardCompact(
                                    orden: list[i],
                                    money: _money,
                                    trabajosLabel: trabajosLabel,
                                    fetchItems: _controller.fetchItemsDeOrden,
                                    isListMode: false,
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _OrdenCardCompact(
                                      orden: list[i],
                                      money: _money,
                                      trabajosLabel: trabajosLabel,
                                      fetchItems: _controller.fetchItemsDeOrden,
                                      isListMode: true,
                                    ),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
      {required String title, required String value, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDark ? const Color(0xFF3B82F6) : null),
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
                            : Colors.black.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _designerRow(DesignerAggLocal a, String Function(num) money) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3F5F) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.nombre,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${a.tickets} tks • Mat ${money(a.material)} • Plot ${money(a.ploteo)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.black.withValues(alpha: 0.55),
                      fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(money(a.total),
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _OrdenCardCompact extends StatelessWidget {
  static const Color _ramon = Color(0xFF38BDF8);
  static const Color _cristian = Color(0xFFFFA11A);
  static const Color _defaultAccent = Color(0xFF6D28D9);

  final Orden orden;
  final String Function(num) money;
  final String Function(Orden) trabajosLabel;
  final Future<List<OrdenItem>> Function(String ordenId) fetchItems;
  final bool isListMode;

  const _OrdenCardCompact({
    required this.orden,
    required this.money,
    required this.trabajosLabel,
    required this.fetchItems,
    required this.isListMode,
  });

  Color _accentByDisenador(String d) {
    final x = d.trim().toLowerCase();
    if (x == 'ramon') return _ramon;
    if (x == 'cristian') return _cristian;
    return _defaultAccent;
  }

  Future<void> _openDetalle(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) {
        final accent = _accentByDisenador(orden.disenador);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _DetalleOrdenDialog(
              orden: orden,
              money: money,
              trabajosLabel: trabajosLabel,
              fetchItems: fetchItems,
              accent: accent,
            ),
          ),
        );
      },
    );
  }

  Future<void> _reimprimirTicket(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preparando ticket para impresión...'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentByDisenador(orden.disenador),
        ),
      );
      final items = await fetchItems(orden.id);
      await PrintService.imprimirOrden(orden: orden, items: items);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error de impresión: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _compartirWhatsApp(BuildContext context) async {
    final mensaje =
        "Hola *${orden.cliente}*, aquí tienes el resumen de tu orden *${orden.ticketLabel}*.\n\nTotal: *${money(orden.monto)}*\n\n¡Gracias por tu compra!";
    final url =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(mensaje)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final o = orden;
    final accent = _accentByDisenador(o.disenador);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isListMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 2),
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x05000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(8)),
              child: Text(
                o.ticketLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(o.cliente,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Dis: ${o.disenador}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.black.withValues(alpha: 0.50),
                          fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                trabajosLabel(o),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : Colors.black87),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Cod: ${o.codigoCobro}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.black.withValues(alpha: 0.45),
                  fontSize: 12),
            ),
            const SizedBox(width: 24),
            Text(money(o.monto),
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(width: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF25D366),
                    tooltip: 'WhatsApp',
                    onTap: () => _compartirWhatsApp(context),
                    accent: accent),
                const SizedBox(width: 6),
                _actionIconButton(
                    icon: Icons.print_outlined,
                    color: accent,
                    tooltip: 'Imprimir',
                    onTap: () => _reimprimirTicket(context),
                    accent: accent),
                const SizedBox(width: 6),
                _actionIconButton(
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    tooltip: 'Ver Auditoría',
                    onTap: () => _openDetalle(context),
                    accent: accent),
              ],
            )
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x08000000),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.85)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${o.ticketLabel} • ${o.cliente}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(money(o.monto),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Diseñador: ${o.disenador}  |  Cod: ${o.codigoCobro}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.black.withValues(alpha: 0.55),
                        fontSize: 11.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Text(
                      trabajosLabel(o),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          height: 1.2),
                    ),
                  ),
                  const Spacer(),
                  _miniLine('Material', money(o.costoMaterial ?? 0), isDark),
                  _miniLine('Ploteo', money(o.costoPloteo ?? 0), isDark),
                  _miniLine('Extras', money(o.costoExtras ?? 0), isDark),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.06)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF25D366),
                    tooltip: 'Enviar WhatsApp',
                    onTap: () => _compartirWhatsApp(context),
                    accent: accent),
                _actionIconButton(
                    icon: Icons.print_outlined,
                    color: accent,
                    tooltip: 'Reimprimir recibo',
                    onTap: () => _reimprimirTicket(context),
                    accent: accent),
                _actionIconButton(
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    tooltip: 'Ver detalle',
                    onTap: () => _openDetalle(context),
                    accent: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }

  Widget _miniLine(String left, String right, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(left,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.black.withValues(alpha: 0.45),
                    fontSize: 11)),
          ),
          Text(right,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isDark ? const Color(0xFFF1F5F9) : Colors.black87)),
        ],
      ),
    );
  }
}

class _DetalleOrdenDialog extends StatefulWidget {
  final Orden orden;
  final String Function(num) money;
  final String Function(Orden) trabajosLabel;
  final Future<List<OrdenItem>> Function(String ordenId) fetchItems;
  final Color accent;

  const _DetalleOrdenDialog({
    required this.orden,
    required this.money,
    required this.trabajosLabel,
    required this.fetchItems,
    required this.accent,
  });

  @override
  State<_DetalleOrdenDialog> createState() => _DetalleOrdenDialogState();
}

class _DetalleOrdenDialogState extends State<_DetalleOrdenDialog> {
  late Future<List<OrdenItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchItems(widget.orden.id);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.orden;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            widget.accent,
            widget.accent.withValues(alpha: 0.85)
          ])),
          child: Row(
            children: [
              Expanded(
                  child: Text('${o.ticketLabel} • ${o.cliente}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900))),
              Text(widget.money(o.monto),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white)),
            ],
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Diseñador: ${o.disenador} • Código: ${o.codigoCobro}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.black.withValues(alpha: 0.70)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A3F5F) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Text(widget.trabajosLabel(o),
                      style: TextStyle(
                          color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<OrdenItem>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: widget.accent));
                      }
                      if (snap.hasError) return Text('Error: ${snap.error}');

                      final items = snap.data ?? const <OrdenItem>[];
                      if (items.isEmpty) return const Text('Sin items.');

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: widget.accent.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xE0FFFFFF),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                                            : Colors.black.withValues(alpha: 0.08)),
                                  ),
                                  child: Text(
                                      it.seccion.isEmpty ? 'Item' : it.seccion,
                                      style: TextStyle(
                                          color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                          fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(it.descripcion,
                                          style: TextStyle(
                                              color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                              fontWeight: FontWeight.w900)),
                                      Text(
                                          'Cant: ${it.cantidad} • Unit: ${widget.money(it.precioUnitario)}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : Colors.black.withValues(alpha: 0.60))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(widget.money(it.subtotal),
                                    style: TextStyle(
                                        color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.10)),
                _row('Material', widget.money(o.costoMaterial ?? 0), isDark),
                _row('Ploteo', widget.money(o.costoPloteo ?? 0), isDark),
                _row('Extras', widget.money(o.costoExtras ?? 0), isDark),
                const SizedBox(height: 6),
                Divider(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.12)),
                _row('TOTAL', widget.money(o.monto), isDark, bold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _row(String left, String right, bool isDark, {bool bold = false}) {
    final st = TextStyle(
        fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
        color: isDark
            ? (bold ? const Color(0xFFF1F5F9) : const Color(0xFFCBD5E1))
            : Colors.black.withValues(alpha: bold ? 0.85 : 0.65));
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(child: Text(left, style: st)),
        Text(right, style: st)
      ]),
    );
  }
}
