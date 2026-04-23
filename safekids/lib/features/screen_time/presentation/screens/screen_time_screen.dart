import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/screen_time_provider.dart';
import 'package:safekids/features/app_control/presentation/providers/app_control_provider.dart';

class ScreenTimeScreen extends ConsumerStatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  ConsumerState<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends ConsumerState<ScreenTimeScreen> {
  int _selectedChild = 0;

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  Color _progressColor(double progress) {
    if (progress < 0.6) return const Color(0xFF6ECFB5);
    if (progress < 0.85) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenIdsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: childrenAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B9FFF))),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (childrenIds) {
            if (childrenIds.isEmpty) {
              return _buildNoChildren();
            }

            final activeChildId = childrenIds.length > _selectedChild
                ? childrenIds[_selectedChild]
                : childrenIds.first;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // Header
                  const Text('Control de tiempo',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A6B))),
                  const SizedBox(height: 4),
                  const Text('Límites diarios por hijo',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF8A94B2))),

                  const SizedBox(height: 20),

                  // Selector de hijos
                  if (childrenIds.length > 1)
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: childrenIds.length,
                        itemBuilder: (context, i) {
                          final isSelected = i == _selectedChild;
                          final profile = ref.watch(
                              childProfileDataProvider(childrenIds[i]));
                          return profile.when(
                            loading: () => const SizedBox(width: 80),
                            error: (_, __) => const SizedBox(),
                            data: (p) => GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedChild = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF7B9FFF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : const Color(0xFFE8ECF8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(p?['emoji'] ?? '👧',
                                        style:
                                            const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      p?['name'] ?? 'Hijo/a',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF2D3A6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Datos en tiempo real del hijo seleccionado
                  _buildChildTimeCard(activeChildId),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChildTimeCard(String childId) {
    final screenTimeAsync = ref.watch(childScreenTimeProvider(childId));

    return screenTimeAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7B9FFF))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rules) {
        final limit = (rules?['dailyLimitMinutes'] ?? 120) as int;
        final used = (rules?['usedTodayMinutes'] ?? 0) as int;
        final autoBlock = rules?['autoBlock'] ?? true;
        final isActive = rules?['isActive'] ?? true;
        final remaining = (limit - used).clamp(0, limit);
        final progress = limit > 0 ? used / limit : 0.0;
        final color = _progressColor(progress);
        final isOverLimit = used >= limit;

        return Column(
          children: [
            // Tarjeta principal — tiempo restante
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isOverLimit
                    ? const Color(0xFFFF6B6B)
                    : color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isOverLimit
                        ? '⛔ Límite alcanzado'
                        : '⏱ Tiempo restante hoy',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isOverLimit ? '0min' : _formatMinutes(remaining),
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Usado: ${_formatMinutes(used)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                      Text('Límite: ${_formatMinutes(limit)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón reset manual
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showResetDialog(childId),
                icon: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF7B9FFF), size: 18),
                label: const Text('Resetear tiempo hoy',
                    style: TextStyle(color: Color(0xFF7B9FFF))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7B9FFF)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Configuración
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B9FFF).withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuración',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3A6B))),
                  const SizedBox(height: 20),

                  // Slider límite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Límite diario',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3A6B))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B9FFF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatMinutes(limit),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7B9FFF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF7B9FFF),
                      inactiveTrackColor:
                          const Color(0xFF7B9FFF).withOpacity(0.15),
                      thumbColor: const Color(0xFF7B9FFF),
                      overlayColor:
                          const Color(0xFF7B9FFF).withOpacity(0.15),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: limit.toDouble().clamp(30, 480),
                      min: 30,
                      max: 480,
                      divisions: 15,
                      onChanged: (value) async {
                        await ScreenTimeRepository.updateDailyLimit(

                          childId: childId,
                          limitMinutes: value.toInt(),
                          autoBlock: autoBlock,
                          isActive: isActive,
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('30 min',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFB0BAD3))),
                      Text('8 horas',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFB0BAD3))),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF0F4FF), height: 1),
                  const SizedBox(height: 16),

                  // Toggle bloqueo automático
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Bloqueo automático',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3A6B))),
                          SizedBox(height: 3),
                          Text('Bloquea al llegar al límite',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A94B2))),
                        ],
                      ),
                      Switch(
                        value: autoBlock,
                        onChanged: (v) async {
                          await ScreenTimeRepository.updateDailyLimit(

                            childId: childId,
                            limitMinutes: limit,
                            autoBlock: v,
                            isActive: isActive,
                          );
                        },
                        activeColor: const Color(0xFF7B9FFF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F4FF), height: 1),
                  const SizedBox(height: 16),

                  // Toggle control activo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Control activo',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3A6B))),
                          SizedBox(height: 3),
                          Text('Activá o pausá el control',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A94B2))),
                        ],
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (v) async {
                          await ScreenTimeRepository.updateDailyLimit(

                            childId: childId,
                            limitMinutes: limit,
                            autoBlock: autoBlock,
                            isActive: v,
                          );
                        },
                        activeColor: const Color(0xFF7B9FFF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(String childId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Resetear tiempo',
            style: TextStyle(
                color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
        content: const Text(
          '¿Querés resetear el tiempo usado hoy a 0? El hijo podrá usar el celular desde cero.',
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
            onPressed: () async {
             await ScreenTimeRepository.resetChildTime(childId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Tiempo reseteado'),
                  backgroundColor: Color(0xFF6ECFB5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B9FFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildren() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: Color(0xFF7B9FFF), size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Sin hijos vinculados',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A6B))),
          const SizedBox(height: 8),
          const Text(
            'Vinculá el celular de tu hijo/a primero',
            style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2)),
          ),
        ],
      ),
    );
  }
}