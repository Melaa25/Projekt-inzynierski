import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/batch_status.dart';
import '../../models/material_batch_entity.dart';
import '../../services/auth_service.dart';
import '../../services/batch_label_print_service.dart';
import '../../services/material_batch_repository.dart';

class BatchDetailsView extends StatefulWidget {
  final String batchCode;

  const BatchDetailsView({super.key, required this.batchCode});

  @override
  State<BatchDetailsView> createState() => _BatchDetailsViewState();
}

class _BatchDetailsViewState extends State<BatchDetailsView> {
  MaterialBatchEntity? _batch;
  bool _isLoading = true;
  String? _error;
  bool _isBusy = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = getIt<MaterialBatchRepository>();
    final result = await repo.getBatchByCode(widget.batchCode);

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => setState(() {
        _error = error;
        _isLoading = false;
      }),
      (batch) => setState(() {
        _batch = batch;
        _isLoading = false;
      }),
    );
  }

  Future<void> _addQuantity() async {
    final batch = _batch;
    if (batch == null) {
      return;
    }

    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dodaj ilość'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ilość (szt.)'),
                validator: (value) {
                  final number = int.tryParse((value ?? '').trim());
                  if (number == null || number < 1) {
                    return 'Podaj poprawną ilość';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Uwagi (opcjonalnie)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    final repo = getIt<MaterialBatchRepository>();
    final quantity = int.parse(quantityController.text.trim());
    final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();

    final result = batch.isWaste
        ? await repo.receiveWaste(
            quantity: quantity,
            weight: null,
            locationId: batch.currentLocationId!,
            targetBatchId: batch.id,
            note: note,
          )
        : await repo.receiveMaterial(
            materialId: batch.materialId!,
            quantity: quantity,
            locationId: batch.currentLocationId!,
            targetBatchId: batch.id,
            note: note,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
    });

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dodano $quantity szt. do partii.')),
        );
        _hasChanges = true;
        _load();
      },
    );
  }

  Future<void> _issueQuantity() async {
    final batch = _batch;
    if (batch == null) {
      return;
    }

    final quantityController = TextEditingController();
    final destinationController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wydaj materiał'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ilość (dostępne: ${batch.quantity} szt.)',
                ),
                validator: (value) {
                  final number = int.tryParse((value ?? '').trim());
                  if (number == null || number < 1) {
                    return 'Podaj poprawną ilość';
                  }
                  if (number > batch.quantity) {
                    return 'Przekracza dostępną ilość';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'Cel wydania (opcjonalnie)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Uwagi (opcjonalnie)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Wydaj'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    final repo = getIt<MaterialBatchRepository>();
    final quantity = int.parse(quantityController.text.trim());

    final result = await repo.issueBatch(
      batchId: batch.id,
      quantity: quantity,
      destination: destinationController.text.trim().isEmpty ? null : destinationController.text.trim(),
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
    });

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wydano $quantity szt.')),
        );
        _hasChanges = true;
        _load();
      },
    );
  }

  Future<void> _changeStatus() async {
    final batch = _batch;
    if (batch == null) {
      return;
    }

    String selectedStatus = batch.status;
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Zmień status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: BatchStatus.values
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(BatchStatus.label(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Uwagi (opcjonalnie)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    final repo = getIt<MaterialBatchRepository>();
    final result = await repo.updateBatchStatus(
      batchId: batch.id,
      status: selectedStatus,
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBusy = false;
    });

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status zaktualizowany.')),
        );
        _hasChanges = true;
        _load();
      },
    );
  }

  Future<void> _printLabel() async {
    final batch = _batch;
    if (batch == null) {
      return;
    }

    try {
      await BatchLabelPrintService.printSingleLabel(batch);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wydrukować etykiety: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final batch = _batch;
    if (batch == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń partię'),
        content: Text('Na pewno usunąć partię ${batch.batchCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final repo = getIt<MaterialBatchRepository>();
    final result = await repo.deleteBatch(batch.id);

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partia została usunięta.')),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    final canManage = authService.isAdmin || authService.currentUser?.role == 'kierownik';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          title: const Text('Szczegóły partii'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!)))
                : _batch == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: _batch!.isWaste
                                    ? const [Color(0xFF8E1B1B), Color(0xFF5A0F0F)]
                                    : const [Color(0xFF00A54F), Color(0xFF006B38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _batch!.displayName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kod partii: ${_batch!.batchCode}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFE5FFF1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.numbers_rounded, color: Color(0xFF006B38)),
                              title: const Text('Ilość'),
                              subtitle: Text('${_batch!.quantity} szt.'),
                            ),
                          ),
                          if (_batch!.totalWeight != null)
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.scale_rounded, color: Color(0xFF006B38)),
                                title: const Text('Waga łączna'),
                                subtitle: Text('${_batch!.totalWeight} kg'),
                              ),
                            ),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.place_rounded, color: Color(0xFF006B38)),
                              title: const Text('Lokalizacja'),
                              subtitle: Text(_batch!.currentLocation?.name ?? '-'),
                            ),
                          ),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.flag_rounded, color: Color(0xFF006B38)),
                              title: const Text('Status'),
                              subtitle: Text(BatchStatus.label(_batch!.status)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isBusy ? null : _addQuantity,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Dodaj ilość'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: _isBusy ? null : _issueQuantity,
                                  icon: const Icon(Icons.call_made_rounded),
                                  label: const Text('Wydaj'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isBusy ? null : _changeStatus,
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('Zmień status'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _printLabel,
                              icon: const Icon(Icons.print_rounded),
                              label: const Text('Drukuj etykietę'),
                            ),
                          ),
                          if (canManage) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: _confirmDelete,
                                icon: const Icon(Icons.delete_rounded),
                                label: const Text('Usuń partię'),
                                style: FilledButton.styleFrom(
                                  foregroundColor: const Color(0xFF8E1B1B),
                                ),
                              ),
                            ),
                          ],
                          if (_batch!.movements != null && _batch!.movements!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Historia ruchów',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._batch!.movements!.map(
                              (movement) => Card(
                                child: ListTile(
                                  title: Text(
                                    '${movement.type} (${movement.quantityDelta > 0 ? '+' : ''}${movement.quantityDelta} szt.)',
                                  ),
                                  subtitle: Text(
                                    '${movement.userName ?? '-'} • ${movement.createdAt.toLocal()}${movement.note != null ? '\n${movement.note}' : ''}',
                                  ),
                                  isThreeLine: movement.note != null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
      ),
    );
  }
}