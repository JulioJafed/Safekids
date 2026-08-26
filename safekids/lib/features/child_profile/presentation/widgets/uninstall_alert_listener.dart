import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/link_provider.dart';
import '../../../../core/services/uninstall_protection_service.dart';

/// Envuelve cualquier pantalla del padre (recomendado: ParentDashboardScreen)
/// y muestra automáticamente una alerta en tiempo real cada vez que un hijo
/// vinculado intenta desactivar/desinstalar SafeKids, con opciones de
/// Autorizar o Denegar.
class UninstallAlertListener extends ConsumerWidget {
  final Widget child;
  const UninstallAlertListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(linkedChildrenProvider);

    return childrenAsync.when(
      data: (children) {
        return Stack(
          children: [
            this.child,
            for (final c in children)
              if ((c['childId'] ?? '').toString().isNotEmpty)
                _ChildUninstallWatcher(
                  key: ValueKey(c['childId']),
                  childId: c['childId'],
                  childName: c['name'] ?? 'tu hijo/a',
                ),
          ],
        );
      },
      loading: () => this.child,
      error: (_, __) => this.child,
    );
  }
}

class _ChildUninstallWatcher extends StatefulWidget {
  final String childId;
  final String childName;
  const _ChildUninstallWatcher({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<_ChildUninstallWatcher> createState() => _ChildUninstallWatcherState();
}

class _ChildUninstallWatcherState extends State<_ChildUninstallWatcher> {
  final _service = UninstallProtectionService();
  String? _lastHandledStatus;
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _service.watchUninstallRequests(widget.childId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          final status = data['status'] as String?;
          if (status == 'pending' &&
              _lastHandledStatus != 'pending' &&
              !_dialogOpen) {
            _lastHandledStatus = status;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showAlertDialog(context);
            });
          } else if (status != 'pending') {
            _lastHandledStatus = status;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showAlertDialog(BuildContext context) {
    if (_dialogOpen) return;
    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF6B6B), size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.childName} intentó desactivar SafeKids',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3A6B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¿Autorizás la desactivación? Si aceptás, se genera un código '
              'para que lo ingrese en su celular. Si denegás, su celular se '
              'bloquea de inmediato.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Color(0xFF8A94B2), height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: const BorderSide(color: Color(0xFFFF6B6B)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _service.denyRequest(widget.childId);
                      _dialogOpen = false;
                    },
                    child: const Text('Denegar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6ECFB5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      final result =
                          await _service.generateCode(widget.childId);
                      _dialogOpen = false;
                      if (result.isSuccess && context.mounted) {
                        _showCodeDialog(context, result.code);
                      }
                    },
                    child: const Text('Autorizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Código de autorización',
            style:
                TextStyle(color: Color(0xFF2D3A6B), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Decile este código a ${widget.childName}. Vence en 5 minutos.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A94B2)),
            ),
            const SizedBox(height: 16),
            Text(
              code,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Color(0xFF7B9FFF),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}