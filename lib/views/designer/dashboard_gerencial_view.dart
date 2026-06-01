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

  @override
  void initState() {
    super.initState();
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
        final stats = _calcularEstadisticas(ordenes);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Gerencial'),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GraficoIngresosCostos(stats: stats),
                const SizedBox(height: 24),
                _MedidorDineroEnCalle(stats: stats),
                const SizedBox(height: 24),
                _RankingDisenadores(stats: stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calcularEstadisticas(List<Orden> ordenes) {
    double ingresosTotales = 0;
    double costosTotales = 0;
    double dineroEnCalle = 0;
    final disenadoresData = <String, Map<String, dynamic>>{};

    for (final orden in ordenes) {
      final ingresos = orden.monto;
      final costos = (orden.costoMaterial ?? 0) + (orden.costoPloteo ?? 0);
      final utilidad = ingresos - costos;

      ingresosTotales += ingresos;
      costosTotales += costos;

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

    final topDisenadores = disenadoresData.entries.toList()
      ..sort((a, b) => (b.value['utilidad'] as double).compareTo(a.value['utilidad'] as double));

    return {
      'ingresosTotales': ingresosTotales,
      'costosTotales': costosTotales,
      'utilidadTotal': ingresosTotales - costosTotales,
      'dineroEnCalle': dineroEnCalle,
      'topDisenadores': topDisenadores.take(5).toList(),
    };
  }
}

class _GraficoIngresosCostos extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _GraficoIngresosCostos({required this.stats});

  @override
  Widget build(BuildContext context) {
    final ingresos = (stats['ingresosTotales'] as double) / 1000000;
    final costos = (stats['costosTotales'] as double) / 1000000;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos vs Costos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (ingresos * 1.2),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: ingresos,
                          color: Theme.of(context).colorScheme.primary,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: costos,
                          color: Theme.of(context).colorScheme.secondary,
                          width: 40,
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
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoBox(
                  label: 'Ingresos',
                  value: _formatCurrency(stats['ingresosTotales'] as double),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _InfoBox(
                  label: 'Costos',
                  value: _formatCurrency(stats['costosTotales'] as double),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _InfoBox(
                  label: 'Utilidad',
                  value: _formatCurrency(stats['utilidadTotal'] as double),
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _MedidorDineroEnCalle extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _MedidorDineroEnCalle({required this.stats});

  @override
  Widget build(BuildContext context) {
    final dineroEnCalle = (stats['dineroEnCalle'] as double) / 1000000;
    final maxY = dineroEnCalle * 1.5;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dinero en la Calle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Saldos pendientes por cobrar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
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
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: ${_formatCurrency(stats['dineroEnCalle'] as double)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}

class _RankingDisenadores extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _RankingDisenadores({required this.stats});

  @override
  Widget build(BuildContext context) {
    final topDisenadores = stats['topDisenadores'] as List<MapEntry<String, Map<String, dynamic>>>;

    if (topDisenadores.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Diseñadores',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Sin datos disponibles')),
            ],
          ),
        ),
      );
    }

    final maxUtilidad = topDisenadores.first.value['utilidad'] as double;
    final colors = [
      Colors.amber,
      Colors.grey,
      Colors.orange,
      Colors.lightBlue,
      Colors.pink,
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Diseñadores por Utilidad',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: topDisenadores.length * 50.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: (maxUtilidad / 1000000) * 1.1,
                  barGroups: List.generate(
                    topDisenadores.length,
                    (index) {
                      final utilidad = topDisenadores[index].value['utilidad'] as double;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: utilidad / 1000000,
                            color: colors[index % colors.length],
                            width: 20,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= topDisenadores.length) {
                            return const Text('');
                          }
                          final nombre = topDisenadores[index].key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              nombre.length > 12 ? '${nombre.substring(0, 12)}...' : nombre,
                              style: const TextStyle(fontSize: 10),
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
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(
                topDisenadores.length,
                (index) {
                  final nombre = topDisenadores[index].key;
                  final utilidad = topDisenadores[index].value['utilidad'] as double;
                  final ordenes = topDisenadores[index].value['ordenes'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colors[index % colors.length],
                          radius: 12,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                '$ordenes órdenes',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(utilidad),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors[index % colors.length],
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }
}
