import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/material_repository.dart';

class EditMaterialPage extends StatefulWidget {
  final MaterialEntity material;

  const EditMaterialPage({
    super.key,
    required this.material,
  });

  @override
  State<EditMaterialPage> createState() => _EditMaterialPageState();
}

class _EditMaterialPageState extends State<EditMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _lengthController;
  late final TextEditingController _locationController;

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
    _locationController = TextEditingController(text: widget.material.location ?? '');
  }

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
        title: const Text('Edytuj materiał'),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Waga',
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
              label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz zmiany'),
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
    final result = await repository.updateMaterial(
      id: widget.material.id,
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
      (updatedMaterial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materiał został zaktualizowany.')),
        );
        Navigator.of(context).pop(updatedMaterial);
      },
    );
  }
}
