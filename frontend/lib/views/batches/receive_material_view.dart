import 'package:flutter/material.dart';

import '../../components/forms/form_cards.dart';
import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../models/material_batch_entity.dart';
import '../../models/material_type_entity.dart';
import '../../services/location_repository.dart';
import '../../services/material_batch_repository.dart';
import '../../services/material_type_repository.dart';
import '../../services/batch_label_print_service.dart';

class ReceiveMaterialView extends StatefulWidget {
  const ReceiveMaterialView({super.key});

  @override
  State<ReceiveMaterialView> createState() => _ReceiveMaterialViewState();
}

class _ReceiveMaterialViewState extends State<ReceiveMaterialView> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  List<MaterialTypeEntity> _materials = [];
  List<LocationEntity> _locations = [];
  MaterialTypeEntity? _selectedMaterial;
  LocationEntity? _selectedLocation;

  bool _isLoadingOptions = true;
  bool _isChecking = false;
  bool _isSaving = false;
  bool _hasChecked = false;
  MaterialBatchEntity? _existingBatch;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
    });

    final materialRepo = getIt<MaterialTypeRepository>();
    final locationRepo = getIt<LocationRepository>();

    final materialsResult = await materialRepo.getMaterialTypes();
    final locationsResult = await locationRepo.getLocations();

    if (!mounted) {
      return;
    }

    materialsResult.fold(
      (_) => null,
      (list) => setState(() => _materials = list),
    );

    locationsResult.fold(
      (_) => null,
      (list) => setState(() => _locations = list),
    );

    setState(() {
      _isLoadingOptions = false;
    });
  }

  Future<void> _checkLocation() async {
    if (_selectedMaterial == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz materiał i lokalizację.')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _hasChecked = false;
      _existingBatch = null;
    });

    final repo = getIt<MaterialBatchRepository>();
    final result = await repo.suggestExisting(
      materialId: _selectedMaterial!.id,
      type: 'material',
      locationId: _selectedLocation!.id,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      },
      (batch) {
        setState(() {
          _existingBatch = batch;
          _hasChecked = true;
        });
      },
    );

    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_hasChecked) {
      if (!_hasChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Najpierw sprawdź lokalizację.')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repo = getIt<MaterialBatchRepository>();
    final quantity = int.parse(_quantityController.text.trim());

    final result = await repo.receiveMaterial(
      materialId: _selectedMaterial!.id,
      quantity: quantity,
      locationId: _selectedLocation!.id,
      targetBatchId: _existingBatch?.id,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    await result.fold(
      (error) async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      },
      (batch) async {
        final wasNewBatch = _existingBatch == null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasNewBatch
                  ? 'Utworzono nową partię ${batch.batchCode}.'
                  : 'Dodano $quantity szt. do partii ${batch.batchCode}.',
            ),
          ),
        );

        if (wasNewBatch && mounted) {
          final shouldPrint = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Nowa etykieta'),
              content: Text(
                'Utworzono nową partię z kodem ${batch.batchCode}. Wydrukować etykietę na regał?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Później'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Drukuj'),
                ),
              ],
            ),
          );

          if (shouldPrint == true) {
            await BatchLabelPrintService.printSingleLabel(batch);
          }
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Przyjęcie materiału')),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const FormHeaderCard(
                    icon: Icons.move_to_inbox_rounded,
                    title: 'Przyjęcie materiału',
                    subtitle:
                        'Wybierz typ materiału, ilość i lokalizację. Jeśli na tej lokalizacji jest już taka sama partia, ilość zostanie do niej dodana.',
                  ),
                  const SizedBox(height: 16),
                  FormSectionCard(
                    title: 'Dane przyjęcia',
                    child: Column(
                      children: [
                        DropdownButtonFormField<MaterialTypeEntity>(
                          value: _selectedMaterial,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Typ materiału',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: _materials
                              .map(
                                (m) => DropdownMenuItem<MaterialTypeEntity>(
                                  value: m,
                                  child: Text(m.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMaterial = value;
                              _hasChecked = false;
                              _existingBatch = null;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Wybierz typ materiału';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ilość (szt.)',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                          validator: (value) {
                            final number = int.tryParse((value ?? '').trim());
                            if (number == null || number < 1) {
                              return 'Podaj poprawną ilość';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<LocationEntity>(
                          value: _selectedLocation,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Lokalizacja',
                            prefixIcon: Icon(Icons.place_rounded),
                          ),
                          items: _locations
                              .map(
                                (l) => DropdownMenuItem<LocationEntity>(
                                  value: l,
                                  child: Text(l.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLocation = value;
                              _hasChecked = false;
                              _existingBatch = null;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Wybierz lokalizację';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Uwagi (opcjonalnie)',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : _checkLocation,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      label: Text(_isChecking ? 'Sprawdzanie...' : 'Sprawdź lokalizację'),
                    ),
                  ),
                  if (_hasChecked) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD9E4DC)),
                      ),
                      child: Text(
                        _existingBatch == null
                            ? 'Na tej lokalizacji nie ma jeszcze tego materiału. Zostanie utworzona nowa partia i nowa etykieta do wydruku.'
                            : 'Na tej lokalizacji jest już partia ${_existingBatch!.batchCode} (${_existingBatch!.quantity} szt.). Nowa ilość zostanie do niej dodana, etykieta pozostaje bez zmian.',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz przyjęcie'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}