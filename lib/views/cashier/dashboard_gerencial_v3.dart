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
  DateTime? _selectedDate;
  final Set<String> selectedOrderIds = {};
  bool _isDeleting = false;

  String _mapDisenador(String original) {
    if (original == 'qwf4r7l4ve6nd8e') return 'Ramon';
    if (original == 'ibct9j81py574o4') return 'Cristian';
    return original;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _eliminarSeleccionados() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ocultar Órdenes'),
        content: Text('¿Está seguro de que desea ocultar del tráfico las ${selectedOrderIds.length} órdenes seleccionadas? (Podrá buscarlas luego).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ocultar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      for (final id in selectedOrderIds) {
        await _service.ocultarOrdenTrafico(id);
      }
      if (mounted) {
        setState(() {
          selectedOrderIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Órdenes ocultadas correctamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ocultar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tráfico de Órdenes Asignadas'),
        elevation: 0,
        actions: [
          if (selectedOrderIds.isNotEmpty)
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Eliminar seleccionados',
                    onPressed: _eliminarSeleccionados,
                  ),
        ],
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
                      final data = snapshot.data ?? [];
                      final disenadoresSet = <String>{'Todos'};
                      for (var o in data) {
                        if (o.disenador.isNotEmpty) {
                          disenadoresSet.add(_mapDisenador(o.disenador));
                        }
                      }
                      final disenadoresList = disenadoresSet.toList()..sort();
                      
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
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_selectedDate == null ? Icons.calendar_today : Icons.event_busy, color: _selectedDate == null ? null : Colors.red),
                  tooltip: _selectedDate == null ? 'Filtrar por Fecha' : 'Quitar Filtro de Fecha',
                  onPressed: () {
                    if (_selectedDate == null) {
                      _pickDate();
                    } else {
                      setState(() {
                        _selectedDate = null;
                      });
                    }
                  },
                ),
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

                var todasLasOrdenes = snapshot.data ?? [];

                if (_searchQuery.isEmpty) {
                  todasLasOrdenes = todasLasOrdenes.where((orden) => orden.ocultoTrafico != true).toList();
                }

                // Apply Filters
                final ordenesFiltradas = todasLasOrdenes.where((orden) {
                  final clienteStr = orden.cliente.toLowerCase();
                  final telefonoStr = orden.whatsappCliente?.toLowerCase() ?? '';
                  final searchQueryLower = _searchQuery.toLowerCase();
                  
                  final matchesSearch = _searchQuery.isEmpty || 
                                        clienteStr.contains(searchQueryLower) || 
                                        telefonoStr.contains(searchQueryLower);
                  
                  final mappedDisenador = _mapDisenador(orden.disenador);
                  final matchesDisenador = _selectedDisenador == 'Todos' || mappedDisenador == _selectedDisenador;

                  bool matchesDate = true;
                  if (_selectedDate != null) {
                    final d = orden.created.toLocal();
                    matchesDate = d.year == _selectedDate!.year && 
                                  d.month == _selectedDate!.month && 
                                  d.day == _selectedDate!.day;
                  }

                  return matchesSearch && matchesDisenador && matchesDate;
                }).toList();

                final bool allSelected = ordenesFiltradas.isNotEmpty &&
                    ordenesFiltradas.every((o) => selectedOrderIds.contains(o.id));

                return Column(
                  children: [
                    // Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Checkbox(
                              value: allSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedOrderIds.addAll(ordenesFiltradas.map((e) => e.id));
                                  } else {
                                    selectedOrderIds.removeAll(ordenesFiltradas.map((e) => e.id));
                                  }
                                });
                              },
                            ),
                          ),
                          const Expanded(flex: 1, child: Text('OT No.', style: TextStyle(fontWeight: FontWeight.bold))),
                          const Expanded(flex: 2, child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                          const Expanded(flex: 2, child: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                          const Expanded(flex: 2, child: Text('Diseñador', style: TextStyle(fontWeight: FontWeight.bold))),
                          const Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ),

                    if (ordenesFiltradas.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No se encontraron órdenes con los filtros actuales.'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: ordenesFiltradas.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final orden = ordenesFiltradas[index];
                            
                            String displayTicket = orden.ticketLabel;
                            if (orden.ticketNo < 0 || orden.ticketNo > 999999) {
                              displayTicket = 'TMP-${(index + 1).toString().padLeft(3, '0')}';
                            }
                            
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
                            final bool isSelected = selectedOrderIds.contains(orden.id);

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : bgColor,
                                border: Border(
                                  left: BorderSide(
                                    color: isRamon || isCristian ? accentColor : Colors.transparent,
                                    width: 4.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            selectedOrderIds.add(orden.id);
                                          } else {
                                            selectedOrderIds.remove(orden.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      displayTicket,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: accentColor != Colors.grey ? accentColor : null),
                                    ),
                                  ),
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
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(Orden orden) {
    String estado = orden.estadoDiseno.trim();

    if (estado.isEmpty) {
      estado = 'Asignado';
    }

    Color chipColor;
    Color bgColor;

    switch (estado.toLowerCase()) {
      case 'asignado':
        chipColor = Colors.blue[700]!;
        bgColor = Colors.blue[50]!;
        estado = 'Asignado';
        break;
      case 'en proceso':
        chipColor = Colors.orange[800]!;
        bgColor = Colors.orange[50]!;
        estado = 'En Proceso';
        break;
      case 'completado':
      case 'listo':
        chipColor = Colors.green[700]!;
        bgColor = Colors.green[50]!;
        estado = 'Terminado';
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
