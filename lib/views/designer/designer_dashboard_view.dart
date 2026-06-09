import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../services/pb_service.dart';
import '../../services/auth_provider.dart';
import '../../models/orden_model.dart';
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
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Orden>>(
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
