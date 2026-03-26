import 'package:flutter/material.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

// Modelo simple de tiempo por hijo
class _ChildTimeConfig {
  final String name;
  final String emoji;
  final Color color;
  double dailyLimitHours;
  bool autoBlock;
  bool isActive;

  _ChildTimeConfig({
    required this.name,
    required this.emoji,
    required this.color,
    this.dailyLimitHours = 2,
    required this.autoBlock,
    required this.isActive,
  });
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  int _selectedChild = 0;

  final List<_ChildTimeConfig> _children = [
    _ChildTimeConfig(
      name: 'Sofía',
      emoji: '👧',
      color: const Color(0xFF7B9FFF),
      dailyLimitHours: 2,
      autoBlock: true,
      isActive: true,
    ),
    _ChildTimeConfig(
      name: 'Mateo',
      emoji: '👦',
      color: const Color(0xFF6ECFB5),
      dailyLimitHours: 1.5,
      autoBlock: true,
      isActive: true,
    ),
  ];

  // Tiempo usado simulado (a futuro vendrá del dispositivo del hijo)
  final List<double> _usedHours = [1.2, 0.5];

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final child = _children[_selectedChild];
    final used = _usedHours[_selectedChild];
    final remaining = (child.dailyLimitHours - used).clamp(0.0, 24.0);
    final progress = (used / child.dailyLimitHours).clamp(0.0, 1.0);
    final isNearLimit = progress >= 0.8;
    final isOverLimit = progress >= 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // Header
              const Text(
                'Control de tiempo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A6B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Establecé límites diarios por hijo',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A94B2)),
              ),

              const SizedBox(height: 24),

              // Selector de hijo
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _children.length,
                  itemBuilder: (context, i) {
                    final c = _children[i];
                    final isSelected = i == _selectedChild;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChild = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c.color
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.color.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE8ECF8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(c.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2D3A6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta de cuenta regresiva
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isOverLimit
                      ? const Color(0xFFFF6B6B)
                      : isNearLimit
                          ? const Color(0xFFFFB347)
                          : child.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isOverLimit
                              ? const Color(0xFFFF6B6B)
                              : child.color)
                          .withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isOverLimit ? '⛔ Límite alcanzado' : '⏱ Tiempo restante hoy',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOverLimit ? '0h 0min' : _formatHours(remaining),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barra de progreso
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Usado: ${_formatHours(used)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                        Text(
                          'Límite: ${_formatHours(child.dailyLimitHours)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta de configuración
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B9FFF).withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Slider de límite diario
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Límite diario',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3A6B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: child.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatHours(child.dailyLimitHours),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: child.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: child.color,
                        inactiveTrackColor: child.color.withOpacity(0.15),
                        thumbColor: child.color,
                        overlayColor: child.color.withOpacity(0.15),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: child.dailyLimitHours,
                        min: 0.5,
                        max: 8,
                        divisions: 15,
                        onChanged: (value) {
                          setState(() {
                            _children[_selectedChild].dailyLimitHours = value;
                          });
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
                    const SizedBox(height: 20),

                    // Toggle bloqueo automático
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Bloqueo automático',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3A6B),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Bloquea el dispositivo al llegar al límite',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF8A94B2)),
                            ),
                          ],
                        ),
                        Switch(
                          value: child.autoBlock,
                          onChanged: (v) => setState(
                              () => _children[_selectedChild].autoBlock = v),
                          activeColor: child.color,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF0F4FF), height: 1),
                    const SizedBox(height: 16),

                    // Toggle activar/desactivar control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Control activo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3A6B),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Activá o pausá el control de tiempo',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF8A94B2)),
                            ),
                          ],
                        ),
                        Switch(
                          value: child.isActive,
                          onChanged: (v) => setState(
                              () => _children[_selectedChild].isActive = v),
                          activeColor: child.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Resumen semanal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B9FFF).withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen esta semana',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DayBar(day: 'L', hours: 1.5, limit: child.dailyLimitHours, color: child.color),
                        _DayBar(day: 'M', hours: 2.0, limit: child.dailyLimitHours, color: child.color),
                        _DayBar(day: 'X', hours: 0.8, limit: child.dailyLimitHours, color: child.color),
                        _DayBar(day: 'J', hours: 2.5, limit: child.dailyLimitHours, color: child.color),
                        _DayBar(day: 'V', hours: 3.0, limit: child.dailyLimitHours, color: child.color),
                        _DayBar(day: 'S', hours: 1.2, limit: child.dailyLimitHours, color: child.color),
                        _DayBar(day: 'D', hours: used, limit: child.dailyLimitHours, color: child.color, isToday: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String day;
  final double hours;
  final double limit;
  final Color color;
  final bool isToday;

  const _DayBar({
    required this.day,
    required this.hours,
    required this.limit,
    required this.color,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (hours / limit).clamp(0.0, 1.0);
    final isOver = hours > limit;

    return Column(
      children: [
        Text(
          '${hours}h',
          style: TextStyle(
            fontSize: 10,
            color: isOver ? const Color(0xFFFF6B6B) : const Color(0xFF8A94B2),
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 28,
              height: 80 * ratio,
              decoration: BoxDecoration(
                color: isOver
                    ? const Color(0xFFFF6B6B)
                    : isToday
                        ? color
                        : color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: isToday ? color : const Color(0xFF8A94B2),
          ),
        ),
      ],
    );
  }
}