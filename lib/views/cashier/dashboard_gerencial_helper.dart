import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/orden_model.dart';
import '../../services/pb_service.dart';

class DashboardGerencialView extends StatefulWidget {
  const DashboardGerencialView({super.key});

  @override
  State<DashboardGerencialView> createState() => _DashboardGerencialViewState();
}

class _DashboardGerencialViewState extends State<DashboardGerencialView> {
  final _service = PocketBaseService();
  late Future<List<Orden>> _ordenesFuture;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    final hace30Dias = hoy.subtract(const Duration(days: 30));
    _dateRange = DateTimeRange(start: hace30Dias, end: hoy);
    _ordenesFuture = _service.obtenerTodasLasOrdenes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Orden>>(
      future: _ordenesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard Gerencial')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard Gerencial')),
            body: const Center(child: Text('No hay datos disponibles')),
          );
        }

        final ordenes = snapshot.data!;
        final ordenesEnRango = _filtrarPorFecha(ordenes, _dateRange!);
        final stats = _calcularEstadisticas(ordenes, ordenesEnRango);

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard Gerencial'),
                Text('Resumen de indicadores clave del negocio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con selector de fechas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período: ${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _seleccionarFechas(context),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Filtros'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // KPIs en fila
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _KpiCard(
                        title: 'Ingresos',
                        value: _formatCurrency((stats['ingresos'] as num?)?.toDouble() ?? 0.0),
                        icon: Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                        variation: (stats['variacionIngresos'] as num?)?.toDouble() ?? 0.0,
                      ),
                      const SizedBox(width: 16),
                      _KpiCard(
                        title: 'Costos',
                        value: _formatCurrency((stats['costos'] as num?)?.toDouble() ?? 0.0),
                        icon: Icons.production_quantity_limits,
                        color: Theme.of(context).colorScheme.secondary,
                        variation: (stats['variacionCostos'] as num?)?.toDouble() ?? 0.0,
                      ),
                      const SizedBox(width: 16),
                      _KpiCard(
                        title: 'Utilidad',
                        value: _formatCurrency((stats['utilidad'] as num?)?.toDouble() ?? 0.0),
                        icon: Icons.attach_money,
                        color: Colors.green,
                        variation: (stats['variacionUtilidad'] as num?)?.toDouble() ?? 0.0,
                      ),
                      const SizedBox(width: 16),
                      _KpiCard(
                        title: 'Margen de Utilidad',
                        value: '${((stats['margen'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                        icon: Icons.percent,
                        color: Colors.blue,
                        variation: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Gráficas principales
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gráfica Ingresos vs Costos
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ingresos vs Costos',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Comparación del período',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 300,
                                child: _GraficoIngresosCostos(stats: stats),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Dinero en la Calle
                    Expanded(
                      flex: 1,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dinero en la Calle',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Saldos pendientes',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: _MedidorDineroEnCalle(stats: stats),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Total: ${_formatCurrency(stats['dineroEnCalle'])}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Diseñadores
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Top Diseñadores por Utilidad',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ranking de diseñadores generada',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 320,
                          child: _RankingDisenadores(stats: stats),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seleccionarFechas(BuildContext context) async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (rango != null) {
      setState(() {
        _dateRange = rango;
      });
    }
  }

  List<Orden> _filtrarPorFecha(List<Orden> ordenes, DateTimeRange rango) {
    return ordenes.where((o) {
      final fecha = o.created;
      return fecha.isAfter(rango.start) && fecha.isBefore(rango.end.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> _calcularEstadisticas(List<Orden> todasLasOrdenes, List<Orden> ordenesRango) {
    // Período actual
    double ingresosCurrent = 0;
    double costosCurrent = 0;
    double dineroEnCalle = 0;
    final disenadoresData = <String, Map<String, dynamic>>{};

    for (final orden in ordenesRango) {
      final ingresos = orden.monto;
      final costos = (orden.costoMaterial ?? 0) + (orden.costoPloteo ?? 0);
      final utilidad = ingresos - costos;

      ingresosCurrent += ingresos;
      costosCurrent += costos;

      if (orden.estado == 'Pendiente') {
        dineroEnCalle += orden.saldoPendiente;
      }

      final disenador = orden.disenador.trim().isEmpty ? 'Sin Diseñador' : orden.disenador.trim();
      disenadoresData.putIfAbsent(disenador, () => {
        'utilidad': 0.0,
        'ordenes': 0,
      });
      disenadoresData[disenador]!['utilidad'] = (disenadoresData[disenador]!['utilidad'] as double) + utilidad;
      disenadoresData[disenador]!['ordenes'] = (disenadoresData[disenador]!['ordenes'] as int) + 1;
    }

    // Período anterior (para variación)
    final hace60Dias = _dateRange!.start.subtract(Duration(days: (_dateRange!.end.difference(_dateRange!.start).inDays)));
    final periodoAnterior = DateTimeRange(start: hace60Dias, end: _dateRange!.start);
    final ordenesAnterior = _filtrarPorFecha(todasLasOrdenes, periodoAnterior);

    double ingresosAnterior = 0;
    double costosAnterior = 0;
    for (final orden in ordenesAnterior) {
      ingresosAnterior += orden.monto;
      costosAnterior += (orden.costoMaterial ?? 0) + (orden.costoPloteo ?? 0);
    }

    final utilidadActual = ingresosCurrent - costosCurrent;
    final utilidadAnterior = ingresosAnterior - costosAnterior;
    final margen = ingresosCurrent > 0 ? (utilidadActual / ingresosCurrent) * 100 : 0;

    final variacionIngresos = ingresosAnterior > 0 ? ((ingresosCurrent - ingresosAnterior) / ingresosAnterior) * 100 : 0;
    final variacionCostos = costosAnterior > 0 ? ((costosCurrent - costosAnterior) / costosAnterior) * 100 : 0;
    final variacionUtilidad = utilidadAnterior > 0 ? ((utilidadActual - utilidadAnterior) / utilidadAnterior) * 100 : 0;

    final topDisenadores = disenadoresData.entries.toList()
      ..sort((a, b) => (b.value['utilidad'] as double).compareTo(a.value['utilidad'] as double));

    return {
      'ingresos': ingresosCurrent,
      'costos': costosCurrent,
      'utilidad': utilidadActual,
      'margen': margen,
      'dineroEnCalle': dineroEnCalle,
      'topDisenadores': topDisenadores.take(5).toList(),
      'variacionIngresos': variacionIngresos,
      'variacionCostos': variacionCostos,
      'variacionUtilidad': variacionUtilidad,
    };
  }

  String _formatDate(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')} ${_meses[fecha.month - 1]} ${fecha.year}';
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  final List<String> _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double variation;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.variation,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = variation >= 0;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (variation != 0)
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${variation.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'vs. período anterior',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GraficoIngresosCostos extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _GraficoIngresosCostos({required this.stats});

  @override
  Widget build(BuildContext context) {
    final ingresos = (stats['ingresos'] as double) / 1000000;
    final costos = (stats['costos'] as double) / 1000000;
    final maxY = (ingresos * 1.3).clamp(0.0, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: ingresos,
                color: Theme.of(context).colorScheme.primary,
                width: 48,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: costos,
                color: Theme.of(context).colorScheme.secondary,
                width: 48,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('Ingresos');
                if (value == 1) return const Text('Costos');
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(1)}M');
              },
              reservedSize: 50,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class _MedidorDineroEnCalle extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _MedidorDineroEnCalle({required this.stats});

  @override
  Widget build(BuildContext context) {
    final dineroEnCalle = (stats['dineroEnCalle'] as double) / 1000000;
    final maxY = (dineroEnCalle * 1.5).clamp(0.0001, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: maxY,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: dineroEnCalle,
                color: Colors.orange,
                width: 60,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return const Text('Pendiente');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(1)}M');
              },
              reservedSize: 50,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class _RankingDisenadores extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _RankingDisenadores({required this.stats});

  @override
  Widget build(BuildContext context) {
    final topDisenadores = stats['topDisenadores'] as List<MapEntry<String, Map<String, dynamic>>>;

    if (topDisenadores.isEmpty) {
      return const Center(child: Text('Sin datos disponibles'));
    }

    final colors = [
      Colors.amber,
      Colors.grey,
      Colors.orange,
      Colors.lightBlue,
      Colors.pink,
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: ((topDisenadores.first.value['utilidad'] as num?)?.toDouble() ?? 0.0) / 1000000 * 1.1,
        barGroups: List.generate(
          topDisenadores.length,
          (index) {
            final utilidad = (topDisenadores[index].value['utilidad'] as num?)?.toDouble() ?? 0.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: utilidad / 1000000,
                  color: colors[index % colors.length],
                  width: 16,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                ),
              ],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= topDisenadores.length) return const Text('');
                final nombre = topDisenadores[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    nombre.length > 10 ? '${nombre.substring(0, 10)}...' : nombre,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}M',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
