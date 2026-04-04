import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_detection_service.dart';
import '../../../../features/app_control/data/repositories/app_sync_repository.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _hasPermission = false;
  bool _isSyncing = false;
  bool _synced = false;
  String _statusMessage = '';
  int _appsFound = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final has = await AppDetectionService.hasUsagePermission();
    setState(() => _hasPermission = has);
  }

  Future<void> _requestPermission() async {
    await AppDetectionService.openUsageSettings();
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermission();
  }

  Future<void> _syncApps() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Detectando apps instaladas...';
    });

    final repo = AppSyncRepository();
    final result = await repo.syncInstalledApps();

    if (result.isSuccess) {
      setState(() {
        _statusMessage = 'Sincronizando estadísticas de uso...';
        _appsFound = result.appsCount;
      });
      await repo.syncUsageStats();
      setState(() {
        _isSyncing = false;
        _synced = true;
        _statusMessage = '¡Listo! ${result.appsCount} apps sincronizadas';
      });
    } else {
      setState(() {
        _isSyncing = false;
        _statusMessage = result.errorMessage ?? 'Error al sincronizar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configuración',
            style: TextStyle(
                color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Ícono principal
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF7B9FFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded,
                  color: Color(0xFF7B9FFF), size: 48),
            ),

            const SizedBox(height: 24),

            const Text('Configuración de seguridad',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A6B))),

            const SizedBox(height: 8),

            const Text(
              'Para que SafeKids funcione correctamente necesita estos permisos',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF8A94B2), height: 1.5),
            ),

            const SizedBox(height: 32),

            // Paso 1 — Permiso de uso
            _StepCard(
              step: '1',
              title: 'Permiso de acceso al uso',
              description:
                  'Permite que SafeKids vea cuánto tiempo usás cada app y envíe esa info a tu padre/madre.',
              isCompleted: _hasPermission,
              color: const Color(0xFF7B9FFF),
              action: _hasPermission
                  ? null
                  : ElevatedButton(
                      onPressed: _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B9FFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Activar permiso'),
                    ),
            ),

            const SizedBox(height: 16),

            // Paso 2 — Sincronizar apps
            _StepCard(
              step: '2',
              title: 'Sincronizar apps instaladas',
              description:
                  'Envía la lista de apps instaladas en este dispositivo al panel de tu padre/madre.',
              isCompleted: _synced,
              color: const Color(0xFF6ECFB5),
              action: _hasPermission && !_synced
                  ? ElevatedButton(
                      onPressed: _isSyncing ? null : _syncApps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6ECFB5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sincronizar ahora'),
                    )
                  : null,
            ),

            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _synced
                      ? const Color(0xFF6ECFB5).withOpacity(0.1)
                      : const Color(0xFF7B9FFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _synced
                        ? const Color(0xFF6ECFB5).withOpacity(0.3)
                        : const Color(0xFF7B9FFF).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _synced
                          ? Icons.check_circle_rounded
                          : Icons.sync_rounded,
                      color: _synced
                          ? const Color(0xFF6ECFB5)
                          : const Color(0xFF7B9FFF),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: _synced
                              ? const Color(0xFF3A9E87)
                              : const Color(0xFF5578CC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_synced) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF6ECFB5).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF6ECFB5), size: 40),
                    const SizedBox(height: 12),
                    const Text('¡Todo configurado!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3A6B))),
                    const SizedBox(height: 6),
                    Text(
                      '$_appsFound apps sincronizadas con el panel de tu padre/madre',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A94B2),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final bool isCompleted;
  final Color color;
  final Widget? action;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? color.withOpacity(0.4) : const Color(0xFFE8ECF8),
          width: isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                  : Text(step,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B))),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A94B2),
                        height: 1.5)),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}