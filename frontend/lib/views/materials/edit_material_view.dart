import 'package:flutter/material.dart';

import '../../components/forms/form_cards.dart';
import '../../core/di/injection_container.dart';
import '../../models/material_entity.dart';
import '../../models/material_status.dart';
import '../../services/material_repository.dart';
import '../../models/location_entity.dart';
import '../../services/location_repository.dart';

class EditMaterialView extends StatefulWidget {
  final MaterialEntity material;

  const EditMaterialView({super.key, required this.material});

  @override
  State<EditMaterialView> createState() => _EditMaterialViewState();
}

class _EditMaterialViewState extends State<EditMaterialView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _lengthController;
  late String _selectedStatus;
  LocationEntity? _selectedLocation;
  List<LocationEntity> _locations = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.material.name);
    _weightController = TextEditingController(
      text: widget.material.weight.toStringAsFixed(2),
    );
    _lengthController = TextEditingController(
      text: widget.material.length.toStringAsFixed(2),
    );
    _selectedStatus = widget.material.status;
    _selectedLocation = widget.material.currentLocation;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final repo = getIt<LocationRepository>();
    final res = await repo.getLocations();
    res.fold((_) => null, (list) => setState(() => _locations = list));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj materiał')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7F5), Color(0xFFEAF4EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const FormHeaderCard(
                icon: Icons.edit_note_rounded,
                title: 'Edycja materiału',
                subtitle:
                    'Aktualizuj dane bez zmiany numeru seryjnego. Zmiany zapiszesz w kilku prostych krokach.',
              ),
              const SizedBox(height: 16),
              FormSectionCard(
                title: 'Dane podstawowe',
                subtitle: 'Podstawowe pola opisujące materiał.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Podaj nazwę materiału';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD9E4DC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Numer seryjny: ${widget.material.serialNumber}\nGenerowany automatycznie przy dodawaniu materiału.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Waga',
                        prefixIcon: Icon(Icons.scale_rounded),
                      ),
                      validator: (value) {
                        final normalized = (value ?? '')
                            .replaceAll(',', '.')
                            .trim();
                        final number = double.tryParse(normalized);

                        if (number == null || number < 0) {
                          return 'Podaj poprawną wagę';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lengthController,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Długość',
                        prefixIcon: Icon(Icons.straighten_rounded),
                      ),
                      validator: (value) {
                        final normalized = (value ?? '')
                            .replaceAll(',', '.')
                            .trim();
                        final number = double.tryParse(normalized);

                        if (number == null || number < 0) {
                          return 'Podaj poprawną długość';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FormSectionCard(
                title: 'Lokalizacja i status',
                subtitle: 'Szybka zmiana miejsca i stanu materiału.',
                child: Column(
                  children: [
                    DropdownButtonFormField<LocationEntity?>(
                      value: _selectedLocation,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lokalizacja (z listy)',
                        prefixIcon: Icon(Icons.place_rounded),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Wybierz lokalizację z listy';
                        }

                        return null;
                      },
                      items: [
                        ..._locations.map(
                          (l) => DropdownMenuItem<LocationEntity?>(
                            value: l,
                            child: Text(l.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status materiału',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      items: MaterialStatus.values
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(MaterialStatus.label(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
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
                  label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz zmiany'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository = getIt<MaterialRepository>();
    final result = await repository.updateMaterial(
      id: widget.material.id,
      name: _nameController.text.trim(),
      weight: double.parse(_weightController.text.replaceAll(',', '.').trim()),
      length: double.parse(_lengthController.text.replaceAll(',', '.').trim()),
      location: _selectedLocation?.name,
      currentLocationId: _selectedLocation?.id,
      status: _selectedStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    result.fold(
      (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
      (updatedMaterial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materiał został zaktualizowany.')),
        );
        Navigator.of(context).pop(updatedMaterial);
      },
    );
  }
}
