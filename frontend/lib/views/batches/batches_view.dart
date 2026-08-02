import 'package:flutter/material.dart';

import '../../components/materials/empty_state.dart';
import '../../components/materials/error_state.dart';
import '../../components/materials/filter_panel.dart';
import '../../components/materials/summary_panel.dart';
import '../../components/batches/batch_card.dart';
import '../../core/di/injection_container.dart';
import '../../models/material_batch_entity.dart';
import '../../services/batch_label_print_service.dart';
import '../../services/material_batch_repository.dart';
import 'batch_details_view.dart';
import 'receive_material_view.dart';
import 'receive_waste_view.dart';

class BatchesView extends StatefulWidget {
  const BatchesView({super.key});

  @override
  State<BatchesView> createState() => _BatchesViewState();
}

class _BatchesViewState extends State<BatchesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _typeFilter;
  final Set<int> _selectedBatchIds = <int>{};
  bool _isSelectionMode = false;
  bool _isPrintingLabels = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<MaterialBatchEntity> _batches = const [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
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
          _isSelectionMode ? 'Zaznaczone: ${_selectedBatchIds.length}' : 'Partie materiałów',
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              tooltip: 'Drukuj etykiety',
              onPressed: _isPrintingLabels ? null : _printSelectedLabels,
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
              tooltip: 'Przyjmij materiał',
              onPressed: _openReceiveMaterial,
              icon: const Icon(Icons.add_box_rounded),
            ),
            IconButton(
              tooltip: 'Przyjmij odpad',
              onPressed: _openReceiveWaste,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            IconButton(
              tooltip: 'Odśwież',
              onPressed: _refreshBatches,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
      body: Builder(
        builder: (context) {
          final existingIds = _batches.map((batch) => batch.id).toSet();
          _selectedBatchIds.removeWhere((id) => !existingIds.contains(id));
          if (_selectedBatchIds.isEmpty && _isSelectionMode && !_isPrintingLabels) {
            _isSelectionMode = false;
          }

          if (_isLoading && _batches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null && _batches.isEmpty) {
            return MaterialsErrorState(
              message: _errorMessage ?? 'Nie udało się pobrać partii',
              onRetry: _refreshBatches,
            );
          }

          final visibleBatches = _buildVisibleBatches(_batches);

          return RefreshIndicator(
            onRefresh: () async => _refreshBatches(),
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
                    _loadBatches(search: value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Wszystkie'),
                        selected: _typeFilter == null,
                        onSelected: (_) => _applyTypeFilter(null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Materiały'),
                        selected: _typeFilter == 'material',
                        onSelected: (_) => _applyTypeFilter('material'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Odpady'),
                        selected: _typeFilter == 'waste',
                        onSelected: (_) => _applyTypeFilter('waste'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SummaryPanel(
                  totalCount: _batches.length,
                  filteredCount: visibleBatches.length,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),
                visibleBatches.isEmpty
                    ? const MaterialsEmptyState()
                    : Column(
                        children: visibleBatches
                            .map(
                              (batch) => BatchCard(
                                batch: batch,
                                isSelectionMode: _isSelectionMode,
                                isSelected: _selectedBatchIds.contains(batch.id),
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(batch);
                                  } else {
                                    _openBatchDetails(batch);
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    setState(() => _isSelectionMode = true);
                                  }
                                  _toggleSelection(batch);
                                },
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _applyTypeFilter(String? type) {
    setState(() {
      _typeFilter = type;
    });
    _loadBatches(search: _searchQuery);
  }

  void _toggleSelection(MaterialBatchEntity batch) {
    setState(() {
      if (_selectedBatchIds.contains(batch.id)) {
        _selectedBatchIds.remove(batch.id);
      } else {
        _selectedBatchIds.add(batch.id);
      }

      if (_selectedBatchIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedBatchIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _printSelectedLabels() async {
    final selected = _batches.where((batch) => _selectedBatchIds.contains(batch.id)).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaznacz co najmniej jedną partię.')),
      );
      return;
    }

    setState(() {
      _isPrintingLabels = true;
    });

    try {
      await BatchLabelPrintService.printManyLabels(selected);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Przygotowano ${selected.length} etykiet do wydruku.')),
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

  Future<void> _loadBatches({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = getIt<MaterialBatchRepository>();
    final result = await repository.getBatches(
      search: search ?? _searchQuery,
      type: _typeFilter,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => setState(() {
        _errorMessage = error;
        _isLoading = false;
      }),
      (batches) => setState(() {
        _batches = batches;
        _isLoading = false;
        _errorMessage = null;
      }),
    );
  }

  void _refreshBatches() {
    _loadBatches();
  }

  Future<void> _openReceiveMaterial() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ReceiveMaterialView()),
    );

    if (added == true && mounted) {
      _refreshBatches();
    }
  }

  Future<void> _openReceiveWaste() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ReceiveWasteView()),
    );

    if (added == true && mounted) {
      _refreshBatches();
    }
  }

  Future<void> _openBatchDetails(MaterialBatchEntity batch) async {
    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BatchDetailsView(batchCode: batch.batchCode),
      ),
    );

    if (hasChanges == true && mounted) {
      _refreshBatches();
    }
  }

  List<MaterialBatchEntity> _buildVisibleBatches(List<MaterialBatchEntity> source) {
    final sorted = [...source];
    sorted.sort((a, b) => b.id.compareTo(a.id));
    return sorted;
  }
}