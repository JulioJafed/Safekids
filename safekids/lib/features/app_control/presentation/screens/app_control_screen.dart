import 'package:flutter/material.dart';

// Modelo de app instalada
class AppInfo {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final Color color;
  bool isBlocked;
  TimeOfDay? blockFrom;
  TimeOfDay? blockTo;
  bool hasSchedule;

  AppInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    this.isBlocked = false,
    this.blockFrom,
    this.blockTo,
    this.hasSchedule = false,
  });
}

class AppControlScreen extends StatefulWidget {
  const AppControlScreen({super.key});

  @override
  State<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends State<AppControlScreen> {
  int _selectedChild = 0;
  String _selectedCategory = 'Todas';

  final List<Map<String, String>> _children = [
    {'name': 'Sofía', 'emoji': '👧'},
    {'name': 'Mateo', 'emoji': '👦'},
  ];

  final List<String> _categories = [
    'Todas', 'Juegos', 'Redes sociales', 'Educación', 'Entretenimiento', 'Otros'
  ];

  // Apps simuladas (a futuro vendrán del dispositivo real via canal nativo)
  final List<AppInfo> _apps = [
    AppInfo(id: '1', name: 'TikTok', category: 'Redes sociales',
        icon: Icons.music_note_rounded, color: const Color(0xFF010101), isBlocked: true),
    AppInfo(id: '2', name: 'YouTube', category: 'Entretenimiento',
        icon: Icons.play_circle_rounded, color: const Color(0xFFFF0000)),
    AppInfo(id: '3', name: 'Roblox', category: 'Juegos',
        icon: Icons.sports_esports_rounded, color: const Color(0xFFE02020)),
    AppInfo(id: '4', name: 'Minecraft', category: 'Juegos',
        icon: Icons.grid_on_rounded, color: const Color(0xFF4CAF50)),
    AppInfo(id: '5', name: 'Instagram', category: 'Redes sociales',
        icon: Icons.camera_alt_rounded, color: const Color(0xFFE1306C), isBlocked: true),
    AppInfo(id: '6', name: 'WhatsApp', category: 'Redes sociales',
        icon: Icons.chat_rounded, color: const Color(0xFF25D366)),
    AppInfo(id: '7', name: 'Duolingo', category: 'Educación',
        icon: Icons.school_rounded, color: const Color(0xFF58CC02)),
    AppInfo(id: '8', name: 'Netflix', category: 'Entretenimiento',
        icon: Icons.movie_rounded, color: const Color(0xFFE50914)),
    AppInfo(id: '9', name: 'Free Fire', category: 'Juegos',
        icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF6B00)),
    AppInfo(id: '10', name: 'Khan Academy', category: 'Educación',
        icon: Icons.menu_book_rounded, color: const Color(0xFF14BF96)),
    AppInfo(id: '11', name: 'Spotify', category: 'Entretenimiento',
        icon: Icons.headphones_rounded, color: const Color(0xFF1DB954)),
    AppInfo(id: '12', name: 'Chrome', category: 'Otros',
        icon: Icons.language_rounded, color: const Color(0xFF4285F4)),
  ];

  List<AppInfo> get _filteredApps {
    if (_selectedCategory == 'Todas') return _apps;
    return _apps.where((a) => a.category == _selectedCategory).toList();
  }

  int get _blockedCount => _apps.where((a) => a.isBlocked).length;

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showScheduleSheet(AppInfo app) {
    TimeOfDay fromTime = app.blockFrom ?? const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay toTime = app.blockTo ?? const TimeOfDay(hour: 7, minute: 0);
    bool hasSchedule = app.hasSchedule;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: app.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(app.icon, color: app.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3A6B))),
                      Text(app.category,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8A94B2))),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Toggle horario
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Bloqueo por horario',
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3A6B))),
                      SizedBox(height: 2),
                      Text('Bloqueá la app en un rango de horas',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8A94B2))),
                    ],
                  ),
                  Switch(
                    value: hasSchedule,
                    onChanged: (v) => setModal(() => hasSchedule = v),
                    activeColor: const Color(0xFF7B9FFF),
                  ),
                ],
              ),

              if (hasSchedule) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerCard(
                        label: 'Desde',
                        time: fromTime,
                        color: const Color(0xFFFF6B6B),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: fromTime,
                          );
                          if (picked != null) {
                            setModal(() => fromTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerCard(
                        label: 'Hasta',
                        time: toTime,
                        color: const Color(0xFF7B9FFF),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: toTime,
                          );
                          if (picked != null) {
                            setModal(() => toTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      app.hasSchedule = hasSchedule;
                      app.blockFrom = hasSchedule ? fromTime : null;
                      app.blockTo = hasSchedule ? toTime : null;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B9FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Guardar horario',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredApps;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text('Bloqueo de apps',
                      style: TextStyle(fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A6B))),
                  const SizedBox(height: 4),
                  const Text('Controlá qué apps puede usar tu hijo',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF8A94B2))),

                  const SizedBox(height: 20),

                  // Selector de hijo
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _children.length,
                      itemBuilder: (context, i) {
                        final isSelected = i == _selectedChild;
                        return GestureDetector(
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
                            child: Text(
                              '${_children[i]['emoji']} ${_children[i]['name']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2D3A6B),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resumen
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _SummaryChip(
                          label: 'Total apps',
                          value: '${_apps.length}',
                          color: const Color(0xFF7B9FFF),
                          icon: Icons.apps_rounded,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: 'Bloqueadas',
                          value: '$_blockedCount',
                          color: const Color(0xFFFF6B6B),
                          icon: Icons.block_rounded,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: 'Con horario',
                          value: '${_apps.where((a) => a.hasSchedule).length}',
                          color: const Color(0xFFFFB347),
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filtro por categoría
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, i) {
                        final isSelected =
                            _categories[i] == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategory = _categories[i]),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2D3A6B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(0xFFE8ECF8),
                              ),
                            ),
                            child: Text(
                              _categories[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF8A94B2),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Lista de apps
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  return _AppCard(
                    app: app,
                    onToggle: (v) => setState(() => app.isBlocked = v),
                    onSchedule: () => _showScheduleSheet(app),
                    formatTime: _formatTime,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final AppInfo app;
  final Function(bool) onToggle;
  final VoidCallback onSchedule;
  final String Function(TimeOfDay?) formatTime;

  const _AppCard({
    required this.app,
    required this.onToggle,
    required this.onSchedule,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: app.isBlocked
            ? Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3A6B).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono app
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: app.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(app.icon, color: app.color, size: 22),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(app.category,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8A94B2))),
                    ),
                    if (app.hasSchedule) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB347).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${formatTime(app.blockFrom)} - ${formatTime(app.blockTo)}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFFB347),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botón horario
          IconButton(
            icon: Icon(
              Icons.schedule_rounded,
              color: app.hasSchedule
                  ? const Color(0xFFFFB347)
                  : const Color(0xFFD0D8F0),
              size: 20,
            ),
            onPressed: onSchedule,
          ),

          // Switch bloqueo
          Switch(
            value: app.isBlocked,
            onChanged: onToggle,
            activeColor: const Color(0xFFFF6B6B),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;

  const _TimePickerCard({
    required this.label,
    required this.time,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('$h:$m',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text('Tocá para cambiar',
                style: TextStyle(
                    fontSize: 10, color: color.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF8A94B2))),
          ],
        ),
      ),
    );
  }
}