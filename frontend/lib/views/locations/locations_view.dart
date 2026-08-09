import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../services/location_repository.dart';
import 'racks_view.dart';

class LocationsView extends StatefulWidget {
  const LocationsView({super.key});

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  bool _isLoading = true;
  List<LocationEntity> _sectors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final repo = getIt<LocationRepository>();
    final res = await repo.getLocations(type: 'sektor');

    res.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (list) => _sectors = list,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _showDialog({LocationEntity? sector}) async {
    final nameController = TextEditingController(text: sector?.name ?? '');
    final codeController = TextEditingController(text: sector?.code ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sector == null ? 'Nowy sektor' : 'Edytuj sektor'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: codeController, decoration: const InputDecoration(labelText: 'Kod')),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nazwa'),
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
    final result = sector == null
        ? await repo.createLocation(name: nameController.text.trim(), type: 'sektor', code: codeController.text.trim())
        : await repo.updateLocation(id: sector.id, name: nameController.text.trim(), type: 'sektor', code: codeController.text.trim());

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  Future<void> _delete(LocationEntity sector) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń sektor'),
        content: Text('Usunąć "${sector.name}" razem z regałami i półkami?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = getIt<LocationRepository>();
    final result = await repo.deleteLocation(sector.id);

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sektory')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sectors.isEmpty
              ? const Center(child: Text('Brak sektorów'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sectors.length,
                  itemBuilder: (context, i) {
                    final sector = _sectors[i];
                    return Card(
                      child: ListTile(
                        title: Text(sector.name),
                        subtitle: Text('${sector.childrenCount} regałów'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(sector: sector)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(sector)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RacksView(sector: sector)),
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