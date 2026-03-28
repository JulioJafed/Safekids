import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen>
    with TickerProviderStateMixin {
  bool _isLinked = false;
  String _linkCode = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Tiempo restante simulado (a futuro vendrá de Firebase)
  int _remainingMinutes = 87;
  int _limitMinutes = 120;

  @override
  void initState() {
    super.initState();
    _generateCode();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final code = List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
    setState(() {
      _linkCode = '${code.substring(0, 4)}-${code.substring(4)}';
    });
  }

  double get _progressValue => _remainingMinutes / _limitMinutes;

  String get _timeFormatted {
    final h = _remainingMinutes ~/ 60;
    final m = _remainingMinutes % 60;
    return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}min' : '${m}min';
  }

  Color get _timerColor {
    if (_progressValue > 0.5) return const Color(0xFF6ECFB5);
    if (_progressValue > 0.2) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('¡Hola! 👋',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3A6B))),
                      SizedBox(height: 2),
                      Text('Tu dispositivo SafeKids',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A94B2))),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B9FFF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Color(0xFF7B9FFF), size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // TEMPORIZADOR PRINCIPAL
              if (_isLinked) ...[
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
                          color: _timerColor.withOpacity(0.25),
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
                            value: _progressValue,
                            strokeWidth: 12,
                            backgroundColor:
                                _timerColor.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(_timerColor),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeFormatted,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _timerColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'tiempo restante',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF8A94B2)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6ECFB5).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '✓ Vinculado',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6ECFB5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Info de límite
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
                        value: '2h 00min',
                        icon: Icons.access_time_rounded,
                        color: const Color(0xFF7B9FFF),
                      ),
                      Container(
                          width: 1,
                          height: 36,
                          color: const Color(0xFFE8ECF8)),
                      _InfoChip(
                        label: 'Usado',
                        value: '33min',
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFFFFB347),
                      ),
                      Container(
                          width: 1,
                          height: 36,
                          color: const Color(0xFFE8ECF8)),
                      _InfoChip(
                        label: 'Apps libres',
                        value: '8',
                        icon: Icons.apps_rounded,
                        color: const Color(0xFF6ECFB5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Mensaje motivacional
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
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ] else ...[
                // PANTALLA DE VINCULACIÓN
                Container(
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
                      const Text(
                        'Vinculá tu dispositivo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A6B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mostrá este código a tu padre/madre para que lo ingrese en su app',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8A94B2),
                            height: 1.5),
                      ),
                      const SizedBox(height: 28),

                      // Código grande
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _linkCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: const Color(0xFF7B9FFF).withOpacity(0.3),
                                width: 2),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _linkCode,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3A6B),
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.copy_rounded,
                                      size: 14, color: Color(0xFF8A94B2)),
                                  SizedBox(width: 4),
                                  Text('Toca para copiar',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF8A94B2))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Expiración
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.timer_outlined,
                              size: 14, color: Color(0xFFFFB347)),
                          SizedBox(width: 4),
                          Text(
                            'Este código expira en 10 minutos',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFFFB347)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Botón regenerar
                      TextButton.icon(
                        onPressed: _generateCode,
                        icon: const Icon(Icons.refresh_rounded,
                            color: Color(0xFF7B9FFF), size: 18),
                        label: const Text('Generar nuevo código',
                            style: TextStyle(color: Color(0xFF7B9FFF))),
                      ),

                      const SizedBox(height: 12),

                      // Botón simular vinculación (temporal sin Firebase)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isLinked = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6ECFB5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Simular vinculación ✓',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF8A94B2))),
      ],
    );
  }
}