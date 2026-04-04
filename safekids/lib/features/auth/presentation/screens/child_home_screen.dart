import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../child_profile/presentation/providers/child_provider.dart';
import '../../../child_profile/presentation/providers/link_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _obscurePassword = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Marcar como online al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childRepositoryProvider).updateOnlineStatus(true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Marcar como offline al salir
    ref.read(childRepositoryProvider).updateOnlineStatus(false);
    super.dispose();
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  Color _timerColor(double progress) {
    if (progress > 0.5) return const Color(0xFF6ECFB5);
    if (progress > 0.2) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  void _showChildLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cerrar sesión?',
            style: TextStyle(color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
        content: const Text(
          'Si cerrás sesión, tu padre/madre será notificado. ¿Estás seguro?',
          style: TextStyle(color: Color(0xFF8A94B2), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8A94B2))),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(childRepositoryProvider).updateOnlineStatus(false);
              await ref.read(authRepositoryProvider).signOut();
              if (!mounted) return;
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCode() async {
    try {
      final code = await ref.read(linkRepositoryProvider).generateLinkCode();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Código generado: $code'),
        backgroundColor: const Color(0xFF6ECFB5),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al generar código'),
        backgroundColor: Color(0xFFFF6B6B),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(childProfileProvider);
    final screenTimeAsync = ref.watch(screenTimeRulesProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final blockedAppsAsync = ref.watch(blockedAppsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D3A6B)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Color(0xFF6ECFB5), size: 22),
            SizedBox(width: 8),
            Text('SafeKids',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3A6B))),
          ],
        ),
      ),

      drawer: _buildDrawer(userDataAsync, profileAsync),

      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6ECFB5)),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            final isLinked = profile != null && profile['parentId'] != null;
            final isLocked = profile?['isDeviceLocked'] ?? false;

            // Si el cel está bloqueado totalmente
            if (isLocked) {
              return _buildLockedScreen();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header con nombre
                  userDataAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (userData) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, ${userData?['name'] ?? 'Hola'} 👋',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3A6B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLinked ? 'Dispositivo protegido' : 'Sin vincular',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isLinked
                                      ? const Color(0xFF6ECFB5)
                                      : const Color(0xFFFFB347)),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6ECFB5).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Color(0xFF6ECFB5), size: 24),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (isLinked) ...[
                    // TEMPORIZADOR con datos reales
                    screenTimeAsync.when(
                      loading: () => const CircularProgressIndicator(
                          color: Color(0xFF6ECFB5)),
                      error: (_, __) => const SizedBox(),
                      data: (rules) {
                        final limit = (rules?['dailyLimitMinutes'] ?? 120).toInt();
                        final used = (rules?['usedTodayMinutes'] ?? 0).toInt();
                        final remaining = (limit - used).clamp(0, limit);
                        final progress = limit > 0 ? used / limit : 0.0;
                        final color = _timerColor(1.0 - progress);

    
                        return Column(
                          children: [
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.25),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 190,
                                      height: 190,
                                      child: CircularProgressIndicator(
                                        value: (1.0 - progress).clamp(0.0, 1.0),
                                        strokeWidth: 12,
                                        backgroundColor: color.withOpacity(0.15),
                                        valueColor: AlwaysStoppedAnimation(color),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatMinutes(remaining),
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('tiempo restante',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF8A94B2))),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6ECFB5)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text('✓ Vinculado',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF6ECFB5),
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Info chips
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE8ECF8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _InfoChip(
                                    label: 'Límite hoy',
                                    value: _formatMinutes(limit),
                                    icon: Icons.access_time_rounded,
                                    color: const Color(0xFF7B9FFF),
                                  ),
                                  Container(width: 1, height: 36, color: const Color(0xFFE8ECF8)),
                                  _InfoChip(
                                    label: 'Usado',
                                    value: _formatMinutes(used),
                                    icon: Icons.bar_chart_rounded,
                                    color: const Color(0xFFFFB347),
                                  ),
                                  Container(width: 1, height: 36, color: const Color(0xFFE8ECF8)),
                                  blockedAppsAsync.when(
                                    loading: () => const _InfoChip(
                                        label: 'Apps libres',
                                        value: '...',
                                        icon: Icons.apps_rounded,
                                        color: Color(0xFF6ECFB5)),
                                    error: (_, __) => const SizedBox(),
                                    data: (blocked) => _InfoChip(
                                      label: 'Apps bloq.',
                                      value: '${blocked.length}',
                                      icon: Icons.block_rounded,
                                      color: const Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Mensaje
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B9FFF).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFF7B9FFF).withOpacity(0.2)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.info_outline_rounded,
                                      color: Color(0xFF7B9FFF), size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tu padre/madre administra este dispositivo. Usá el tiempo sabiamente 😊',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF5578CC),
                                          height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    _buildLinkCard(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLockedScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF2D3A6B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded,
                color: Color(0xFFFF6B6B), size: 56),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dispositivo bloqueado',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tu padre/madre ha bloqueado este dispositivo. Contactalo para desbloquearlo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B9FFF).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.link_rounded,
                color: Color(0xFF7B9FFF), size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Vinculá tu dispositivo',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A6B))),
          const SizedBox(height: 8),
          const Text(
            'Mostrá este código a tu padre/madre para que lo ingrese en su app',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Color(0xFF8A94B2), height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _generateCode,
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Generar código de vinculación',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B9FFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    AsyncValue<Map<String, dynamic>?> userDataAsync,
    AsyncValue<Map<String, dynamic>?> profileAsync,
  ) {
    final isLinked = profileAsync.value != null &&
        profileAsync.value!['parentId'] != null;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              color: const Color(0xFFF0F4FF),
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
                          color: const Color(0xFF6ECFB5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.child_care_rounded,
                            color: Colors.white, size: 30),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF8A94B2)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  userDataAsync.when(
                    loading: () => const Text('Cargando...',
                        style: TextStyle(color: Color(0xFF8A94B2))),
                    error: (_, __) => const SizedBox(),
                    data: (userData) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData?['name'] ?? 'Mi cuenta',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3A6B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userData?['email'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8A94B2)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6ECFB5).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLinked ? '🔗 Vinculado con papá/mamá' : '⚠️ Sin vincular',
                      style: TextStyle(
                        fontSize: 11,
                        color: isLinked
                            ? const Color(0xFF3A9E87)
                            : const Color(0xFFFFB347),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6ECFB5).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.timer_rounded,
                          color: Color(0xFF6ECFB5), size: 20),
                    ),
                    title: const Text('Mi tiempo',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3A6B))),
                    subtitle: const Text('Ver tiempo restante',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF8A94B2))),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFB0BAD3), size: 18),
                    onTap: () => Navigator.pop(context),
                  ),
                  _LockedItem(
                      label: 'Configuración',
                      subtitle: 'Solo el padre puede modificar'),
                  _LockedItem(
                      label: 'Desbloquear apps',
                      subtitle: 'Requiere autorización del padre'),
                  _LockedItem(
                      label: 'Cambiar límites',
                      subtitle: 'Requiere autorización del padre'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFE8ECF8)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showChildLogoutDialog();
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFFFF6B6B), size: 18),
                  label: const Text('Cerrar sesión',
                      style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600)),
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
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8A94B2))),
      ],
    );
  }
}

class _LockedItem extends StatelessWidget {
  final String label;
  final String subtitle;
  const _LockedItem({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.lock_rounded,
            color: Color(0xFFFFB0B0), size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB0BAD3))),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFFB0BAD3))),
      trailing: const Icon(Icons.block_rounded,
          color: Color(0xFFFFB0B0), size: 16),
      onTap: null,
    );
  }
}