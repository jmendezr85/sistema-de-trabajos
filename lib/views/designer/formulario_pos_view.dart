import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../services/pb_service.dart';
import '../../models/orden_item_model.dart';
import '../../services/print_service.dart';
import '../../models/orden_model.dart';

class FormularioPosView extends StatefulWidget {
  const FormularioPosView({super.key});

  @override
  State<FormularioPosView> createState() => _FormularioPosViewState();
}

class _DetalleGroup {
  final String key;
  final String descripcion;
  final String seccion;
  final double precioUnitario;
  final int cantidad;
  final double total;

  const _DetalleGroup({
    required this.key,
    required this.descripcion,
    required this.seccion,
    required this.precioUnitario,
    required this.cantidad,
    required this.total,
  });
}

class _RowData {
  final String material;
  final String cara;
  final String corte;
  final int precio;
  final VoidCallback onTap;

  _RowData({
    required this.material,
    required this.cara,
    required this.corte,
    required this.precio,
    required this.onTap,
  });
}

class _FormularioPosViewState extends State<FormularioPosView> {
  final _service = PocketBaseService();

  int _categoriaSeleccionada = 0;

  final List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Impresión Láser',
      'color': const Color(0xFF3B82F6),
      'icono': Icons.print
    },
    {
      'nombre': 'Ploteo Exterior',
      'color': const Color(0xFF10B981),
      'icono': Icons.landscape
    },
    {
      'nombre': 'Ploteo Interior',
      'color': const Color(0xFFF59E0B),
      'icono': Icons.wallpaper
    },
    {
      'nombre': 'Diseño & Otros',
      'color': const Color(0xFF8B5CF6),
      'icono': Icons.design_services
    },
  ];

  final _clienteCtrl = TextEditingController();
  final List<String> _disenadores = const ['Ramon', 'Cristian'];
  String _disenador = 'Ramon';
  final List<OrdenItem> _detalle = [];
  bool _saving = false;

  final _anchoCtrl = TextEditingController();
  final _altoCtrl = TextEditingController();
  int _cantOjaletes = 0;
  bool _aplicaIvaExterior = false;

  final _ploteoInteriorBaseCtrl = TextEditingController(text: '0');
  final _disenoDescCtrl = TextEditingController();
  final _disenoValorCtrl = TextEditingController(text: '0');
  final _abonoCtrl = TextEditingController(text: '0');

  String _materialExterior = 'Vinilo';
  String _ploteoInteriorExtra = 'Ninguno';

  final List<String> _materialOptions = const [
    'Vinilo',
    'Lona',
    'Fotográfico',
    'Propalcote',
    'Pergamino',
    'Lienzo',
    'Pendón'
  ];

  static const double _viniloMat = 9000;
  static const double _viniloCorte = 11000;
  static const double _viniloPloteo = 20000;

  Map<String, int> _precioLaserPO({required String size, required bool doble}) {
    if (size == 'carta') {
      if (doble) {
        return const {'total': 4500, 'laser': 4000, 'mat': 500};
      } else {
        return const {'total': 2500, 'laser': 2000, 'mat': 500};
      }
    }
    if (size == 'tabloide') {
      if (doble) {
        return const {'total': 7000, 'laser': 6000, 'mat': 1000};
      } else {
        return const {'total': 4000, 'laser': 3000, 'mat': 1000};
      }
    }
    if (doble) {
      return const {'total': 10000, 'laser': 8000, 'mat': 2000};
    } else {
      return const {'total': 6000, 'laser': 5000, 'mat': 1000};
    }
  }

  int _precioBond(String size) {
    if (size == 'carta' || size == 'oficio') {
      return 1500;
    }
    return 2500;
  }

  int _extraPloteoInterior(String extraKey) {
    if (extraKey == 'Opalina Pliego') {
      return 3500;
    }
    if (extraKey == 'Opalina 1/2 Pliego') {
      return 2000;
    }
    if (extraKey == 'Opalina 1/4 Pliego') {
      return 1000;
    }
    if (extraKey == 'Bond Adhesivo Pliego') {
      return 2500;
    }
    if (extraKey == 'Bond Adhesivo 1/2 Pliego') {
      return 1500;
    }
    if (extraKey == 'Bond Adhesivo 1/4 Pliego') {
      return 1000;
    }
    return 0;
  }

  double _toD(String s) => double.tryParse(s.trim()) ?? 0;

  double get _subtotal => _detalle.fold(
      0,
      (a, b) =>
          a +
          (b.meta['costo_iva'] == null
              ? b.subtotal
              : b.subtotal - b.meta['costo_iva']));

  double get _totalIva =>
      _detalle.fold(0, (a, b) => a + (b.meta['costo_iva'] ?? 0));

  double get _total => _detalle.fold(0, (a, b) => a + b.subtotal);

  String _money(num v) {
    final x = v.round();
    final s = x.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) {
        buf.write('.');
      }
    }
    return '\$${buf.toString()}';
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _groupKeyFor(OrdenItem it) =>
      '${it.seccion}__${it.descripcion}__${it.precioUnitario.toStringAsFixed(2)}';

  List<_DetalleGroup> _groupedDetalle() {
    final map = <String, _DetalleGroup>{};
    for (final it in _detalle) {
      final key = _groupKeyFor(it);
      final current = map[key];
      if (current == null) {
        map[key] = _DetalleGroup(
            key: key,
            descripcion: it.descripcion,
            seccion: it.seccion,
            precioUnitario: it.precioUnitario,
            cantidad: it.cantidad,
            total: it.subtotal);
      } else {
        map[key] = _DetalleGroup(
            key: key,
            descripcion: current.descripcion,
            seccion: current.seccion,
            precioUnitario: current.precioUnitario,
            cantidad: current.cantidad + it.cantidad,
            total: current.total + it.subtotal);
      }
    }
    return map.values.toList();
  }

  void _decrementGroupByOne(String groupKey) {
    final idx = _detalle.lastIndexWhere((it) => _groupKeyFor(it) == groupKey);
    if (idx >= 0) {
      setState(() {
        _detalle.removeAt(idx);
      });
    }
  }

  void _incrementGroupByOne(String groupKey) {
    final idx = _detalle.indexWhere((it) => _groupKeyFor(it) == groupKey);
    if (idx >= 0) {
      final original = _detalle[idx];
      setState(() {
        _detalle.add(OrdenItem(
            ordenId: '',
            seccion: original.seccion,
            descripcion: original.descripcion,
            cantidad: 1,
            precioUnitario: original.precioUnitario,
            subtotal: original.precioUnitario,
            costoLaser: original.costoLaser,
            costoMaterial: original.costoMaterial,
            meta: original.meta));
      });
    }
  }

  void _removeGroup(String groupKey) {
    setState(() {
      _detalle.removeWhere((it) => _groupKeyFor(it) == groupKey);
    });
  }

  void _addLaserItem(String tipo, String size, bool dobleCara,
      {bool conCorte = false}) {
    final isBond = tipo == 'Bond';
    final seccion = isBond ? 'laser_bond' : 'laser_propalcote_opalina';
    double unit, laser, mat;

    if (isBond) {
      unit = _precioBond(size).toDouble();
      laser = unit;
      mat = 0;
    } else {
      final p = _precioLaserPO(size: size, doble: dobleCara);
      unit = p['total']!.toDouble();
      laser = p['laser']!.toDouble();
      mat = p['mat']!.toDouble();
      if (size == 'extra' && conCorte) {
        unit += 6000;
        laser += 6000;
      }
    }

    final desc = isBond
        ? 'Laser bond $size${size == 'doblecarta' ? ' (color)' : ''}'
        : 'Laser ${tipo.toLowerCase()} $size${conCorte ? ' + corte' : ''}${dobleCara ? ' (doblecara)' : ''}';

    setState(() {
      _detalle.add(OrdenItem(
          ordenId: '',
          seccion: seccion,
          descripcion: desc,
          cantidad: 1,
          precioUnitario: unit,
          subtotal: unit,
          costoLaser: laser,
          costoMaterial: mat,
          meta: {
            'tipo': tipo,
            'size': size,
            'doblecara': dobleCara,
            if (size == 'extra') 'corte': conCorte
          }));
    });
  }

  void _addExteriorItemComboVinilo() {
    const total = 40000.0;
    setState(() {
      _detalle.add(OrdenItem(
          ordenId: '',
          seccion: 'ploteo_exterior',
          descripcion: 'Vinilo + Corte (Ploteo Exterior)',
          cantidad: 1,
          precioUnitario: total,
          subtotal: total,
          costoLaser: _viniloCorte,
          costoMaterial: _viniloMat,
          meta: {
            'tipo': 'vinilo_corte',
            'corte': _viniloCorte,
            'material': _viniloMat,
            'ploteo': _viniloPloteo
          }));
    });
    _snack('Combo Vinilo + Corte agregado');
  }

  void _addExteriorItemCalculado() {
    final ancho = _toD(_anchoCtrl.text);
    final alto = _toD(_altoCtrl.text);
    if (ancho <= 0 || alto <= 0) {
      _snack('Ingresa ancho y alto válidos');
      return;
    }
    try {
      final ext = _service.calcularExterior(
          anchoCm: ancho, altoCm: alto, material: _materialExterior);
      double totalBase = (ext['total'] ?? 0).toDouble();
      if (totalBase <= 0) {
        return;
      }

      final costoOjaletes = _cantOjaletes * 2500.0;
      double subtotalAntesDeIva = totalBase + costoOjaletes;
      double costoIva = _aplicaIvaExterior ? subtotalAntesDeIva * 0.19 : 0;
      double totalFinal = subtotalAntesDeIva + costoIva;

      String descExtra = '';
      if (_cantOjaletes > 0) {
        descExtra += ' + $_cantOjaletes Ojaletes';
      }
      if (_aplicaIvaExterior) {
        descExtra += ' + IVA';
      }

      setState(() {
        _detalle.add(OrdenItem(
            ordenId: '',
            seccion: 'ploteo_exterior',
            descripcion:
                'Ploteo exterior $_materialExterior (${ancho.toStringAsFixed(0)}x${alto.toStringAsFixed(0)} cm)$descExtra',
            cantidad: 1,
            precioUnitario: totalFinal,
            subtotal: totalFinal,
            costoLaser: 0,
            costoMaterial: (ext['costo_material'] ?? 0).toDouble(),
            meta: {
              'material': _materialExterior,
              'ancho_cm': ancho,
              'alto_cm': alto,
              'costo_ojaletes': costoOjaletes,
              'costo_iva': costoIva,
              'costo_extras': (ext['costo_extras'] ?? 0).toDouble(),
              'costo_ploteo': (ext['costo_ploteo'] ?? 0).toDouble()
            }));
      });
      _anchoCtrl.clear();
      _altoCtrl.clear();
      _cantOjaletes = 0;
      _aplicaIvaExterior = false;
    } catch (_) {
      _snack('Error calculando ploteo exterior');
    }
  }

  void _addPloteoInterior() {
    final base = _toD(_ploteoInteriorBaseCtrl.text);
    final extra = _extraPloteoInterior(_ploteoInteriorExtra).toDouble();
    if (base <= 0 && extra <= 0) {
      _snack('Ingresa un valor o selecciona un material');
      return;
    }
    final total = (max(0.0, base) + max(0.0, extra)).toDouble();
    setState(() {
      _detalle.add(OrdenItem(
          ordenId: '',
          seccion: 'ploteo_interior',
          descripcion:
              'Ploteo interior${_ploteoInteriorExtra != 'Ninguno' ? ' + ${_ploteoInteriorExtra.toLowerCase()}' : ''}',
          cantidad: 1,
          precioUnitario: total,
          subtotal: total,
          costoLaser: 0,
          costoMaterial: extra,
          meta: {
            'base': base,
            'extra_key': _ploteoInteriorExtra,
            'extra_valor': extra
          }));
      _ploteoInteriorBaseCtrl.text = '0';
      _ploteoInteriorExtra = 'Ninguno';
    });
    _snack('Ploteo interior añadido');
  }

  void _addCustomItem(
      String title, String seccion, TextEditingController ctrl) {
    final v = _toD(ctrl.text);
    if (v <= 0) {
      _snack('Ingresa un valor mayor a 0');
      return;
    }
    setState(() {
      _detalle.add(OrdenItem(
          ordenId: '',
          seccion: seccion,
          descripcion: title,
          cantidad: 1,
          precioUnitario: v,
          subtotal: v,
          costoLaser: 0,
          costoMaterial: 0,
          meta: {}));
      ctrl.text = '0';
    });
    _snack('$title añadido');
  }

  Future<void> _procesarOrden({required bool soloGuardar}) async {
    final cliente = _clienteCtrl.text.trim();
    if (cliente.isEmpty) {
      _snack('Escribe el nombre del cliente');
      return;
    }
    if (_detalle.isEmpty) {
      _snack('Agrega al menos un item al detalle');
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final tipoTrabajo = <String>[
        if (_detalle.any((x) => x.seccion == 'diseno_corte')) 'Diseño/Corte',
        if (_detalle.any((x) => x.seccion.contains('laser'))) 'Impresión Laser',
        if (_detalle.any((x) => x.seccion == 'ploteo_interior'))
          'Ploteo Interior',
        if (_detalle.any((x) => x.seccion == 'ploteo_exterior'))
          'Ploteo Exterior',
      ];
      final materiales = _detalle.map((x) => x.descripcion).join(' | ');
      final abono = double.tryParse(_abonoCtrl.text.trim()) ?? 0.0;
      final Orden ordenCreada = await _service.crearOrdenV2ConItems(
          cliente: cliente,
          disenador: _disenador,
          itemsSinOrdenId: _detalle,
          materiales: materiales,
          tipoTrabajo: tipoTrabajo,
          abono: abono);

      if (!soloGuardar) {
        if (!kIsWeb) {
          await PrintService.imprimirOrden(orden: ordenCreada, items: _detalle);
        }
      }
      _snack(soloGuardar ? 'Orden guardada ✅' : 'Orden creada e impresa ✅');
      setState(() {
        _clienteCtrl.clear();
        _abonoCtrl.clear();
        _abonoCtrl.text = '0';
        _detalle.clear();
      });
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Color _colorByDesigner(String d) {
    final x = d.trim().toLowerCase();
    if (x == 'ramon') {
      return const Color(0xFF38BDF8);
    }
    if (x == 'cristian') {
      return const Color(0xFFFFA11A);
    }
    return const Color(0xFF13C6A5);
  }

  static const _bgColor = Color(0xFFF8FAFC);
  static const _sidebarColor = Color(0xFF1E293B);
  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorDisenadorActual = _colorByDesigner(_disenador);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Container(
            width: 110,
            color: isDark ? const Color(0xFF0F172A) : _sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Icon(Icons.print_outlined, color: isDark ? const Color(0xFF3B82F6) : Colors.white, size: 40),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final activo = _categoriaSeleccionada == index;
                      final cat = _categorias[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _categoriaSeleccionada = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 8),
                          decoration: BoxDecoration(
                            color: activo ? _primaryBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat['icono'],
                                  color: activo ? Colors.white : (isDark ? const Color(0xFF94A3B8) : Colors.white54),
                                  size: 28),
                              const SizedBox(height: 8),
                              Text(
                                cat['nombre'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: activo
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: activo ? Colors.white : (isDark ? const Color(0xFF94A3B8) : Colors.white54),
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: isDark ? const Color(0xFFCBD5E1) : Colors.black54),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 10),
                      Text('Nueva Orden - POS',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.titleLarge?.color,
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: colorDisenadorActual.withValues(
                                    alpha: 0.3)),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            CircleAvatar(
                                radius: 12,
                                backgroundColor:
                                    colorDisenadorActual.withValues(alpha: 0.2),
                                child: Text(_disenador[0],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorDisenadorActual,
                                        fontWeight: FontWeight.bold))),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _disenador,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  size: 16),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                  fontSize: 14),
                              items: _disenadores
                                  .map((d) => DropdownMenuItem(
                                      value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _disenador = v!;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildCentralContent(isDark),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 380,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: isDark ? const Color(0xFFCBD5E1) : Colors.black87),
                      const SizedBox(width: 10),
                      Text('Orden actual',
                          style: TextStyle(
                              color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                              fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _clienteCtrl,
                    style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente (opcional)',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.black45),
                      prefixIcon:
                          Icon(Icons.person_outline, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : _bgColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: isDark ? const BorderSide(color: Color(0xFF3B82F6), width: 0.5) : BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _detalle.isEmpty
                      ? const Center(
                          child: Text('Carrito vacío',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: _groupedDetalle().map((g) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A3F5F) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: _categorias[
                                                        _categoriaSeleccionada]
                                                    ['color']
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Icon(
                                            _categorias[_categoriaSeleccionada]
                                                ['icono'],
                                            size: 16,
                                            color: _categorias[
                                                    _categoriaSeleccionada]
                                                ['color']),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(g.descripcion,
                                              style: TextStyle(
                                                  color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis)),
                                      Text(_money(g.precioUnitario),
                                          style: TextStyle(
                                              color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          _removeGroup(g.key);
                                        },
                                        child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.shade300),
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: Icon(
                                                Icons.delete_outline,
                                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                                                size: 18)),
                                      ),
                                      const Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Row(
                                          children: [
                                            InkWell(
                                                onTap: () {
                                                  _decrementGroupByOne(g.key);
                                                },
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4),
                                                    child: Text('-',
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                isDark ? const Color(0xFF94A3B8) : Colors.grey)))),
                                            Text('${g.cantidad}',
                                                style: TextStyle(
                                                    color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14)),
                                            InkWell(
                                                onTap: () {
                                                  _incrementGroupByOne(g.key);
                                                },
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4),
                                                    child: Text('+',
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: isDark ? const Color(0xFFCBD5E1) : Colors.black)))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                          width: 70,
                                          child: Text(_money(g.total),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15))),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, boxShadow: [
                    BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ]),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                                    fontWeight: FontWeight.w600)),
                            Text(_money(_subtotal),
                                style: TextStyle(
                                    color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                    fontWeight: FontWeight.bold))
                          ]),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('IVA (19%)',
                                style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                                    fontWeight: FontWeight.w600)),
                            Text(_money(_totalIva),
                                style: TextStyle(
                                    color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                    fontWeight: FontWeight.bold))
                          ]),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1)),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL',
                                style: TextStyle(
                                    color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                                    fontSize: 20, fontWeight: FontWeight.w900)),
                            Text(_money(_total),
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: colorDisenadorActual))
                          ]),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Abono Inicial',
                              style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          const Spacer(),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _abonoCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18),
                              decoration: InputDecoration(
                                prefixText: '\$',
                                prefixStyle: TextStyle(
                                    color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08)),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving || _detalle.isEmpty
                                  ? null
                                  : () {
                                      _procesarOrden(soloGuardar: true);
                                    },
                              style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey)),
                              child: Icon(Icons.save_outlined,
                                  color: isDark ? const Color(0xFF3B82F6) : Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: _saving || _detalle.isEmpty
                                  ? null
                                  : () {
                                      _procesarOrden(soloGuardar: false);
                                    },
                              icon: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.shopping_cart_outlined),
                              label: Text(
                                  _saving
                                      ? 'PROCESANDO'
                                      : 'COBRAR ${_money(_total)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: colorDisenadorActual,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralContent(bool isDark) {
    switch (_categoriaSeleccionada) {
      case 0:
        return _buildImpresionLaser(isDark);
      case 1:
        return _buildPloteoExterior(isDark);
      case 2:
        return _buildPloteoInterior(isDark);
      case 3:
        return _buildDisenoYOtros(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildImpresionLaser(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.print, color: _primaryBlue, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Impresión Láser',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF60A5FA) : _primaryBlue)),
                  Text('Selecciona un producto para agregar al carrito',
                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildTablaPorBloque(isDark: isDark, 
            titulo: 'CARTA',
            colorTema: const Color(0xFF6366F1),
            rows: [
              _RowData(
                  material: 'Propalcote',
                  cara: '1 Cara',
                  corte: 'Sin corte',
                  precio: _precioLaserPO(size: 'carta', doble: false)['total']!,
                  onTap: () {
                    _addLaserItem('Propalcote', 'carta', false);
                  }),
              _RowData(
                  material: 'Propalcote',
                  cara: 'Doble Cara',
                  corte: 'Sin corte',
                  precio: _precioLaserPO(size: 'carta', doble: true)['total']!,
                  onTap: () {
                    _addLaserItem('Propalcote', 'carta', true);
                  }),
              _RowData(
                  material: 'Opalina',
                  cara: '1 Cara',
                  corte: 'Sin corte',
                  precio: _precioLaserPO(size: 'carta', doble: false)['total']!,
                  onTap: () {
                    _addLaserItem('Opalina', 'carta', false);
                  }),
              _RowData(
                  material: 'Opalina',
                  cara: 'Doble Cara',
                  corte: 'Sin corte',
                  precio: _precioLaserPO(size: 'carta', doble: true)['total']!,
                  onTap: () {
                    _addLaserItem('Opalina', 'carta', true);
                  }),
            ],
          ),
          const SizedBox(height: 20),
          _buildTablaPorBloque(isDark: isDark, 
            titulo: 'TABLOIDE',
            colorTema: const Color(0xFF059669),
            rows: [
              _RowData(
                  material: 'Propalcote',
                  cara: '1 Cara',
                  corte: 'Sin corte',
                  precio:
                      _precioLaserPO(size: 'tabloide', doble: false)['total']!,
                  onTap: () {
                    _addLaserItem('Propalcote', 'tabloide', false);
                  }),
              _RowData(
                  material: 'Propalcote',
                  cara: 'Doble Cara',
                  corte: 'Sin corte',
                  precio:
                      _precioLaserPO(size: 'tabloide', doble: true)['total']!,
                  onTap: () {
                    _addLaserItem('Propalcote', 'tabloide', true);
                  }),
              _RowData(
                  material: 'Opalina',
                  cara: '1 Cara',
                  corte: 'Sin corte',
                  precio:
                      _precioLaserPO(size: 'tabloide', doble: false)['total']!,
                  onTap: () {
                    _addLaserItem('Opalina', 'tabloide', false);
                  }),
              _RowData(
                  material: 'Opalina',
                  cara: 'Doble Cara',
                  corte: 'Sin corte',
                  precio:
                      _precioLaserPO(size: 'tabloide', doble: true)['total']!,
                  onTap: () {
                    _addLaserItem('Opalina', 'tabloide', true);
                  }),
            ],
          ),
          const SizedBox(height: 20),
          _buildTablaPorBloque(isDark: isDark, 
            titulo: 'EXTRA',
            colorTema: const Color(0xFFD97706),
            rows: [
              _RowData(
                  material: 'Propalcote',
                  cara: '1 Cara',
                  corte: 'Sin corte',
                  precio: _precioLaserPO(size: 'extra', doble: false)['total']!,
                  onTap: () {
                    _addLaserItem('Propalcote', 'extra', false);
                  }),
              _RowData(
                  material: 'Propalcote',
                  cara: 'Doble Cara',
                  corte: 'Sin corte',
                  precio: _precioLaserPO(size: 'extra', doble: true)['total']!,
                  onTap: () {
                    _addLaserItem('Propalcote', 'extra', true);
                  }),
              _RowData(
                  material: 'Propalcote',
                  cara: '1 Cara',
                  corte: 'Con corte',
                  precio:
                      _precioLaserPO(size: 'extra', doble: false)['total']! +
                          6000,
                  onTap: () {
                    _addLaserItem('Propalcote', 'extra', false, conCorte: true);
                  }),
              _RowData(
                  material: 'Opalina',
                  cara: 'Doble Cara',
                  corte: 'Con corte',
                  precio: _precioLaserPO(size: 'extra', doble: true)['total']! +
                      6000,
                  onTap: () {
                    _addLaserItem('Opalina', 'extra', true, conCorte: true);
                  }),
            ],
          ),
          const SizedBox(height: 20),
          _buildTablaPorBloque(isDark: isDark, 
            titulo: 'BOND',
            colorTema: const Color(0xFF64748B),
            rows: [
              _RowData(
                  material: 'Bond',
                  cara: 'Blanco y Negro',
                  corte: 'Carta',
                  precio: _precioBond('carta'),
                  onTap: () {
                    _addLaserItem('Bond', 'carta', false);
                  }),
              _RowData(
                  material: 'Bond',
                  cara: 'Blanco y Negro',
                  corte: 'Oficio',
                  precio: _precioBond('oficio'),
                  onTap: () {
                    _addLaserItem('Bond', 'oficio', false);
                  }),
              _RowData(
                  material: 'Bond',
                  cara: 'Color',
                  corte: 'Doble Carta',
                  precio: _precioBond('doblecarta'),
                  onTap: () {
                    _addLaserItem('Bond', 'doblecarta', false);
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTablaPorBloque(
      {required String titulo,
      required Color colorTema,
      required List<_RowData> rows,
      required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, color: colorTema, size: 20),
                const SizedBox(width: 8),
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: colorTema.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${rows.length} productos',
                      style: TextStyle(
                          color: colorTema,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          Container(
            color: isDark ? const Color(0xFF2A3F5F) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('MATERIAL',
                        style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 2,
                    child: Text('CARA',
                        style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 2,
                    child: Text('CORTE',
                        style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 2,
                    child: Text('PRECIO',
                        style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 60,
                    child: Text('ACCIÓN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (context, index) {
              return Divider(height: 1, color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : const Color(0xFFF1F5F9));
            },
            itemBuilder: (context, index) {
              final r = rows[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getMaterialColor(r.material)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(r.material,
                              style: TextStyle(
                                  color: _getMaterialColor(r.material),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Text(r.cara,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFF1F5F9) : Colors.black87))),
                    Expanded(
                        flex: 2,
                        child: Text(r.corte,
                            style: TextStyle(
                                fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.black54))),
                    Expanded(
                        flex: 2,
                        child: Text(_money(r.precio),
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: colorTema,
                                fontSize: 14))),
                    SizedBox(
                      width: 60,
                      child: Center(
                        child: InkWell(
                          onTap: r.onTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: colorTema,
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.add,
                                color: isDark ? const Color(0xFFF1F5F9) : Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Color _getMaterialColor(String mat) {
    switch (mat.toLowerCase()) {
      case 'propalcote':
        return const Color(0xFF2563EB);
      case 'opalina':
        return const Color(0xFF9333EA);
      case 'bond':
        return const Color(0xFF475569);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildPloteoExterior(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.landscape, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ploteo Exterior',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981))),
                Text('Configura medidas personalizadas o combos',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
        const SizedBox(height: 30),
        InkWell(
          onTap: _addExteriorItemComboVinilo,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 30),
                const SizedBox(width: 16),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('COMBO: Vinilo + Corte',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Agrega automáticamente el combo estándar',
                          style: TextStyle(color: Colors.white70))
                    ])),
                Text(_money(40000),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text('Medidas Personalizadas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _materialExterior,
                    decoration: InputDecoration(
                        labelText: 'Material',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.shade300))),
                    items: _materialOptions
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _materialExterior = v!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: TextField(
                        controller: _anchoCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                        decoration: InputDecoration(
                            labelText: 'Ancho(cm)',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.shade300))))),
                const SizedBox(width: 16),
                Expanded(
                    child: TextField(
                        controller: _altoCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                        decoration: InputDecoration(
                            labelText: 'Alto(cm)',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.shade300))))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.shade300)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ojaletes',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                              fontSize: 14)),
                      const SizedBox(width: 12),
                      InkWell(
                          onTap: _cantOjaletes > 0
                              ? () {
                                  setState(() {
                                    _cantOjaletes--;
                                  });
                                }
                              : null,
                          child: Icon(Icons.remove_circle_outline,
                              color:
                                  _cantOjaletes > 0 ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey),
                              size: 28)),
                      const SizedBox(width: 12),
                      Text('$_cantOjaletes',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 12),
                      InkWell(
                          onTap: () {
                            setState(() {
                              _cantOjaletes++;
                            });
                          },
                          child: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF059669), size: 28)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () {
                    setState(() {
                      _aplicaIvaExterior = !_aplicaIvaExterior;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                            value: _aplicaIvaExterior,
                            onChanged: (v) {
                              setState(() {
                                _aplicaIvaExterior = v ?? false;
                              });
                            },
                            activeColor: const Color(0xFF059669),
                            visualDensity: VisualDensity.compact),
                        Text('IVA 19%',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isDark ? const Color(0xFFF1F5F9) : Colors.black87)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 55,
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: _addExteriorItemCalculado,
                    icon: const Icon(Icons.add),
                    label: const Text('AGREGAR',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                )
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildPloteoInterior(bool isDark) {
    final List<Map<String, dynamic>> opcionesMateriales = [
      {'nombre': 'Ninguno', 'precio': 0},
      {'nombre': 'Opalina Pliego', 'precio': 3500},
      {'nombre': 'Opalina 1/2 Pliego', 'precio': 2000},
      {'nombre': 'Opalina 1/4 Pliego', 'precio': 1000},
      {'nombre': 'Bond Adhesivo Pliego', 'precio': 2500},
      {'nombre': 'Bond Adhesivo 1/2 Pliego', 'precio': 1500},
      {'nombre': 'Bond Adhesivo 1/4 Pliego', 'precio': 1000},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallpaper, color: Color(0xFFF59E0B), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ploteo Interior',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B))),
                  Text('Añade valor base y materiales adicionales',
                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('1. Valor Base (Pesos)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _ploteoInteriorBaseCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                            fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : _bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none))),
                    const SizedBox(height: 24),
                    Text('Material actual: $_ploteoInteriorExtra',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.black54)),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                            onPressed: _addPloteoInterior,
                            icon: const Icon(Icons.add),
                            label: const Text('AGREGAR',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)))))
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. Material Adicional',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: opcionesMateriales.map((m) {
                        final esSel = _ploteoInteriorExtra == m['nombre'];
                        return ChoiceChip(
                          label: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Text(
                                  '${m['nombre']} (+${_money(m['precio'].toDouble())})',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: esSel
                                          ? Colors.white
                                          : isDark ? const Color(0xFFF1F5F9) : Colors.black87))),
                          selected: esSel,
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: isDark ? const Color(0xFF2A3F5F) : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: esSel
                                      ? Colors.transparent
                                      : isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : Colors.grey.shade300)),
                          onSelected: (bool selected) {
                            setState(() {
                              _ploteoInteriorExtra =
                                  selected ? m['nombre'] : 'Ninguno';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDisenoYOtros(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.design_services, color: Color(0xFF8B5CF6), size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diseño & Otros',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6))),
                Text('Agrega servicios personalizados y su valor',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
        const SizedBox(height: 40),
        Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : Colors.grey.shade200)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _disenoDescCtrl,
                style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                decoration: InputDecoration(
                    labelText: 'Descripción del servicio',
                    labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : null,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _disenoValorCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : Colors.black87,
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      labelText: 'Valor (\$)',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : null,
                      border: const OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                      onPressed: () {
                        if (_disenoDescCtrl.text.isEmpty) {
                          _snack('Escribe una descripción');
                          return;
                        }
                        _addCustomItem(_disenoDescCtrl.text, 'diseno_corte',
                            _disenoValorCtrl);
                        _disenoDescCtrl.clear();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('AGREGAR AL CARRITO',
                          style: TextStyle(fontWeight: FontWeight.bold))))
            ],
          ),
        )
      ],
    );
  }
}
