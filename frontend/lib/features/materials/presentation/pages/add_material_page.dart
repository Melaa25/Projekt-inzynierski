import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/material_repository.dart';

class AddMaterialPage extends StatefulWidget {
  const AddMaterialPage({super.key});

  @override
  State<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends State<AddMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj materiał'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nazwa',
                hintText: 'Np. Blacha stalowa',
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8E4DD)),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Waga',
                hintText: 'Np. 10.5',
              ),
              validator: (value) {
                final normalized = (value ?? '').replaceAll(',', '.').trim();
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Długość',
                hintText: 'Np. 250',
              ),
              validator: (value) {
                final normalized = (value ?? '').replaceAll(',', '.').trim();
                final number = double.tryParse(normalized);

                if (number == null || number < 0) {
                  return 'Podaj poprawną długość';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Lokalizacja (opcjonalnie)',
                hintText: 'Np. A-01-R03',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
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
          ],
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
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
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
