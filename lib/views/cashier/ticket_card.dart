import 'package:flutter/material.dart';
import 'package:sistema_ordenes/services/pb_service.dart';
import '../../models/orden_model.dart';
import '../../services/print_service.dart';

class TicketCard extends StatefulWidget {
  final Orden orden;
  final Future<void> Function() onCobrar;
  final Future<void> Function()?
      onAnular; // 🌟 NUEVO: Callback para la eliminación
  final VoidCallback? onImprimir;
  final bool compact;
  final Color accent;

  const TicketCard({
    super.key,
    required this.orden,
    required this.onCobrar,
    this.onAnular, // 🌟 NUEVO
    this.onImprimir,
    this.compact = false,
    this.accent = const Color(0xFF6D28D9),
  });

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  bool _loading = false;

  static const Color _ramonColor = Color(0xFF38BDF8);
  static const Color _cristianColor = Color(0xFFFFA11A);

  Color _accentByDisenador(String d) {
    final x = d.trim().toLowerCase();
    if (x == 'ramon') {
      return _ramonColor;
    }
    if (x == 'cristian') {
      return _cristianColor;
    }
    return widget.accent;
  }

  Color _accentByEstado(Color base, String estado) {
    final e = estado.trim().toLowerCase();
    if (e == 'pagado') {
      return Colors.green;
    }
    return base;
  }

  Future<void> _onCobrar() async {
    setState(() => _loading = true);
    try {
      await widget.onCobrar();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.orden;
    final Color baseAccent = _accentByDisenador(o.disenador);
    final Color accent = _accentByEstado(baseAccent, o.estado);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;

    final textPrimary = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    final textSecondary = theme.textTheme.bodySmall?.color ?? (isDark ? Colors.grey.shade300 : Colors.black54);

    // 🌟 SI NO ES COMPACTO, RENDERIZAMOS EL NUEVO DISEÑO DE FILA ULTRA-PROFESIONAL
    if (!widget.compact) {
      return _buildRowStyleList(o, accent);
    }

    // ===== MODO CUADRÍCULA ORIGINAL (CONSERVA TU ESTILO TICKET DE SIEMPRE) =====
    final double cm = (o.costoMaterial ?? 0).toDouble();
    final double cp = (o.costoPloteo ?? 0).toDouble();
    final double ce = (o.costoExtras ?? 0).toDouble();
    final double pad = widget.compact ? 12.0 : 16.0;
    final double baseFont = widget.compact ? 11.4 : 12.6;

    final TextStyle mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: baseFont,
      height: 1.12,
      color: textPrimary,
    );
    final TextStyle label =
        mono.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.2);
    final TextStyle subtle = mono.copyWith(
        color: textSecondary, fontWeight: FontWeight.w700);
    final TextStyle title = mono.copyWith(
        fontSize: widget.compact ? 14.5 : 18.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.05,
        color: Colors.white);
    final TextStyle totalStyle = mono.copyWith(
        fontSize: widget.compact ? 18.0 : 22.0, fontWeight: FontWeight.w900);
    final border = isDark 
        ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.08);
    final trabajosLabel =
        o.tipoTrabajo.isEmpty ? '—' : o.tipoTrabajo.join(' + ');

    return ClipPath(
      clipper: _ReceiptClipper(
        notchRadius: widget.compact ? 12.0 : 14.0,
        toothWidth: widget.compact ? 10.0 : 12.0,
        toothHeight: widget.compact ? 8.0 : 10.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 12),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.08)),
            if (isDark)
              BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                  color: accent.withValues(alpha: 0.08)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  EdgeInsets.fromLTRB(pad, pad, pad, widget.compact ? 10 : 12),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accent.withValues(alpha: 0.7)]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  )),
              child: Column(
                children: [
                  Text('RECIBO', style: title),
                  const SizedBox(height: 6),
                  Text(o.ticketLabel,
                      style: mono.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: widget.compact ? 12.0 : 13.0)),
                  const SizedBox(height: 4),
                  Text('CÓDIGO: ${o.codigoCobro}',
                      style: mono.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildBody(o, mono, label, subtle, totalStyle,
                            accent, cm, cp, ce, trabajosLabel, isDark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _barcode(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: widget.compact ? 42 : 46,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent,
                              accent.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onCobrar,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('COBRAR / MARCAR PAGADO',
                                  style: mono.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: 170,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accent.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: widget.onImprimir ??
                                  () async => _imprimirTicketDirecto(o, accent),
                              icon: Icon(Icons.print, size: 16, color: accent),
                              label: Text('IMPRIMIR',
                                  style: mono.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w900)),
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                        ),
                        if (widget.onAnular != null)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('¿Anular?'),
                                      content: const Text(
                                          '¿Eliminar ticket permanentemente?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('No')),
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFEF4444)),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Sí')),
                                      ],
                                    ),
                                  );
                                  if (confirmar == true) {
                                    await widget.onAnular!();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Color(0xFFEF4444), size: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 ===== NUEVO DISEÑO MINIMALISTA PARA MODO LISTA HORIZONTAL =====
  Widget _buildRowStyleList(Orden o, Color accent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (isDark)
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: Row(
        children: [
          // 1. Identificador de la Orden (OT)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              o.ticketLabel,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: accent,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Información del Cliente y Diseñador
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  o.cliente.isEmpty ? 'Cliente: Genérico' : o.cliente,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Diseñador: ${o.disenador.isEmpty ? '—' : o.disenador}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3. Lista de Materiales / Trabajos
          Expanded(
            flex: 5,
            child: Text(
              o.materiales.isEmpty ? 'Sin especificaciones' : o.materiales,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(width: 12),

          // 4. Código de Cobro Único
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Cod: ${o.codigoCobro}',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16),

          // 5. Monto Total
          Text(
            '\$${o.saldoPendiente.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isDark ? const Color(0xFFF1F5F9) : Colors.black87),
          ),
          const SizedBox(width: 20),

          // 6. Acciones rápidas (Anular 🗑️, Imprimir 🖨️ y Cobrar)
          if (widget.onAnular != null) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Anular / Eliminar Ticket',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 22),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('¿Anular Ticket?',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                        '¿Deseas eliminar permanentemente el ticket ${o.ticketLabel} de la cola?\n\nEsta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Eliminar Trabajo',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  setState(() => _loading = true);
                  try {
                    await widget.onAnular!();
                  } finally {
                    if (mounted) {
                      setState(() => _loading = false);
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Imprimir Ticket',
            icon: Icon(Icons.print_outlined, color: accent, size: 22),
            onPressed: () async => _imprimirTicketDirecto(o, accent),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _loading ? null : _onCobrar,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('COBRAR',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimirTicketDirecto(Orden o, Color accent) async {
    try {
      final items = await PocketBaseService().obtenerItemsDeOrden(o.id);
      await PrintService.imprimirOrden(orden: o, items: items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Enviando a impresora...'),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al imprimir: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildBody(
      Orden o,
      TextStyle mono,
      TextStyle label,
      TextStyle subtle,
      TextStyle totalStyle,
      Color accent,
      double cm,
      double cp,
      double ce,
      String trabajosLabel,
      bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DashedDivider(),
        const SizedBox(height: 10),
        _kvRow('Cliente', o.cliente, label, mono),
        _kvRow('Diseñador', o.disenador.trim().isEmpty ? '—' : o.disenador,
            label, mono),
        Row(
          children: [
            SizedBox(width: 90, child: Text('Estado', style: label)),
            _estadoChip(o.abono > 0 ? 'Abonado' : 'Pendiente', accent, mono, isDark),
          ],
        ),
        const SizedBox(height: 10),
        const _DashedDivider(),
        const SizedBox(height: 10),
        Text('Detalle', style: label),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _pill(
                  text: trabajosLabel,
                  background: accent.withValues(alpha: 0.10),
                  border: accent.withValues(alpha: 0.24),
                  style: mono.copyWith(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Notas', style: label),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _pill(
                  text: o.materiales.isEmpty ? '—' : o.materiales,
                  background: Colors.deepPurple.withValues(alpha: 0.06),
                  border: Colors.deepPurple.withValues(alpha: 0.16),
                  style: subtle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Material', style: label),
          Text('\$${cm.toStringAsFixed(0)}', style: mono)
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Ploteo', style: label),
          Text('\$${cp.toStringAsFixed(0)}', style: mono)
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Extras', style: label),
          Text('\$${ce.toStringAsFixed(0)}', style: mono)
        ]),
        const SizedBox(height: 10),
        const _DashedDivider(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: label.copyWith(color: subtle.color)),
            Text('\$${o.monto.toStringAsFixed(0)}', style: mono.copyWith(color: subtle.color)),
          ],
        ),
        if (o.abono > 0) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Abono Inicial', style: label.copyWith(color: isDark ? Colors.orangeAccent : Colors.orange.shade800)),
            Text('-\$${o.abono.toStringAsFixed(0)}', style: mono.copyWith(color: isDark ? Colors.orangeAccent : Colors.orange.shade800)),
          ]),
        ],
        const SizedBox(height: 10),
        const _DashedDivider(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SALDO A COBRAR', style: label.copyWith(color: isDark ? Colors.greenAccent : Colors.green.shade700)),
            Text('\$${o.saldoPendiente.toStringAsFixed(0)}', style: totalStyle.copyWith(color: isDark ? Colors.greenAccent : Colors.green.shade700)),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: Text('Gracias por tu compra 💜', style: subtle)),
      ],
    );
  }

  Widget _kvRow(String k, String v, TextStyle label, TextStyle value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(k, style: label)),
          Expanded(child: Text(v.isEmpty ? '—' : v, style: value)),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado, Color accent, TextStyle mono, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: isDark ? accent.withValues(alpha: 0.2) : accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? accent.withValues(alpha: 0.4) : accent.withValues(alpha: 0.25))),
      child: Text(estado.trim(),
          style: mono.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : accent)),
    );
  }

  Widget _pill(
      {required String text,
      required Color background,
      required Color border,
      required TextStyle style}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border)),
      child: Text(text, style: style),
    );
  }

  Widget _barcode() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.10))),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: Row(
        children: List.generate(28, (i) {
          final w = (i % 3 == 0) ? 3.0 : 2.0;
          return Container(
            width: w,
            height: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
                color:
                    Colors.black.withValues(alpha: (i % 2 == 0) ? 0.22 : 0.08),
                borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(double.infinity, 2),
        painter: _DashedLinePainter(
            color: Colors.black.withValues(alpha: 0.20),
            dashWidth: 6,
            dashGap: 5,
            strokeWidth: 2));
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;
  _DashedLinePainter(
      {required this.color,
      required this.dashWidth,
      required this.dashGap,
      required this.strokeWidth});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReceiptClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double toothWidth;
  final double toothHeight;
  _ReceiptClipper(
      {required this.notchRadius,
      required this.toothWidth,
      required this.toothHeight});
  @override
  Path getClip(Size size) {
    final path = Path();
    final r = notchRadius;
    final tw = toothWidth;
    final th = toothHeight;
    path.moveTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.lineTo(size.width - r, 0);
    path.arcToPoint(Offset(size.width, r), radius: Radius.circular(r));
    path.lineTo(size.width, size.height - r - th);
    path.arcToPoint(Offset(size.width - r, size.height - th),
        radius: Radius.circular(r));
    double x = size.width;
    while (x > 0) {
      path.lineTo(x, size.height - th);
      path.lineTo(x - tw / 2, size.height);
      path.lineTo(x - tw, size.height - th);
      x -= tw;
    }
    path.lineTo(r, size.height - th);
    path.arcToPoint(Offset(0, size.height - r - th),
        radius: Radius.circular(r));
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
