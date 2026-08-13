import 'package:flutter/material.dart';

import '../../components/common/responsive_container.dart';
import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../services/location_repository.dart';
import '../batches/shelf_batches_view.dart';

class ShelvesView extends StatefulWidget {
  final LocationEntity rack;

  const ShelvesView({super.key, required this.rack});

  @override
  State<ShelvesView> createState() => _ShelvesViewState();
}

class _ShelvesViewState extends State<ShelvesView> {
  bool _isLoading = true;
  List<LocationEntity> _shelves = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final repo = getIt<LocationRepository>();
    final res = await repo.getLocations(type: 'polka', parentId: widget.rack.id);

    res.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (list) => _shelves = list,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _showDialog({LocationEntity? shelf}) async {
    final nameController = TextEditingController(text: shelf?.name ?? '');
    final codeController = TextEditingController(text: shelf?.code ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shelf == null ? 'Nowa półka' : 'Edytuj półkę'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: codeController, decoration: const InputDecoration(labelText: 'Kod')),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nazwa (np. Półka 6)'),
                validator: (v) => v!.trim().isEmpty ? 'Podaj nazwę' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final repo = getIt<LocationRepository>();
    final result = shelf == null
        ? await repo.createLocation(
            name: nameController.text.trim(),
            type: 'polka',
            parentId: widget.rack.id,
            code: codeController.text.trim(),
          )
        : await repo.updateLocation(
            id: shelf.id,
            name: nameController.text.trim(),
            type: 'polka',
            parentId: widget.rack.id,
            code: codeController.text.trim(),
          );

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  Future<void> _delete(LocationEntity shelf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń półkę'),
        content: Text('Usunąć "${shelf.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = getIt<LocationRepository>();
    final result = await repo.deleteLocation(shelf.id);

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Półki — ${widget.rack.name}')),
      body: ResponsiveContainer(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _shelves.isEmpty
                ? const Center(child: Text('Brak półek'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shelves.length,
                    itemBuilder: (context, i) {
                      final shelf = _shelves[i];
                      return Card(
                        child: ListTile(
                          title: Text(shelf.name),
                          subtitle: Text(shelf.code ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(shelf: shelf)),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(shelf)),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ShelfBatchesView(shelf: shelf)),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}