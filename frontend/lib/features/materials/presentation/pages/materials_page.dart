import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/material_entity.dart';
import '../bloc/materials_bloc.dart';
import '../bloc/materials_event.dart';
import '../bloc/materials_state.dart';
import 'add_material_page.dart';
import 'material_details_page.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<MaterialsBloc>().add(const MaterialsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista materiałów'),
        actions: [
          IconButton(
            tooltip: 'Dodaj materiał',
            onPressed: _openAddMaterialForm,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Odśwież',
            onPressed: _refreshMaterials,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<MaterialsBloc, MaterialsState>(
        builder: (context, state) {
          if (state.status == MaterialsStatus.initial &&
              state.materials.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MaterialsStatus.loading && state.materials.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MaterialsStatus.failure) {
            return _ErrorState(
              message: state.errorMessage ?? 'Nie udało się pobrać materiałów',
              onRetry: _refreshMaterials,
            );
          }

          final visibleMaterials = _buildVisibleMaterials(state.materials);

          return RefreshIndicator(
            onRefresh: () async => _refreshMaterials(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FilterPanel(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _SummaryPanel(
                  totalCount: state.materials.length,
                  filteredCount: visibleMaterials.length,
                  isLoading: state.status == MaterialsStatus.loading,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: visibleMaterials.isEmpty
                      ? const _EmptyState(
                          key: ValueKey<String>('empty_state'),
                        )
                      : Column(
                          key: const ValueKey<String>('list_state'),
                          children: List.generate(visibleMaterials.length, (index) {
                            final material = visibleMaterials[index];

                            return _AnimatedMaterialCard(
                              index: index,
                              child: _MaterialCard(
                                material: material,
                                onTap: () => _openMaterialDetails(material),
                              ),
                            );
                          }),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _refreshMaterials() {
    context.read<MaterialsBloc>().add(const MaterialsRequested());
  }

  Future<void> _openAddMaterialForm() async {
    final wasAdded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddMaterialPage(),
      ),
    );

    if (wasAdded == true && mounted) {
      _refreshMaterials();
    }
  }

  Future<void> _openMaterialDetails(MaterialEntity material) async {
    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MaterialDetailsPage(material: material),
      ),
    );

    if (hasChanges == true && mounted) {
      _refreshMaterials();
    }
  }

  List<MaterialEntity> _buildVisibleMaterials(List<MaterialEntity> source) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = source.where((material) {
      if (query.isEmpty) {
        return true;
      }

      return material.name.toLowerCase().contains(query) ||
          material.serialNumber.toLowerCase().contains(query) ||
          (material.location?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Lista zawsze jest wyświetlana alfabetycznie po nazwie materiału.
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return filtered;
  }
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _FilterPanel({
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Szukaj po nazwie, numerze seryjnym lub lokalizacji',
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Wyczyść',
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final int totalCount;
  final int filteredCount;
  final bool isLoading;

  const _SummaryPanel({
    required this.totalCount,
    required this.filteredCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF006B38)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Widoczne: $filteredCount z $totalCount materiałów',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2A3A32),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
        ],
      ),
    );
  }
}

class _AnimatedMaterialCard extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedMaterialCard({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final beginOffset = const Offset(0, 0.12);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index * 45).clamp(0, 260)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(beginOffset.dx, beginOffset.dy * (1 - value) * 16),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialEntity material;
  final VoidCallback onTap;

  const _MaterialCard({
    required this.material,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1A00A54F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFF006B38),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nr seryjny: ${material.serialNumber}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lokalizacja: ${material.location ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5A685F),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7D8A82),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Color(0xFF7A8A82),
          ),
          const SizedBox(height: 10),
          Text(
            'Brak wyników dla podanych filtrów',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF32433A),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zmień frazę wyszukiwania lub sposób sortowania.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5B6B63),
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
