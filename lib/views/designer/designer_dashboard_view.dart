import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import '../../services/pb_service.dart';
import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../models/orden_model.dart';
import '../../models/recordatorio_model.dart';
import '../auth/login_view.dart';
import 'formulario_pos_view.dart';

class DesignerDashboardView extends StatefulWidget {
  const DesignerDashboardView({super.key});

  @override
  State<DesignerDashboardView> createState() => _DesignerDashboardViewState();
}

class _DesignerDashboardViewState extends State<DesignerDashboardView> {
  final _pbService = PocketBaseService();
  late String _disenadar;

  @override
  void initState() {
    super.initState();
    _disenadar = context.read<AuthProvider>().email?.split('@')[0] ?? 'Diseñador';
  }

  void _logout(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    authProvider.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área de Diseño'),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormularioPosView()),
                );
              },
              icon: const Icon(Icons.add_task),
              label: const Text('Crear Ticket Tradicional'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Diseñador: $_disenadar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left side: Órdenes
          Expanded(
            flex: 2,
            child: StreamBuilder<List<Orden>>(
              stream: _pbService.listenOrdenesPorDisenador(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final authModel = _pbService.pb.authStore.model as RecordModel?;
                final userId = authModel?.id ?? '';
                final userName = authModel?.getStringValue('name') ?? '';

                final todasLasOrdenes = snapshot.data ?? [];
                final ordenes = todasLasOrdenes.where((orden) {
                  final isAssignedToMe = (orden.disenador == userId || orden.disenador == userName);
                  final isValidState = orden.estadoDiseno == 'Asignado' || orden.estadoDiseno == 'En Proceso';
                  return isAssignedToMe && isValidState;
                }).toList();

                if (ordenes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay órdenes asignadas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordenes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final orden = ordenes[index];
                    return _OrdenCard(orden: orden, pbService: _pbService);
                  },
                );
              },
            ),
          ),
          
          // Right side: Agenda
          const VerticalDivider(width: 1, thickness: 1),
          Container(
            width: 350,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: _AgendaPanel(pbService: _pbService),
          ),
        ],
      ),
    );
  }
}

class _AgendaPanel extends StatefulWidget {
  final PocketBaseService pbService;

  const _AgendaPanel({required this.pbService});

  @override
  State<_AgendaPanel> createState() => _AgendaPanelState();
}

class _AgendaPanelState extends State<_AgendaPanel> {
  DateTime _diaSeleccionado = DateTime.now();
  List<dynamic> _recordatoriosSincronizados = [];
  final Set<String> _alertasDisparadas = {};
  Timer? _alertaTimer;

  @override
  void initState() {
    super.initState();
    _alertaTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) _verificarAlarmas();
    });
  }

  @override
  void dispose() {
    _alertaTimer?.cancel();
    super.dispose();
  }

  void _verificarAlarmas() {
    if (!mounted) return;
    
    final ahora = DateTime.now();

    for (final dynamic tarea in _recordatoriosSincronizados) {
      final bool completado = (tarea is Recordatorio) ? tarea.completado : (tarea['completado'] == true);
      if (completado) continue;
      
      DateTime horaRec;
      try {
        horaRec = DateTime.parse(tarea['fecha'] ?? tarea.getStringValue('fecha')).toLocal();
      } catch (_) {
        horaRec = (tarea is Recordatorio) ? tarea.fecha.toLocal() : DateTime.now();
      }
      
      final coincideEstricto = ahora.year == horaRec.year && 
                               ahora.month == horaRec.month && 
                               ahora.day == horaRec.day && 
                               ahora.hour == horaRec.hour && 
                               ahora.minute == horaRec.minute;
      
      final String id = (tarea is Recordatorio) ? tarea.id : (tarea['id']?.toString() ?? '');
      
      if (coincideEstricto && !_alertasDisparadas.contains(id)) {
         setState(() {
           _alertasDisparadas.add(id);
         });
         _mostrarAlertaRecordatorio(tarea);
      }
    }
  }

  void _mostrarAlertaRecordatorio(dynamic tarea) {
    if (!mounted) return;
    
    final String titulo = (tarea is Recordatorio) ? tarea.titulo : (tarea['titulo']?.toString() ?? '');
    final String descripcion = (tarea is Recordatorio) ? tarea.descripcion : (tarea['descripcion']?.toString() ?? '');
    
    DateTime horaRec;
    try {
      horaRec = DateTime.parse(tarea['fecha'] ?? tarea.getStringValue('fecha')).toLocal();
    } catch (_) {
      horaRec = (tarea is Recordatorio) ? tarea.fecha.toLocal() : DateTime.now();
    }
    
    final horaFormateada = TimeOfDay.fromDateTime(horaRec).format(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2247),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF3C677).withValues(alpha: 0.3),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.assignment_outlined, color: Color(0xFFF3C677), size: 48),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 4, right: 4),
                        child: Icon(Icons.notifications_active, color: Color(0xFFF3C677), size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'RECORDATORIO DE TAREA PRÓXIMA',
                style: TextStyle(
                  color: Color(0xFFFFE0A5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2E5D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'FECHA LÍMITE: $horaFormateada',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (descripcion.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3C677), Color(0xFFC79542)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Entendido, gracias',
                    style: TextStyle(
                      color: Color(0xFF0D1128),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cambiarDia(int dias) {
    setState(() {
      _diaSeleccionado = _diaSeleccionado.add(Duration(days: dias));
    });
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _diaSeleccionado) {
      setState(() {
        _diaSeleccionado = picked;
      });
    }
  }

  void _mostrarFormulario() {
    showDialog(
      context: context,
      builder: (ctx) => _FormularioRecordatorio(
        pbService: widget.pbService,
        fechaInicial: _diaSeleccionado,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Hoy';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Mañana';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Ayer';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Agenda Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _cambiarDia(-1),
                tooltip: 'Día anterior',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      Text(
                        'Mi Agenda',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_diaSeleccionado),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    onPressed: _seleccionarFecha,
                    tooltip: 'Elegir fecha',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _cambiarDia(1),
                tooltip: 'Día siguiente',
              ),
            ],
          ),
        ),

        // Recordatorios List
        Expanded(
          child: StreamBuilder<List<Recordatorio>>(
            stream: widget.pbService.listenRecordatorios(_diaSeleccionado),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _recordatoriosSincronizados = snapshot.data!;
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar agenda'));
              }

              final recordatorios = snapshot.data ?? [];

              if (recordatorios.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Día libre de tareas',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recordatorios.length,
                itemBuilder: (context, index) {
                  final rec = recordatorios[index];
                  return _RecordatorioCard(
                    recordatorio: rec,
                    pbService: widget.pbService,
                  );
                },
              );
            },
          ),
        ),

        // Bottom Add Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _mostrarFormulario,
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Nuevo Recordatorio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordatorioCard extends StatelessWidget {
  final dynamic recordatorio;
  final PocketBaseService pbService;

  const _RecordatorioCard({
    required this.recordatorio,
    required this.pbService,
  });

  void _mostrarDetalles(BuildContext context) {
    final horaLocal = recordatorio.fecha.toLocal();
    final horaFormateada = TimeOfDay.fromDateTime(horaLocal).format(context);
    final fechaFormateada = '${horaLocal.day.toString().padLeft(2, '0')}/${horaLocal.month.toString().padLeft(2, '0')}/${horaLocal.year}';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.event_note, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Detalle de Tarea', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recordatorio.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('$fechaFormateada - $horaFormateada', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ],
            ),
            if (recordatorio.descripcion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(recordatorio.descripcion, style: const TextStyle(fontSize: 15)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool completado = recordatorio.completado;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: completado 
              ? Colors.green.withValues(alpha: 0.3) 
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      color: completado 
          ? Colors.green.withValues(alpha: 0.05) 
          : Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalles(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  completado ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: completado ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),
                onPressed: () {
                  pbService.actualizarEstadoRecordatorio(recordatorio.id, !completado);
                },
                tooltip: completado ? 'Desmarcar' : 'Marcar completado',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recordatorio.titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration: completado ? TextDecoration.lineThrough : null,
                        color: completado 
                            ? Theme.of(context).colorScheme.onSurfaceVariant 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (recordatorio.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        recordatorio.descripcion,
                        style: TextStyle(
                          fontSize: 13,
                          color: completado 
                              ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5) 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                onPressed: () {
                  pbService.eliminarRecordatorio(recordatorio.id);
                },
                tooltip: 'Eliminar tarea',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormularioRecordatorio extends StatefulWidget {
  final PocketBaseService pbService;
  final DateTime fechaInicial;

  const _FormularioRecordatorio({
    required this.pbService,
    required this.fechaInicial,
  });

  @override
  State<_FormularioRecordatorio> createState() => _FormularioRecordatorioState();
}

class _FormularioRecordatorioState extends State<_FormularioRecordatorio> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.fechaInicial;
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty) return;
    if (_horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona la hora del recordatorio.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final authModel = widget.pbService.pb.authStore.model as RecordModel?;
      final disenadorId = authModel?.id ?? '';
      
      final fechaFinal = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );

      await widget.pbService.crearRecordatorio(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        fecha: fechaFinal,
        disenadorId: disenadorId,
      );

      if (mounted) {
        Navigator.pop(context); // Cierra el formulario
        _mostrarAlertaExito(context); // Muestra la alerta elegante
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarAlertaExito(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Excelente!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recordatorio guardado en tu agenda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_calendar, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text(
                  'Nuevo Recordatorio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tituloCtrl,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: '¿Qué necesitas recordar?',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Detalles adicionales (opcional)',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarFecha,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarHora,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _horaSeleccionada != null
                          ? _horaSeleccionada!.format(context)
                          : 'Hora Exacta',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: _horaSeleccionada != null 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _guardando
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdenCard extends StatefulWidget {
  final Orden orden;
  final PocketBaseService pbService;

  const _OrdenCard({
    required this.orden,
    required this.pbService,
  });

  @override
  State<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends State<_OrdenCard> {
  bool _actualizando = false;

  Future<void> _abrirWhatsApp() async {
    final matches = RegExp(r'\d+').allMatches(widget.orden.cliente);
    final numero = matches.map((m) => m.group(0)).join();
    final url = 'https://wa.me/57$numero';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        
        if (mounted) {
          setState(() => _actualizando = true);
          try {
            await widget.pbService.actualizarEstadoOrden(widget.orden.id, 'En Proceso');
          } finally {
            if (mounted) setState(() => _actualizando = false);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completarOrden() async {
    setState(() => _actualizando = true);
    try {
      await widget.pbService.eliminarOrden(widget.orden.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden completada ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        final nombre = widget.orden.cliente.trim();
        final telefono = widget.orden.whatsappCliente?.trim() ?? '';
        String clienteUnificado = nombre;
        if (nombre.isNotEmpty && telefono.isNotEmpty) {
          clienteUnificado = '$nombre / $telefono';
        } else if (telefono.isNotEmpty) {
          clienteUnificado = telefono;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormularioPosView(
              clienteInicial: clienteUnificado,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.orden.estadoDiseno;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: estado == 'En Proceso' ? Colors.orange[50] : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left side: Ticket and Client
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.orden.ticketLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.orden.cliente,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.orden.whatsappCliente != null && widget.orden.whatsappCliente!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.orden.whatsappCliente!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Center: Status Badge
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: estado == 'Asignado' 
                        ? Colors.blue.withValues(alpha: 0.1) 
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: estado == 'Asignado' ? Colors.blue : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (estado == 'En Proceso') ...[
                        Icon(Icons.lock, size: 12, color: Colors.orange[800]),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        estado,
                        style: TextStyle(
                          color: estado == 'Asignado' ? Colors.blue[700] : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Right side: Actions
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: estado == 'Asignado'
                    ? ElevatedButton.icon(
                        onPressed: _actualizando ? null : _abrirWhatsApp,
                        icon: _actualizando
                            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.chat, size: 16),
                        label: Text(_actualizando ? '...' : 'Atender Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _actualizando ? null : _completarOrden,
                        icon: _actualizando
                            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock, size: 16),
                        label: Text(_actualizando ? '...' : 'Terminar Trabajo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
