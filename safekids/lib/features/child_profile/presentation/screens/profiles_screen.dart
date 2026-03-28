import 'package:flutter/material.dart';
import 'link_device_screen.dart';

// Modelo simple de perfil de hijo (sin base de datos por ahora)
class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String emoji;
  final String deviceStatus;
  final Color color;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.emoji,
    required this.deviceStatus,
    required this.color,
  });
}

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  // Lista en memoria (a futuro vendrá de Firebase)
  final List<ChildProfile> _profiles = [
    const ChildProfile(
      id: '1',
      name: 'Sofía',
      age: 10,
      emoji: '👧',
      deviceStatus: 'Conectado',
      color: Color(0xFF7B9FFF),
    ),
    const ChildProfile(
      id: '2',
      name: 'Mateo',
      age: 8,
      emoji: '👦',
      deviceStatus: 'Desconectado',
      color: Color(0xFF6ECFB5),
    ),
  ];

  void _showAddProfileSheet() {
    final nameController = TextEditingController();
    int selectedAge = 8;
    String selectedEmoji = '👧';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Agregar hijo/a',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A6B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completá los datos del perfil',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A94B2)),
              ),
              const SizedBox(height: 24),

              // Selector de emoji
              const Text('Elegí un avatar',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3A6B))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👧', '👦', '🧒', '👶', '🧑'].map((e) {
                  final isSelected = selectedEmoji == e;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedEmoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7B9FFF).withOpacity(0.15)
                            : const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7B9FFF)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Nombre
              const Text('Nombre',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3A6B))),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nombre del hijo/a',
                  hintStyle: const TextStyle(color: Color(0xFFBFC8E2)),
                  prefixIcon: const Icon(Icons.badge_outlined,
                      color: Color(0xFF7B9FFF), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF7B9FFF), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Edad
              const Text('Edad',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3A6B))),
              const SizedBox(height: 10),
              Row(
                children: List.generate(10, (i) {
                  final age = i + 4;
                  final isSelected = selectedAge == age;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedAge = age),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7B9FFF)
                              : const Color(0xFFF5F7FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '$age',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF8A94B2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Botón agregar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      final colors = [
                        const Color(0xFF7B9FFF),
                        const Color(0xFF6ECFB5),
                        const Color(0xFFFFB085),
                        const Color(0xFFFF8FAB),
                      ];
                      setState(() {
                        _profiles.add(ChildProfile(
                          id: DateTime.now().toString(),
                          name: nameController.text.trim(),
                          age: selectedAge,
                          emoji: selectedEmoji,
                          deviceStatus: 'Sin vincular',
                          color: colors[_profiles.length % colors.length],
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B9FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Agregar perfil',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar perfil',
            style: TextStyle(
                color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
        content: Text(
          '¿Querés eliminar el perfil de ${_profiles[index].name}?',
          style: const TextStyle(color: Color(0xFF8A94B2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8A94B2))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _profiles.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mis hijos',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A6B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administrá los perfiles vinculados',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF8A94B2)),
                      ),
                    ],
                  ),
                  // Botón agregar
                  GestureDetector(
                    onTap: _showAddProfileSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B9FFF),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B9FFF).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Lista de perfiles
              Expanded(
                child: _profiles.isEmpty
                    ? _EmptyState(onAdd: _showAddProfileSheet)
                    : ListView.builder(
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final p = _profiles[index];
                          return _ProfileCard(
                            profile: p,
                            onDelete: () => _showDeleteDialog(index),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ChildProfile profile;
  final VoidCallback onDelete;

  const _ProfileCard({required this.profile, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isConnected = profile.deviceStatus == 'Conectado';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: profile.color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: profile.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child:
                  Text(profile.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A6B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.age} años',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8A94B2)),
                ),
                const SizedBox(height: 8),
                // Badge estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFF8A94B2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF8A94B2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        profile.deviceStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isConnected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF8A94B2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Acciones
          Column(
            children: [
            IconButton(
              icon: const Icon(Icons.link_rounded,
                  color: Color(0xFF7B9FFF), size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LinkDeviceScreen()),
              ),
            ),
              
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFF6B6B), size: 22),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  void _showLockDialog(BuildContext context) {
  bool isLocked = false;
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xFFFF6B6B).withOpacity(0.12)
                    : const Color(0xFF6ECFB5).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: isLocked
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF6ECFB5),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isLocked
                  ? '${profile.name} no puede usar el celular'
                  : '¿Bloquear celular de ${profile.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3A6B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLocked
                  ? 'El dispositivo está completamente bloqueado. Solo vos podés desbloquearlo.'
                  : 'El celular quedará completamente bloqueado hasta que vos lo desbloquees.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF8A94B2), height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8ECF8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Color(0xFF8A94B2))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => isLocked = !isLocked),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLocked
                          ? const Color(0xFF6ECFB5)
                          : const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isLocked ? 'Desbloquear' : 'Bloquear',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: Color(0xFF7B9FFF), size: 50),
          ),
          const SizedBox(height: 20),
          const Text('No hay perfiles aún',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A6B))),
          const SizedBox(height: 8),
          const Text('Agregá el primer perfil de tu hijo/a',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar hijo/a'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B9FFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}