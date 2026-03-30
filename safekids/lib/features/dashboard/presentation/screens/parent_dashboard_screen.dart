import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../child_profile/presentation/screens/profiles_screen.dart';
import '../../../screen_time/presentation/screens/screen_time_screen.dart';
import '../../../app_control/presentation/screens/app_control_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const ProfilesScreen(),
    const ScreenTimeScreen(),
    const AppControlScreen(),
    const _ComingSoon(icon: Icons.location_on_rounded, label: 'Ubicación'),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4FF),

      // ── APP BAR ──────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D3A6B)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Color(0xFF7B9FFF), size: 22),
            SizedBox(width: 8),
            Text(
              'SafeKids',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A6B),
              ),
            ),
          ],
        ),
        actions: [
          // Notificación rápida
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF2D3A6B)),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── DRAWER ───────────────────────────────────────
      drawer: _ParentDrawer(
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
      ),

      // ── BODY ─────────────────────────────────────────
      body: _screens[_currentIndex],

      // ── BOTTOM NAV ───────────────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.people_rounded, label: 'Hijos', index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.access_time_rounded, label: 'Tiempo', index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.apps_rounded, label: 'Apps', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.location_on_rounded, label: 'Ubicación', index: 3, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.bar_chart_rounded, label: 'Reportes', index: 4, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── DRAWER DEL PADRE ─────────────────────────────────────────────

class _ParentDrawer extends StatelessWidget {
  final VoidCallback onClose;
  const _ParentDrawer({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [

            // Header del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B9FFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 30),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF8A94B2)),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Papá / Mamá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A6B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'padre@email.com',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF8A94B2)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6ECFB5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '👨‍👧 Rol: Padre/Madre',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3A9E87),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Opciones del menú
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.people_rounded,
                    label: 'Mis hijos',
                    subtitle: '2 perfiles vinculados',
                    color: const Color(0xFF7B9FFF),
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.phonelink_rounded,
                    label: 'Vincular dispositivo',
                    subtitle: 'Agregar celular de hijo/a',
                    color: const Color(0xFF6ECFB5),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/link-device');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones',
                    subtitle: '3 alertas sin leer',
                    color: const Color(0xFFFFB347),
                    badge: '3',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Configuración',
                    subtitle: 'Cuenta y preferencias',
                    color: const Color(0xFF8A94B2),
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Ayuda',
                    subtitle: 'Preguntas frecuentes',
                    color: const Color(0xFF8A94B2),
                    onTap: () => Navigator.pop(context),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFE8ECF8)),
                  ),

                  // Salir SIN cerrar sesión
                  _DrawerItem(
                    icon: Icons.minimize_rounded,
                    label: 'Minimizar app',
                    subtitle: 'Volver al inicio sin cerrar sesión',
                    color: const Color(0xFF8A94B2),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Cerrar sesión al fondo
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFFFF6B6B), size: 18),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFFFF6B6B), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cerrar sesión?',
            style: TextStyle(
                color: Color(0xFF2D3A6B),
                fontWeight: FontWeight.w600)),
        content: const Text(
          'Si cerrás sesión, el monitoreo seguirá activo en el celular del hijo hasta que se desconecte manualmente.',
          style: TextStyle(
              color: Color(0xFF8A94B2), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8A94B2))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ───────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3A6B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF8A94B2)),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB347).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFB347),
                ),
              ),
            )
          : const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFB0BAD3), size: 18),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7B9FFF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? const Color(0xFF7B9FFF)
                    : const Color(0xFFB0BAD3),
                size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF7B9FFF)
                    : const Color(0xFFB0BAD3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ComingSoon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFF7B9FFF), size: 36),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A6B))),
          const SizedBox(height: 8),
          const Text('Próximamente',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2))),
        ],
      ),
    );
  }
}