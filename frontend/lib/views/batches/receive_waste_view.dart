import 'package:flutter/material.dart';

import '../../components/forms/form_cards.dart';
import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../models/material_batch_entity.dart';
import '../../services/location_repository.dart';
import '../../services/material_batch_repository.dart';
import '../../services/batch_label_print_service.dart';

class ReceiveWasteView extends StatefulWidget {
  const ReceiveWasteView({super.key});

  @override
  State<ReceiveWasteView> createState() => _ReceiveWasteViewState();
}

class _ReceiveWasteViewState extends State<ReceiveWasteView> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  List<LocationEntity> _locations = [];
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
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
    });

    final repo = getIt<LocationRepository>();
    final result = await repo.getLocations();

    if (!mounted) {
      return;
    }

    result.fold(
      (_) => null,
      (list) => setState(() => _locations = list),
    );

    setState(() {
      _isLoadingOptions = false;
    });
  }

  Future<void> _checkLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz lokalizację.')),
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
      type: 'waste',
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
    final weightText = _weightController.text.replaceAll(',', '.').trim();
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);

    final result = await repo.receiveWaste(
      quantity: quantity,
      weight: weight,
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
                  ? 'Utworzono nową partię odpadów ${batch.batchCode}.'
                  : 'Dodano $quantity szt. do partii odpadów ${batch.batchCode}.',
            ),
          ),
        );

        if (wasNewBatch && mounted) {
          final shouldPrint = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Nowa etykieta'),
              content: Text(
                'Utworzono nową partię odpadów z kodem ${batch.batchCode}. Wydrukować etykietę na regał?',
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
      appBar: AppBar(title: const Text('Przyjęcie odpadu')),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const FormHeaderCard(
                    icon: Icons.delete_outline_rounded,
                    title: 'Przyjęcie odpadu',
                    subtitle:
                        'Odpady różnych kształtów na tej samej lokalizacji trafiają pod jeden wspólny kod.',
                  ),
                  const SizedBox(height: 16),
                  FormSectionCard(
                    title: 'Dane przyjęcia',
                    child: Column(
                      children: [
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
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Waga łączna (kg, opcjonalnie)',
                            prefixIcon: Icon(Icons.scale_rounded),
                          ),
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
                            ? 'Na tej lokalizacji nie ma jeszcze partii odpadów. Zostanie utworzona nowa partia i nowa etykieta do wydruku.'
                            : 'Na tej lokalizacji jest już partia odpadów ${_existingBatch!.batchCode} (${_existingBatch!.quantity} szt.). Nowa ilość zostanie do niej dodana, etykieta pozostaje bez zmian.',
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