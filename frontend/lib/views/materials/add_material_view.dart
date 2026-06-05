import 'package:flutter/material.dart';

import '../../components/forms/form_cards.dart';
import '../../core/di/injection_container.dart';
import '../../models/material_status.dart';
import '../../services/material_repository.dart';
import '../../models/location_entity.dart';
import '../../services/location_repository.dart';

class AddMaterialView extends StatefulWidget {
  const AddMaterialView({super.key});

  @override
  State<AddMaterialView> createState() => _AddMaterialViewState();
}

class _AddMaterialViewState extends State<AddMaterialView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  LocationEntity? _selectedLocation;
  List<LocationEntity> _locations = [];
  String _selectedStatus = MaterialStatus.inStock;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final repo = getIt<LocationRepository>();
    final res = await repo.getLocations();
    res.fold((_) => null, (list) => setState(() => _locations = list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj materiał')),
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
                icon: Icons.inventory_2_rounded,
                title: 'Nowy materiał',
                subtitle:
                    'Wprowadź podstawowe dane, wskaż lokalizację i ustaw status. Numer seryjny wygeneruje się automatycznie.',
              ),
              const SizedBox(height: 16),
              FormSectionCard(
                title: 'Dane podstawowe',
                subtitle: 'Najważniejsze informacje identyfikujące materiał.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa',
                        hintText: 'Np. Blacha stalowa',
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
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Numer seryjny zostanie wygenerowany automatycznie na podstawie nazwy (np. BL-0001).',
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
                        hintText: 'Np. 10.5',
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
                        hintText: 'Np. 250',
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
                subtitle: 'Określ gdzie materiał trafi po dodaniu.',
                child: Column(
                  children: [
                    DropdownButtonFormField<LocationEntity?>(
                      value: _selectedLocation,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lokalizacja',
                        prefixIcon: Icon(Icons.place_rounded),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Wybierz lokalizację';
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
                  label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz materiał'),
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
    final result = await repository.createMaterial(
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
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materiał został dodany.')),
        );
        Navigator.of(context).pop(true);
      },
    );
  }
}
