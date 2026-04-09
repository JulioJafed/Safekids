import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_control_provider.dart';

class AppControlScreen extends ConsumerStatefulWidget {
  const AppControlScreen({super.key});

  @override
  ConsumerState<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends ConsumerState<AppControlScreen> {
  String _selectedCategory = 'Todas';
  String _searchQuery = '';

  final List<String> _categories = [
    'Todas', 'Juegos', 'Redes sociales',
    'Entretenimiento', 'Música', 'Productividad', 'Otros'
  ];

  // Colores por categoría
  Color _categoryColor(String category) {
    switch (category) {
      case 'Juegos': return const Color(0xFF7B9FFF);
      case 'Redes sociales': return const Color(0xFFFF8FAB);
      case 'Entretenimiento': return const Color(0xFFFF6B6B);
      case 'Música': return const Color(0xFF6ECFB5);
      case 'Productividad': return const Color(0xFFFFB347);
      default: return const Color(0xFF8A94B2);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Juegos': return Icons.gamepad_rounded;
      case 'Redes sociales': return Icons.people_rounded;
      case 'Entretenimiento': return Icons.movie_rounded;
      case 'Música': return Icons.headphones_rounded;
      case 'Productividad': return Icons.work_rounded;
      default: return Icons.apps_rounded;
    }
  }

  Future<void> _toggleAppBlock({
    required String childId,
    required String packageName,
    required List<String> currentBlocked,
    required bool isBlocked,
  }) async {
    final newBlocked = List<String>.from(currentBlocked);
    if (isBlocked) {
      newBlocked.remove(packageName);
    } else {
      newBlocked.add(packageName);
    }

    await FirebaseFirestore.instance
        .collection('appRules')
        .doc(childId)
        .set({
      'childId': childId,
      'blockedApps': newBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  Future<void> _blockAllApps({
    required String childId,
    required List<Map<String, dynamic>> apps,
    required bool block,
  }) async {
    final packages = block
        ? apps.map((a) => a['packageName'] as String).toList()
        : <String>[];

    await FirebaseFirestore.instance
        .collection('appRules')
        .doc(childId)
        .set({
      'childId': childId,
      'blockedApps': packages,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenIdsProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);

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

            // Seleccionar primer hijo por defecto
            final activeChildId = selectedChildId ?? childrenIds.first;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text('Bloqueo de apps',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3A6B))),
                      const SizedBox(height: 4),
                      const Text('Apps instaladas en el celular del hijo',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A94B2))),

                      const SizedBox(height: 16),

                      // Selector de hijo
                      if (childrenIds.length > 1)
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: childrenIds.length,
                            itemBuilder: (context, i) {
                              final childId = childrenIds[i];
                              final isSelected = childId == activeChildId;
                              final childAsync = ref.watch(
                                  childProfileDataProvider(childId));

                              return childAsync.when(
                                loading: () => const SizedBox(width: 100),
                                error: (_, __) => const SizedBox(),
                                data: (profile) {
                                  final name =
                                      profile?['name'] ?? 'Hijo/a';
                                  final emoji =
                                      profile?['emoji'] ?? '👧';
                                  return GestureDetector(
                                    onTap: () => ref
                                        .read(selectedChildIdProvider
                                            .notifier)
                                        .state = childId,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin:
                                          const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF7B9FFF)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : const Color(0xFFE8ECF8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(emoji,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          const SizedBox(width: 6),
                                          Text(name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(
                                                        0xFF2D3A6B),
                                              )),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Buscador
                      TextField(
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Buscar app...',
                          hintStyle:
                              const TextStyle(color: Color(0xFFBFC8E2)),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Color(0xFF7B9FFF), size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filtro categorías
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
                                      ? const Color(0xFF7B9FFF)
                                          .withOpacity(0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF7B9FFF)
                                        : const Color(0xFFE8ECF8),
                                  ),
                                ),
                                child: Text(
                                  _categories[i],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF7B9FFF)
                                        : const Color(0xFF8A94B2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Lista de apps desde Firebase
                Expanded(
                  child: _buildAppsList(activeChildId),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppsList(String childId) {
    final appsAsync = ref.watch(childInstalledAppsProvider(childId));
    final blockedAsync = ref.watch(childBlockedAppsProvider(childId));

    return appsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7B9FFF))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (apps) {
        if (apps.isEmpty) {
          return _buildNoApps(childId);
        }

        return blockedAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF7B9FFF))),
          error: (_, __) => const SizedBox(),
          data: (blockedApps) {
            // Filtrar por categoría y búsqueda
            final filtered = apps.where((app) {
              final name = (app['name'] ?? '').toString().toLowerCase();
              final category = app['category'] ?? 'Otros';
              final matchesSearch = _searchQuery.isEmpty ||
                  name.contains(_searchQuery);
              final matchesCategory = _selectedCategory == 'Todas' ||
                  category == _selectedCategory;
              return matchesSearch && matchesCategory;
            }).toList();

            final blockedCount =
                apps.where((a) => blockedApps.contains(a['packageName'])).length;

            return Column(
              children: [
                // Stats + acciones rápidas
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _StatPill(
                              label: '$blockedCount bloqueadas',
                              color: const Color(0xFFFF6B6B)),
                          const SizedBox(width: 8),
                          _StatPill(
                              label: '${apps.length - blockedCount} libres',
                              color: const Color(0xFF6ECFB5)),
                        ],
                      ),
                      Row(
                        children: [
                          _QuickBtn(
                            label: 'Bloquear todo',
                            color: const Color(0xFFFF6B6B),
                            onTap: () => _blockAllApps(
                                childId: childId,
                                apps: apps,
                                block: true),
                          ),
                          const SizedBox(width: 6),
                          _QuickBtn(
                            label: 'Liberar todo',
                            color: const Color(0xFF6ECFB5),
                            onTap: () => _blockAllApps(
                                childId: childId,
                                apps: apps,
                                block: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No hay apps en esta categoría',
                            style: const TextStyle(
                                color: Color(0xFF8A94B2), fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final app = filtered[index];
                            final packageName =
                                app['packageName'] as String? ?? '';
                            final isBlocked =
                                blockedApps.contains(packageName);
                            final category =
                                app['category'] as String? ?? 'Otros';

                            return _AppTileFirebase(
                              name: app['name'] as String? ?? '',
                              packageName: packageName,
                              category: category,
                              isBlocked: isBlocked,
                              categoryColor: _categoryColor(category),
                              categoryIcon: _categoryIcon(category),
                              onToggle: () => _toggleAppBlock(
                                childId: childId,
                                packageName: packageName,
                                currentBlocked: blockedApps,
                                isBlocked: isBlocked,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoChildren() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Vinculá el celular de tu hijo/a primero para ver sus apps',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoApps(String childId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB347).withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.apps_outlined,
                  color: Color(0xFFFFB347), size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Sin apps detectadas',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A6B))),
            const SizedBox(height: 8),
            const Text(
              'El hijo/a aún no ha sincronizado sus apps. Pedile que abra SafeKids y active los permisos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF8A94B2), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────

class _AppTileFirebase extends StatelessWidget {
  final String name;
  final String packageName;
  final String category;
  final bool isBlocked;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onToggle;

  const _AppTileFirebase({
    required this.name,
    required this.packageName,
    required this.category,
    required this.isBlocked,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked
              ? const Color(0xFFFF6B6B).withOpacity(0.3)
              : const Color(0xFFE8ECF8),
        ),
      ),
      child: Row(
        children: [
          // Ícono categoría
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 22),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isBlocked
                        ? const Color(0xFF8A94B2)
                        : const Color(0xFF2D3A6B),
                    decoration: isBlocked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                            fontSize: 10, color: categoryColor),
                      ),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.block_rounded,
                          size: 12, color: Color(0xFFFF6B6B)),
                      const SizedBox(width: 3),
                      const Text('Bloqueada',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Switch
          Switch(
            value: !isBlocked,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF4CAF50),
            inactiveThumbColor: const Color(0xFFFF6B6B),
            inactiveTrackColor: const Color(0xFFFF6B6B).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}