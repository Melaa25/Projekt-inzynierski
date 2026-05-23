import 'package:flutter/material.dart';

import '../../components/materials/empty_state.dart';
import '../../components/materials/error_state.dart';
import '../../components/materials/filter_panel.dart';
import '../../components/materials/material_card.dart';
import '../../components/materials/summary_panel.dart';
import '../../core/di/injection_container.dart';
import '../../models/material_entity.dart';
import '../../services/material_label_print_service.dart';
import '../../services/material_repository.dart';
import 'add_material_view.dart';
import 'material_details_view.dart';

class MaterialsView extends StatefulWidget {
  const MaterialsView({super.key});

  @override
  State<MaterialsView> createState() => _MaterialsViewState();
}

class _MaterialsViewState extends State<MaterialsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _selectedMaterialIds = <int>{};
  bool _isSelectionMode = false;
  bool _isPrintingLabels = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<MaterialEntity> _materials = const [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
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
        title: Text(
          _isSelectionMode
              ? 'Zaznaczone: ${_selectedMaterialIds.length}'
              : 'Lista materiałów',
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              tooltip: 'Zaznacz wszystkie widoczne',
              onPressed: () => _selectAllVisible(_materials),
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              tooltip: 'Drukuj etykiety',
              onPressed: _isPrintingLabels
                  ? null
                  : () => _printSelectedLabels(_materials),
              icon: _isPrintingLabels
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.print_rounded),
            ),
            IconButton(
              tooltip: 'Anuluj zaznaczanie',
              onPressed: _clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Tryb zaznaczania',
              onPressed: _enableSelectionMode,
              icon: const Icon(Icons.checklist_rounded),
            ),
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
        ],
      ),
      body: Builder(
        builder: (context) {
          final existingIds = _materials.map((material) => material.id).toSet();
          _selectedMaterialIds.removeWhere((id) => !existingIds.contains(id));
          if (_selectedMaterialIds.isEmpty &&
              _isSelectionMode &&
              !_isPrintingLabels) {
            _isSelectionMode = false;
          }

          if (_isLoading && _materials.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null && _materials.isEmpty) {
            return MaterialsErrorState(
              message: _errorMessage ?? 'Nie udało się pobrać materiałów',
              onRetry: _refreshMaterials,
            );
          }

          final visibleMaterials = _buildVisibleMaterials(_materials);

          return RefreshIndicator(
            onRefresh: () async => _refreshMaterials(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilterPanel(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });

                    _loadMaterials(search: value);
                  },
                ),
                const SizedBox(height: 12),
                SummaryPanel(
                  totalCount: _materials.length,
                  filteredCount: visibleMaterials.length,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: visibleMaterials.isEmpty
                      ? const MaterialsEmptyState(
                          key: ValueKey<String>('empty_state'),
                        )
                      : Column(
                          key: const ValueKey<String>('list_state'),
                          children: List.generate(visibleMaterials.length, (
                            index,
                          ) {
                            final material = visibleMaterials[index];

                            return _AnimatedMaterialCard(
                              index: index,
                              child: MaterialCard(
                                material: material,
                                isSelectionMode: _isSelectionMode,
                                isSelected: _selectedMaterialIds.contains(
                                  material.id,
                                ),
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(material);
                                  } else {
                                    _openMaterialDetails(material);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _enableSelectionMode();
                                  }
                                  _toggleSelection(material);
                                },
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

  void _enableSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _toggleSelection(MaterialEntity material) {
    setState(() {
      if (_selectedMaterialIds.contains(material.id)) {
        _selectedMaterialIds.remove(material.id);
      } else {
        _selectedMaterialIds.add(material.id);
      }

      if (_selectedMaterialIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllVisible(List<MaterialEntity> allMaterials) {
    final visibleIds = _buildVisibleMaterials(
      allMaterials,
    ).map((material) => material.id).toSet();

    if (visibleIds.isEmpty) {
      return;
    }

    setState(() {
      _isSelectionMode = true;
      _selectedMaterialIds.addAll(visibleIds);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMaterialIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _printSelectedLabels(List<MaterialEntity> allMaterials) async {
    final selectedMaterials = allMaterials
        .where((material) => _selectedMaterialIds.contains(material.id))
        .toList();

    if (selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaznacz co najmniej jeden materiał.')),
      );
      return;
    }

    setState(() {
      _isPrintingLabels = true;
    });

    try {
      await MaterialLabelPrintService.printManyLabels(selectedMaterials);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Przygotowano ${selectedMaterials.length} etykiet do wydruku.',
          ),
        ),
      );
      _clearSelection();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się przygotować etykiet: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingLabels = false;
        });
      }
    }
  }

  Future<void> _loadMaterials({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = getIt<MaterialRepository>();
    final result = await repository.getMaterials(
      search: search ?? _searchQuery,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (error) {
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      },
      (materials) {
        setState(() {
          _materials = materials;
          _isLoading = false;
          _errorMessage = null;
        });
      },
    );
  }

  void _refreshMaterials() {
    _loadMaterials();
  }

  Future<void> _openAddMaterialForm() async {
    final wasAdded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddMaterialView()),
    );

    if (wasAdded == true && mounted) {
      _refreshMaterials();
    }
  }

  Future<void> _openMaterialDetails(MaterialEntity material) async {
    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MaterialDetailsView(material: material),
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

    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return filtered;
  }
}

class _AnimatedMaterialCard extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedMaterialCard({required this.index, required this.child});

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
