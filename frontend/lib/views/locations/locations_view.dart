import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../services/location_repository.dart';

class LocationsView extends StatefulWidget {
  const LocationsView({super.key});

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  bool _isLoading = true;
  List<LocationEntity> _locations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final repo = getIt<LocationRepository>();
    final res = await repo.getLocations();
    res.fold(
      (err) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
      },
      (list) {
        setState(() => _locations = list);
      },
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showEditDialog({LocationEntity? location}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: location?.name ?? '');
    final codeController = TextEditingController(text: location?.code ?? '');
    final typeController = TextEditingController(text: location?.type ?? '');
    final descController = TextEditingController(
      text: location?.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          location == null ? 'Nowa lokalizacja' : 'Edytuj lokalizację',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kod'),
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nazwa'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Podaj nazwę lokalizacji';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Typ'),
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Opis'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              final repo = getIt<LocationRepository>();
              final result = location == null
                  ? await repo.createLocation(
                      name: nameController.text.trim(),
                      code: codeController.text.trim().isEmpty
                          ? null
                          : codeController.text.trim(),
                      type: typeController.text.trim().isEmpty
                          ? null
                          : typeController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    )
                  : await repo.updateLocation(
                      id: location.id,
                      name: nameController.text.trim(),
                      code: codeController.text.trim().isEmpty
                          ? null
                          : codeController.text.trim(),
                      type: typeController.text.trim().isEmpty
                          ? null
                          : typeController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );

              if (!mounted) return;

              final hasError = result.fold((err) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
                return true;
              }, (_) => false);

              if (hasError) {
                return;
              }

              Navigator.of(ctx).pop(true);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _load();
    }
  }

  Future<void> _delete(LocationEntity location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń lokalizację'),
        content: Text('Na pewno usunąć "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = getIt<LocationRepository>();
    final res = await repo.deleteLocation(location.id);
    res.fold(
      (err) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lokalizacje magazynowe')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final loc = _locations[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.place_rounded,
                        color: Color(0xFF006B38),
                      ),
                      title: Text(loc.name),
                      subtitle: Text(loc.code ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showEditDialog(location: loc),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _delete(loc),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        label: const Text('Nowa lokalizacja'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
