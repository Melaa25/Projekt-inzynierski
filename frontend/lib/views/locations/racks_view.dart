import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../services/location_repository.dart';
import 'shelves_view.dart';

class RacksView extends StatefulWidget {
  final LocationEntity sector;

  const RacksView({super.key, required this.sector});

  @override
  State<RacksView> createState() => _RacksViewState();
}

class _RacksViewState extends State<RacksView> {
  bool _isLoading = true;
  List<LocationEntity> _racks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final repo = getIt<LocationRepository>();
    final res = await repo.getLocations(type: 'regal', parentId: widget.sector.id);

    res.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (list) => _racks = list,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _showDialog({LocationEntity? rack}) async {
    final nameController = TextEditingController(text: rack?.name ?? '');
    final codeController = TextEditingController(text: rack?.code ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rack == null ? 'Nowy regał' : 'Edytuj regał'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: codeController, decoration: const InputDecoration(labelText: 'Kod')),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nazwa (np. Regał 4)'),
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
    final result = rack == null
        ? await repo.createLocation(
            name: nameController.text.trim(),
            type: 'regal',
            parentId: widget.sector.id,
            code: codeController.text.trim(),
          )
        : await repo.updateLocation(
            id: rack.id,
            name: nameController.text.trim(),
            type: 'regal',
            parentId: widget.sector.id,
            code: codeController.text.trim(),
          );

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  Future<void> _delete(LocationEntity rack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń regał'),
        content: Text('Usunąć "${rack.name}" razem z półkami?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = getIt<LocationRepository>();
    final result = await repo.deleteLocation(rack.id);

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Regały — ${widget.sector.name}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _racks.isEmpty
              ? const Center(child: Text('Brak regałów'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _racks.length,
                  itemBuilder: (context, i) {
                    final rack = _racks[i];
                    return Card(
                      child: ListTile(
                        title: Text(rack.name),
                        subtitle: Text('${rack.childrenCount} półek'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(rack: rack)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(rack)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ShelvesView(rack: rack)),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}