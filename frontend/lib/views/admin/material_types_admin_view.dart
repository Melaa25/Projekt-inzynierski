import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/material_type_entity.dart';
import '../../services/material_type_repository.dart';

class MaterialTypesAdminView extends StatefulWidget {
  const MaterialTypesAdminView({super.key});

  @override
  State<MaterialTypesAdminView> createState() => _MaterialTypesAdminViewState();
}

class _MaterialTypesAdminViewState extends State<MaterialTypesAdminView> {
  bool _isLoading = true;
  List<MaterialTypeEntity> _materials = [];
  String? _error;

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

    final repo = getIt<MaterialTypeRepository>();
    final result = await repo.getMaterialTypes();

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => setState(() {
        _error = error;
        _isLoading = false;
      }),
      (list) => setState(() {
        _materials = list;
        _isLoading = false;
      }),
    );
  }

  Future<void> _openMaterialDialog({MaterialTypeEntity? material}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: material?.name ?? '');
    final weightController = TextEditingController(
      text: material == null ? '' : material.weight.toStringAsFixed(2),
    );
    final lengthController = TextEditingController(
      text: material == null ? '' : material.length.toStringAsFixed(2),
    );
    final thicknessController = TextEditingController(
      text: material == null ? '' : material.thickness.toStringAsFixed(2),
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(material == null ? 'Dodaj typ materiału' : 'Edytuj typ materiału'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Podaj nazwę materiału';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Waga',
                        prefixIcon: Icon(Icons.scale_rounded),
                      ),
                      validator: (value) {
                        final number = double.tryParse((value ?? '').replaceAll(',', '.').trim());
                        if (number == null || number < 0) {
                          return 'Podaj poprawną wagę';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lengthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Długość',
                        prefixIcon: Icon(Icons.straighten_rounded),
                      ),
                      validator: (value) {
                        final number = double.tryParse((value ?? '').replaceAll(',', '.').trim());
                        if (number == null || number < 0) {
                          return 'Podaj poprawną długość';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thicknessController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Grubość',
                        prefixIcon: Icon(Icons.layers_rounded),
                      ),
                      validator: (value) {
                        final number = double.tryParse((value ?? '').replaceAll(',', '.').trim());
                        if (number == null || number < 0) {
                          return 'Podaj poprawną grubość';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
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
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || !mounted) {
      return;
    }

    final repo = getIt<MaterialTypeRepository>();
    final weight = double.parse(weightController.text.replaceAll(',', '.').trim());
    final length = double.parse(lengthController.text.replaceAll(',', '.').trim());
    final thickness = double.parse(thicknessController.text.replaceAll(',', '.').trim());

    final result = material == null
        ? await repo.createMaterialType(
            name: nameController.text.trim(),
            weight: weight,
            length: length,
            thickness: thickness,
          )
        : await repo.updateMaterialType(
            id: material.id,
            name: nameController.text.trim(),
            weight: weight,
            length: length,
            thickness: thickness,
          );

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(material == null ? 'Typ materiału został dodany.' : 'Typ materiału został zaktualizowany.'),
          ),
        );
        await _load();
      },
    );
  }

  Future<void> _deleteMaterial(MaterialTypeEntity material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Usuń typ materiału'),
        content: Text('Na pewno usunąć "${material.name}"?'),
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

    if (confirmed != true) {
      return;
    }

    final repo = getIt<MaterialTypeRepository>();
    final result = await repo.deleteMaterialType(material.id);

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))),
      (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Typ materiału został usunięty.')),
        );
        await _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog materiałów'),
        actions: [
          IconButton(
            tooltip: 'Dodaj typ materiału',
            onPressed: () => _openMaterialDialog(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                  title: const Text('Nie udało się pobrać materiałów'),
                  subtitle: Text(_error!),
                  trailing: IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              )
            else if (_materials.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Brak typów materiałów w katalogu.'),
                ),
              )
            else
              ..._materials.map(
                (material) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.category_rounded, color: Color(0xFF006B38)),
                    title: Text(material.name),
                    subtitle: Text(
                      'Waga: ${material.weight} • Długość: ${material.length} • Grubość: ${material.thickness}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _openMaterialDialog(material: material),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          onPressed: () => _deleteMaterial(material),
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMaterialDialog(),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Dodaj typ materiału'),
      ),
    );
  }
}