import 'package:flutter/material.dart';
import 'link_device_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/link_provider.dart';
import '../../../../core/services/lock_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  // Lista en memoria (a futuro vendrá de Firebase)
  @override
Widget build(BuildContext context) {
  final childrenAsync = ref.watch(linkedChildrenProvider);

  return Scaffold(
    backgroundColor: const Color(0xFFF0F4FF),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Mis hijos',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3A6B))),
                    SizedBox(height: 4),
                    Text('Dispositivos vinculados',
                        style: TextStyle(fontSize: 13, color: Color(0xFF8A94B2))),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LinkDeviceScreen())),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B9FFF),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [BoxShadow(color: const Color(0xFF7B9FFF).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: childrenAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7B9FFF))),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (children) {
                  if (children.isEmpty) {
                    return _EmptyState(onAdd: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LinkDeviceScreen())));
                  }
                  return ListView.builder(
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      final colors = [
                        const Color(0xFF7B9FFF),
                        const Color(0xFF6ECFB5),
                        const Color(0xFFFFB085),
                        const Color(0xFFFF8FAB),
                      ];
                      return _ProfileCard(
                        profile: ChildProfile(
                          id: child['childId'] ?? '',
                          name: child['name'] ?? 'Hijo/a',
                          age: child['age'] ?? 0,
                          emoji: child['emoji'] ?? '👧',
                          deviceStatus: child['deviceStatus'] ?? 'offline',
                          color: colors[index % colors.length],
                        ),
                        onDelete: () async {
                          await ref.read(linkRepositoryProvider)
                              .unlinkChild(child['childId']);
                        },
                      );
                    },
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
            icon: Icon(
              profile.deviceStatus == 'blocked'
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              color: profile.deviceStatus == 'blocked'
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF7B9FFF),
              size: 22,
            ),
            onPressed: () => _showLockDialog(context),
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
  final lockService = LockService();
  bool isLocked = false;
  bool isLoading = true;
  String generatedCode = '';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        // Cargar estado real desde Firestore al abrir
        if (isLoading) {
          FirebaseFirestore.instance
              .collection('childProfiles')
              .doc(profile.id)
              .get()
              .then((doc) {
            if (doc.exists) {
              final locked = doc.data()?['isDeviceLocked'] ?? false;
              final code = doc.data()?['unlockCode'] ?? '';
              setModalState(() {
                isLocked = locked;
                generatedCode = code;
                isLoading = false;
              });
            } else {
              setModalState(() => isLoading = false);
            }
          });
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7B9FFF)),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? const Color(0xFFFF6B6B).withOpacity(0.12)
                            : const Color(0xFF6ECFB5).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: isLocked
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF6ECFB5),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLocked
                          ? 'Celular de ${profile.name} BLOQUEADO'
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
                          ? 'Mostrá este código a ${profile.name} para desbloquear'
                          : 'Se generará un código único para desbloquear',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A94B2),
                          height: 1.5),
                    ),

                    // Código de desbloqueo
                    if (isLocked && generatedCode.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3A6B).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF7B9FFF).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text('Código de desbloqueo',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A94B2))),
                            const SizedBox(height: 8),
                            Text(
                              generatedCode,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3A6B),
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dictale este código al hijo',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF8A94B2)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFE8ECF8)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            child: const Text('Cerrar',
                                style: TextStyle(
                                    color: Color(0xFF8A94B2))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setModalState(() => isLoading = true);
                              if (!isLocked) {
                                final result =
                                    await lockService.lockDevice(profile.id);
                                if (result.isSuccess) {
                                  setModalState(() {
                                    isLocked = true;
                                    generatedCode = result.code;
                                    isLoading = false;
                                  });
                                } else {
                                  setModalState(() => isLoading = false);
                                }
                              } else {
                                await lockService.unlockDevice(profile.id);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLocked
                                  ? const Color(0xFF6ECFB5)
                                  : const Color(0xFFFF6B6B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            child: Text(
                              isLocked ? 'Desbloquear' : 'Bloquear ahora',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
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