import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedChild = 0;
  String _selectedPeriod = 'Esta semana';

  final List<Map<String, String>> _children = [
    {'name': 'Sofía', 'emoji': '👧'},
    {'name': 'Mateo', 'emoji': '👦'},
  ];

  final List<String> _periods = ['Hoy', 'Esta semana', 'Este mes'];

  // Datos simulados por hijo
  final List<Map<String, dynamic>> _childData = [
    {
      'totalHoy': 1.2,
      'totalSemana': 9.5,
      'totalMes': 38.0,
      'promedioDisario': 1.9,
      'diaSemana': [1.5, 2.0, 0.8, 2.5, 3.0, 1.2, 1.2],
      'topApps': [
        {'name': 'YouTube', 'hours': 3.2, 'icon': Icons.play_circle_filled_rounded, 'color': Color(0xFFFF0000)},
        {'name': 'Roblox', 'hours': 2.8, 'icon': Icons.gamepad_rounded, 'color': Color(0xFFE02020)},
        {'name': 'TikTok', 'hours': 1.5, 'icon': Icons.music_note_rounded, 'color': Color(0xFF010101)},
        {'name': 'Minecraft', 'hours': 1.2, 'icon': Icons.grid_on_rounded, 'color': Color(0xFF4CAF50)},
        {'name': 'WhatsApp', 'hours': 0.8, 'icon': Icons.chat_rounded, 'color': Color(0xFF25D366)},
      ],
      'categorias': [
        {'name': 'Entretenimiento', 'pct': 0.42, 'color': Color(0xFFFF6B6B)},
        {'name': 'Juegos', 'pct': 0.31, 'color': Color(0xFF7B9FFF)},
        {'name': 'Redes sociales', 'pct': 0.18, 'color': Color(0xFF6ECFB5)},
        {'name': 'Educación', 'pct': 0.09, 'color': Color(0xFFFFB347)},
      ],
    },
    {
      'totalHoy': 0.5,
      'totalSemana': 5.2,
      'totalMes': 20.0,
      'promedioDisario': 1.0,
      'diaSemana': [0.5, 1.0, 0.3, 1.2, 1.5, 0.4, 0.5],
      'topApps': [
        {'name': 'Minecraft', 'hours': 2.1, 'icon': Icons.grid_on_rounded, 'color': Color(0xFF4CAF50)},
        {'name': 'YouTube', 'hours': 1.5, 'icon': Icons.play_circle_filled_rounded, 'color': Color(0xFFFF0000)},
        {'name': 'Duolingo', 'hours': 0.8, 'icon': Icons.translate_rounded, 'color': Color(0xFF58CC02)},
        {'name': 'Spotify', 'hours': 0.5, 'icon': Icons.headphones_rounded, 'color': Color(0xFF1DB954)},
        {'name': 'Chrome', 'hours': 0.3, 'icon': Icons.language_rounded, 'color': Color(0xFF4285F4)},
      ],
      'categorias': [
        {'name': 'Juegos', 'pct': 0.45, 'color': Color(0xFF7B9FFF)},
        {'name': 'Entretenimiento', 'pct': 0.30, 'color': Color(0xFFFF6B6B)},
        {'name': 'Educación', 'pct': 0.15, 'color': Color(0xFF6ECFB5)},
        {'name': 'Otros', 'pct': 0.10, 'color': Color(0xFFFFB347)},
      ],
    },
  ];

  String _formatHours(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    if (hrs == 0) return '${mins}min';
    if (mins == 0) return '${hrs}h';
    return '${hrs}h ${mins}min';
  }

  double get _totalPeriod {
    final d = _childData[_selectedChild];
    switch (_selectedPeriod) {
      case 'Hoy': return d['totalHoy'];
      case 'Este mes': return d['totalMes'];
      default: return d['totalSemana'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _childData[_selectedChild];
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final horas = List<double>.from(data['diaSemana']);
    final maxHora = horas.reduce((a, b) => a > b ? a : b);
    final topApps = List<Map<String, dynamic>>.from(data['topApps']);
    final categorias = List<Map<String, dynamic>>.from(data['categorias']);
    final childColor = _selectedChild == 0
        ? const Color(0xFF7B9FFF)
        : const Color(0xFF6ECFB5);

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
                'Reportes',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A6B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumen de actividad del dispositivo',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A94B2)),
              ),

              const SizedBox(height: 20),

              // Selector de hijo
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _children.length,
                  itemBuilder: (context, i) {
                    final isSelected = i == _selectedChild;
                    final color = i == 0
                        ? const Color(0xFF7B9FFF)
                        : const Color(0xFF6ECFB5);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChild = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE8ECF8),
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Text(_children[i]['emoji']!,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              _children[i]['name']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF2D3A6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Selector de período
              Row(
                children: _periods.map((p) {
                  final isSelected = p == _selectedPeriod;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? childColor.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? childColor
                              : const Color(0xFFE8ECF8),
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? childColor
                              : const Color(0xFF8A94B2),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Tarjetas de resumen
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: _selectedPeriod,
                      value: _formatHours(_totalPeriod),
                      icon: Icons.access_time_rounded,
                      color: childColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Promedio diario',
                      value: _formatHours(data['promedioDisario']),
                      icon: Icons.today_rounded,
                      color: const Color(0xFFFFB347),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Apps usadas',
                      value: '${topApps.length}',
                      icon: Icons.apps_rounded,
                      color: const Color(0xFF6ECFB5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Apps bloqueadas',
                      value: '3',
                      icon: Icons.block_rounded,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Gráfica de barras semanal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: childColor.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Uso por día',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3A6B),
                          ),
                        ),
                        Text(
                          'Límite: 2h/día',
                          style: TextStyle(
                            fontSize: 12,
                            color: childColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final h = horas[i];
                          final ratio = maxHora > 0 ? h / maxHora : 0.0;
                          final isOver = h > 2.0;
                          final isToday = i == 6;
                          final barColor = isOver
                              ? const Color(0xFFFF6B6B)
                              : isToday
                                  ? childColor
                                  : childColor.withOpacity(0.4);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatHours(h),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isOver
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(0xFF8A94B2),
                                  fontWeight: isToday
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                width: 28,
                                height: 90 * ratio,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dias[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday
                                      ? childColor
                                      : const Color(0xFF8A94B2),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Línea de límite visual
                    Row(
                      children: [
                        Container(width: 16, height: 2,
                            color: const Color(0xFFFF6B6B).withOpacity(0.5)),
                        const SizedBox(width: 6),
                        const Text(
                          'Barras rojas = superó el límite diario',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF8A94B2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Top apps
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: childColor.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apps más usadas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...topApps.asMap().entries.map((e) {
                      final i = e.key;
                      final app = e.value;
                      final maxH = (topApps.first['hours'] as double);
                      final ratio = (app['hours'] as double) / maxH;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            // Rank
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? const Color(0xFFFFB347).withOpacity(0.2)
                                    : const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: i == 0
                                        ? const Color(0xFFFFB347)
                                        : const Color(0xFF8A94B2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Ícono app
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (app['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(app['icon'] as IconData,
                                  color: app['color'] as Color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            // Nombre + barra
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        app['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2D3A6B),
                                        ),
                                      ),
                                      Text(
                                        _formatHours(app['hours'] as double),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8A94B2),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor:
                                          const Color(0xFFF0F4FF),
                                      valueColor: AlwaysStoppedAnimation(
                                          app['color'] as Color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Distribución por categoría
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: childColor.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Por categoría',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Barra horizontal apilada
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 16,
                        child: Row(
                          children: categorias.map((c) {
                            return Expanded(
                              flex: ((c['pct'] as double) * 100).round(),
                              child: Container(color: c['color'] as Color),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Leyenda
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: categorias.map((c) {
                        final pct = ((c['pct'] as double) * 100).round();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${c['name']} $pct%',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8A94B2)),
                            ),
                          ],
                        );
                      }).toList(),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A94B2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}