import 'package:flutter/material.dart';
import '../../models/orden_model.dart';
import '../../services/pb_service.dart';

class DashboardGerencialView extends StatefulWidget {
  const DashboardGerencialView({super.key});

  @override
  State<DashboardGerencialView> createState() => _DashboardGerencialViewState();
}

class _DashboardGerencialViewState extends State<DashboardGerencialView> {
  final _service = PocketBaseService();
  
  String _searchQuery = '';
  String _selectedDisenador = 'Todos';

  String _mapDisenador(String original) {
    if (original == 'qwf4r7l4ve6nd8e') return 'Ramon';
    if (original == 'ibct9j81py574o4') return 'Cristian';
    return original;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tráfico de Órdenes Asignadas'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar por Nombre o Teléfono',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: StreamBuilder<List<Orden>>(
                    stream: _service.listenTodasLasOrdenesActivas(),
                    builder: (context, snapshot) {
                      // Derive unique designers from the current active orders
                      final data = snapshot.data ?? [];
                      final disenadoresSet = <String>{'Todos'};
                      for (var o in data) {
                        if (o.disenador.isNotEmpty) {
                          disenadoresSet.add(_mapDisenador(o.disenador));
                        }
                      }
                      final disenadoresList = disenadoresSet.toList()..sort();
                      
                      // Ensure selected value is in the list
                      if (!disenadoresList.contains(_selectedDisenador)) {
                        _selectedDisenador = 'Todos';
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedDisenador,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por Diseñador',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        items: disenadoresList.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(d),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDisenador = value ?? 'Todos';
                          });
                        },
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
          
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('OT No.', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Diseñador', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),

          // Data Table
          Expanded(
            child: StreamBuilder<List<Orden>>(
              stream: _service.listenTodasLasOrdenesActivas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error al cargar órdenes: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final todasLasOrdenes = snapshot.data ?? [];

                // Apply Filters
                final ordenesFiltradas = todasLasOrdenes.where((orden) {
                  // Search query filter
                  final clienteStr = orden.cliente.toLowerCase();
                  final matchesSearch = _searchQuery.isEmpty || clienteStr.contains(_searchQuery);
                  
                  // Designer filter
                  final mappedDisenador = _mapDisenador(orden.disenador);
                  final matchesDisenador = _selectedDisenador == 'Todos' || mappedDisenador == _selectedDisenador;

                  return matchesSearch && matchesDisenador;
                }).toList();

                if (ordenesFiltradas.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron órdenes con los filtros actuales.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordenesFiltradas.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final orden = ordenesFiltradas[index];
                    
                    String displayTicket = orden.ticketLabel;
                    if (orden.ticketNo < 0 || orden.ticketNo > 999999) {
                      displayTicket = 'TMP-${(index + 1).toString().padLeft(3, '0')}';
                    }
                    
                    // Separar Nombre y Teléfono (formato esperado: "Nombre / Teléfono")
                    String nombre = orden.cliente;
                    String telefono = '';
                    if (orden.cliente.contains(' / ')) {
                      final parts = orden.cliente.split(' / ');
                      nombre = parts[0].trim();
                      if (parts.length > 1) {
                        telefono = parts[1].trim();
                      }
                    }

                    final String designerName = _mapDisenador(orden.disenador);
                    final bool isRamon = designerName.toLowerCase().contains('ramon') || designerName.toLowerCase().contains('ramón');
                    final bool isCristian = designerName.toLowerCase().contains('cristian');
                    
                    final Color accentColor = isRamon ? Colors.blue : (isCristian ? Colors.orange : Colors.grey);
                    final Color bgColor = isRamon ? Colors.blue.withValues(alpha: 0.05) : (isCristian ? Colors.orange.withValues(alpha: 0.05) : Colors.transparent);

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          left: BorderSide(
                            color: isRamon || isCristian ? accentColor : Colors.transparent,
                            width: 4.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // OT No.
                          Expanded(
                            flex: 1,
                            child: Text(
                              displayTicket,
                              style: TextStyle(fontWeight: FontWeight.bold, color: accentColor != Colors.grey ? accentColor : null),
                            ),
                          ),
                          // Cliente
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Teléfono
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                if (telefono.isNotEmpty) ...[
                                  Icon(Icons.phone, size: 14, color: accentColor != Colors.grey ? accentColor : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    telefono,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ] else ...[
                                  const Text('-', style: TextStyle(color: Colors.grey)),
                                ],
                              ],
                            ),
                          ),
                          // Diseñador
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Icon(Icons.brush, size: 14, color: accentColor != Colors.grey ? accentColor : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  designerName.isNotEmpty ? designerName : 'Sin Asignar',
                                  style: TextStyle(color: accentColor != Colors.grey ? accentColor : null, fontWeight: accentColor != Colors.grey ? FontWeight.w600 : null),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Estado Chip
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _buildEstadoChip(orden),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(Orden orden) {
    String estado = orden.estadoDiseno;
    
    if (orden.estado.toLowerCase() == 'facturado') {
      estado = 'Completado';
    }

    if (estado.isEmpty) {
      estado = 'Pendiente';
    }

    Color chipColor;
    Color bgColor;

    switch (estado.toLowerCase()) {
      case 'asignado':
        chipColor = Colors.blue[700]!;
        bgColor = Colors.blue[50]!;
        break;
      case 'en proceso':
        chipColor = Colors.orange[800]!;
        bgColor = Colors.orange[50]!;
        break;
      case 'completado':
      case 'facturado':
        chipColor = Colors.green[700]!;
        bgColor = Colors.green[50]!;
        estado = 'Completado';
        break;
      default:
        chipColor = Colors.grey[700]!;
        bgColor = Colors.grey[100]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
