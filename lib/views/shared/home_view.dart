import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_provider.dart';
import '../../services/theme_provider.dart';
import '../../services/pb_service.dart';
import '../auth/login_view.dart';
import '../designer/designer_dashboard_view.dart';
import '../cashier/dashboard_gerencial_v3.dart';
import '../cashier/lista_pendientes_view.dart';
import '../cashier/lista_pagados_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  void _logout(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    authProvider.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  void _navigateToModule(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isDisenador && !authProvider.isAdmin) {
          return const DesignerDashboardView();
        }

        return Scaffold(
          body: Row(
            children: [
              // Sidebar
              SizedBox(
                width: 200,
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.print,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sistema de',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900)),
                                Text('Trabajos',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Menu items
                      _SidebarItem(
                        icon: Icons.home,
                        label: 'Inicio',
                        isSelected: _selectedIndex == 0,
                        onTap: () => _navigateToModule(0),
                      ),
                      _SidebarItem(
                        icon: Icons.brush,
                        label: 'Área de Diseño',
                        isSelected: _selectedIndex == 1,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DesignerDashboardView())),
                      ),
                      if (authProvider.isAdmin) ...[
                        _SidebarItem(
                          icon: Icons.point_of_sale,
                          label: 'Área de Caja',
                          isSelected: _selectedIndex == 2,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ListaPendientesView())),
                        ),
                        _SidebarItem(
                          icon: Icons.receipt_long,
                          label: 'Inventario del Día',
                          isSelected: _selectedIndex == 3,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ListaPagadosView())),
                        ),
                        _SidebarItem(
                          icon: Icons.analytics,
                          label: 'Dashboard Gerencial',
                          isSelected: _selectedIndex == 4,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const DashboardGerencialView())),
                        ),
                      ],

                      const Spacer(),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Sistema Seguro',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                        Text('Conectado',
                                            style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    // Header superior
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Theme.of(context).dividerColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenido, ${authProvider.email?.split('@')[0]}! 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestiona y monitorea todas las áreas de tu negocio desde aquí.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {}),
                              IconButton(
                                  icon: const Icon(Icons.notifications),
                                  onPressed: () {}),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    _logout(context);
                                  } else if (value == 'theme') {
                                    context.read<ThemeProvider>().toggleTheme();
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  final themeProvider =
                                      context.read<ThemeProvider>();
                                  return [
                                    PopupMenuItem(
                                      value: 'theme',
                                      child: Row(
                                        children: [
                                          Icon(
                                              themeProvider.isDarkMode
                                                  ? Icons.light_mode
                                                  : Icons.dark_mode,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Text(themeProvider.isDarkMode
                                              ? 'Modo Claro'
                                              : 'Modo Oscuro'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'logout',
                                      child: Row(children: [
                                        Icon(Icons.logout, size: 18),
                                        SizedBox(width: 8),
                                        Text('Cerrar Sesión')
                                      ]),
                                    ),
                                  ];
                                },
                                child: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: const Icon(Icons.person,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Contenido scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (authProvider.isAdmin) ...[
                              const _DespachoRapidoBar(),
                              const SizedBox(height: 24),
                              // KPIs
                              const SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _KpiSmallCard(
                                        title: 'Órdenes hoy',
                                        value: '24',
                                        change: '+12%',
                                        icon: Icons.receipt),
                                    _KpiSmallCard(
                                        title: 'Pendientes de cobro',
                                        value: '8',
                                        change: '-5%',
                                        icon: Icons.hourglass_empty),
                                    _KpiSmallCard(
                                        title: 'Pagados hoy',
                                        value: '16',
                                        change: '+8%',
                                        icon: Icons.check_circle),
                                    _KpiSmallCard(
                                        title: 'Ventas del día',
                                        value: '\$12,450',
                                        change: '+15%',
                                        icon: Icons.trending_up),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Módulos
                            Text('Módulos Principales',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),

                            GridView(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 125,
                              ),
                              children: [
                                if (authProvider.isAdmin ||
                                    authProvider.isDisenador)
                                  _ModuleCardCompact(
                                    title: 'Área de Diseño',
                                    description:
                                        'Crea nuevas órdenes, gestiona proyectos y tickets de diseño.',
                                    icon: Icons.brush,
                                    color: const Color(0xFF3257D6),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const DesignerDashboardView())),
                                  ),
                                if (authProvider.isAdmin ||
                                    authProvider.isCajero)
                                  _ModuleCardCompact(
                                    title: 'Área de Caja',
                                    description:
                                        'Cobra pendientes, registra pagos y emite comprobantes.',
                                    icon: Icons.point_of_sale,
                                    color: const Color(0xFF1F7A3A),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ListaPendientesView())),
                                  ),
                                if (authProvider.isAdmin ||
                                    authProvider.isCajero)
                                  _ModuleCardCompact(
                                    title: 'Inventario del Día',
                                    description:
                                        'Consulta pagos, aplica filtros y exporta a Excel.',
                                    icon: Icons.receipt_long,
                                    color: const Color(0xFF1F2A44),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ListaPagadosView())),
                                  ),
                                if (authProvider.isAdmin)
                                  _ModuleCardCompact(
                                    title: 'Dashboard Gerencial',
                                    description:
                                        'Visualiza analíticas, métricas y reportes clave del negocio.',
                                    icon: Icons.analytics,
                                    color: const Color(0xFF6C3B8D),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const DashboardGerencialView())),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Franja de Clima y Consejo anclada estrictamente al fondo
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _DailyAdviceAndWeather(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DespachoRapidoBar extends StatefulWidget {
  const _DespachoRapidoBar();

  @override
  State<_DespachoRapidoBar> createState() => _DespachoRapidoBarState();
}

class _DespachoRapidoBarState extends State<_DespachoRapidoBar> {
  final _pbService = PocketBaseService();
  final _whatsappCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  bool _enviando = false;
  bool _cargandoDisenadores = true;
  List<Map<String, String>> _disenadores = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDisenadores();
    });
  }

  Future<void> _cargarDisenadores() async {
    try {
      final res = await _pbService.pb.collection('users').getFullList();
      debugPrint('PB RAW: ${res.length}');

      List<Map<String, String>> combinados = [];
      for (final user in res) {
        debugPrint('Evaluando: ${user.data}');
        final rolString = user.getStringValue('rol').toLowerCase();
        final rolData = (user.data['rol']?.toString() ?? '').toLowerCase();

        if (rolString == 'disenador' ||
            rolString == 'diseñador' ||
            rolData == 'disenador' ||
            rolData == 'diseñador') {
          String name = user.getStringValue('name');
          if (name.isEmpty) {
            name = user.data['name']?.toString() ?? '';
          }
          if (name.isEmpty) {
            name = user.getStringValue('username');
          }
          if (name.isEmpty) {
            name = user.data['username']?.toString() ?? 'Diseñador';
          }

          combinados.add({
            'id': user.id,
            'nombre': name,
          });
        }
      }

      // Contingencia temporal quemada
      if (res.isEmpty || combinados.isEmpty) {
        combinados = [
          {'id': 'temp_cristian', 'nombre': 'Cristian'},
          {'id': 'temp_ramon', 'nombre': 'Ramón'},
        ];
      }

      if (mounted) {
        setState(() {
          _disenadores = combinados;
          _cargandoDisenadores = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando diseñadores: $e');
      if (mounted) {
        setState(() {
          _disenadores = [
            {'id': 'temp_cristian', 'nombre': 'Cristian'},
            {'id': 'temp_ramon', 'nombre': 'Ramón'},
          ];
          _cargandoDisenadores = false;
        });
      }
    }
  }

  Future<void> _crearOrdenRapida(
      String disenadorId, String disenadorNombre) async {
    final nombre = _clienteCtrl.text.trim();
    final whatsapp = _whatsappCtrl.text.trim();

    if (nombre.isEmpty || whatsapp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final clienteUnificado = '$nombre / $whatsapp';

    setState(() => _enviando = true);
    try {
      await _pbService.crearOrdenRapida(
        cliente: clienteUnificado,
        whatsappCliente: whatsapp,
        disenadorId: disenadorId,
      );

      if (mounted) {
        _clienteCtrl.clear();
        _whatsappCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Orden asignada a $disenadorNombre'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Despacho Rápido',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clienteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Nombre del cliente',
                    prefixIcon: const Icon(Icons.person, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _whatsappCtrl,
                  decoration: InputDecoration(
                    hintText: '300XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              if (_enviando || _cargandoDisenadores)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _disenadores.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilledButton.icon(
                        onPressed: () =>
                            _crearOrdenRapida(d['id']!, d['nombre']!),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: Text(d['nombre']!,
                            style: const TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 36),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiSmallCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;

  const _KpiSmallCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              Icon(icon,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(change,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ModuleCardCompact extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCardCompact({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.75)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  color: color.withValues(alpha: 0.2)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  Icon(Icons.arrow_forward,
                      color: Colors.white.withValues(alpha: 0.7), size: 16),
                ],
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Ir al módulo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingSunIcon extends StatefulWidget {
  const _PulsingSunIcon();

  @override
  State<_PulsingSunIcon> createState() => _PulsingSunIconState();
}

class _PulsingSunIconState extends State<_PulsingSunIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.yellowAccent.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.wb_sunny, color: Colors.yellowAccent, size: 24),
      ),
    );
  }
}

class _DailyAdviceAndWeather extends StatefulWidget {
  const _DailyAdviceAndWeather();

  @override
  State<_DailyAdviceAndWeather> createState() => _DailyAdviceAndWeatherState();
}

class _DailyAdviceAndWeatherState extends State<_DailyAdviceAndWeather> {
  Future<Map<String, String>>? _dataFuture;

  static const List<String> _proverbs = [
    "El temor del Señor es el principio del conocimiento. (Proverbios 1:7)",
    "Confía en el Señor de todo corazón, y no en tu propia inteligencia. (Proverbios 3:5)",
    "No te creas demasiado sabio; teme al Señor y apártate del mal. (Proverbios 3:7)",
    "Honra al Señor con tus riquezas y con los primeros frutos de tus cosechas. (Proverbios 3:9)",
    "El que anda con sabios, sabio será; mas el que se junta con necios será quebrantado. (Proverbios 13:20)",
    "La respuesta amable calma el enojo, pero la agresiva echa leña al fuego. (Proverbios 15:1)",
    "El corazón alegre hermosea el rostro, pero el dolor del corazón abate el espíritu. (Proverbios 15:13)",
    "El corazón del hombre traza su rumbo, pero sus pasos los dirige el Señor. (Proverbios 16:9)",
    "El que es lento para la ira vale más que el valiente. (Proverbios 16:32)",
    "El amigo ama en todo momento; en tiempos de angustia es como un hermano. (Proverbios 17:17)",
    "El que perdona la ofensa cultiva el amor; el que insiste en la ofensa divide a los amigos. (Proverbios 17:9)",
    "Aun el necio, si calla, es tenido por sabio; por inteligente, si cierra los labios. (Proverbios 17:28)",
    "El nombre del Señor es una torre inexpugnable; a ella corren los justos y se ponen a salvo. (Proverbios 18:10)",
    "El que halla esposa halla la felicidad: muestras de su favor le ha dado el Señor. (Proverbios 18:22)",
    "Muchos son los planes en el corazón del hombre, pero el propósito del Señor es el que prevalece. (Proverbios 19:21)",
    "El vino es un burlón, y la bebida embriagante, un alborotador. (Proverbios 20:1)",
    "Instruye al niño en el camino correcto, y aun en su vejez no lo abandonará. (Proverbios 22:6)",
    "El prudente ve el peligro y lo evita; el inexperto sigue adelante y sufre las consecuencias. (Proverbios 22:3)",
    "No te afanes acumulando riquezas; no te obsesiones con ellas. (Proverbios 23:4)",
    "Porque cual es su pensamiento en su corazón, tal es él. (Proverbios 23:7)",
    "Con sabiduría se edifica una casa, y con prudencia se afianza. (Proverbios 24:3)",
    "No te alegres cuando caiga tu enemigo, ni se regocije tu corazón cuando tropiece. (Proverbios 24:17)",
    "Manzana de oro con figuras de plata es la palabra dicha como conviene. (Proverbios 25:11)",
    "Como perro que vuelve a su vómito, así es el necio que repite su necedad. (Proverbios 26:11)",
    "No te jactes del día de mañana, porque no sabes qué dará de sí el día. (Proverbios 27:1)",
    "Fieles son las heridas del que ama, pero engañosos los besos del enemigo. (Proverbios 27:6)",
    "El hierro se afila con el hierro, y el hombre en el trato con el hombre. (Proverbios 27:17)",
    "El impío huye sin que nadie lo persiga, pero el justo está confiado como un león. (Proverbios 28:1)",
    "El que encubre sus pecados no prosperará, pero el que los confiesa y se aparta alcanzará misericordia. (Proverbios 28:13)",
    "El que confía en su propio corazón es un necio, pero el que camina en sabiduría será librado. (Proverbios 28:26)",
    "Toda palabra de Dios es limpia; Él es escudo a los que en Él esperan. (Proverbios 30:5)",
    "Engañosa es la gracia y vana la hermosura; la mujer que teme al Señor, esa será alabada. (Proverbios 31:30)",
  ];

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, String>> _fetchData() async {
    final int day = DateTime.now().day;
    final String proverb = _proverbs[day % _proverbs.length];

    String temp = '28.0°C'; // Fallback realista
    String pop = '0.0 mm'; // Fallback realista
    String humidity = '60%'; // Fallback realista
    String wind = '12.0 km/h'; // Fallback realista

    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=7.8939&longitude=-72.5078&current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['current'] != null) {
          temp = '${data['current']['temperature_2m']}°C';
          pop = '${data['current']['precipitation']} mm';
          humidity = '${data['current']['relative_humidity_2m']}%';
          wind = '${data['current']['wind_speed_10m']} km/h';
        }
      }
    } catch (_) {
      // Ignorar error y usar fallbacks
    }

    return {
      'proverb': proverb,
      'temp': temp,
      'pop': pop,
      'humidity': humidity,
      'wind': wind,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data ??
            {
              'proverb': _proverbs[DateTime.now().day % _proverbs.length],
              'temp': '28.0°C',
              'pop': '0.0 mm',
              'humidity': '60%',
              'wind': '12.0 km/h'
            };

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.05),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.cyanAccent))
              : Row(
                  children: [
                    // 1. Izquierda: Sol pulsante y texto de clima
                    const _PulsingSunIcon(),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            data['temp']!,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lluvia: ${data['pop']}',
                                  style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      height: 1.1)),
                              Text('Humedad: ${data['humidity']}',
                                  style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      height: 1.1)),
                              Text('Viento: ${data['wind']}',
                                  style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      height: 1.1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 2. Centro: Frecuencia cardíaca
                    const Icon(Icons.monitor_heart,
                        color: Colors.blueAccent, size: 26),
                    const SizedBox(width: 16),

                    // 3. Derecha: Bombilla con glow y consejo
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.lightbulb,
                                color: Colors.amber, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['proverb']!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[300],
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
