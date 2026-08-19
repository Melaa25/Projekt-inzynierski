import 'package:flutter/material.dart';

import '../../components/common/responsive_container.dart';
import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../models/location_tree_node.dart';
import '../../services/location_repository.dart';
import '../batches/shelf_batches_view.dart';

class LocationsView extends StatefulWidget {
  const LocationsView({super.key});

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  bool _isLoading = true;
  String? _error;
  List<LocationTreeNode> _sectors = [];

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

    final repo = getIt<LocationRepository>();
    final res = await repo.getLocationsTree();

    if (!mounted) return;

    res.fold(
      (err) => setState(() => _error = err),
      (list) => setState(() => _sectors = list),
    );

    setState(() => _isLoading = false);
  }

  Future<void> _showLocationDialog({
    required String type,
    required String title,
    int? parentId,
    int? id,
    String? initialName,
    String? initialCode,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final codeController = TextEditingController(text: initialCode ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
    final result = id == null
        ? await repo.createLocation(
            name: nameController.text.trim(),
            type: type,
            parentId: parentId,
            code: codeController.text.trim(),
          )
        : await repo.updateLocation(
            id: id,
            name: nameController.text.trim(),
            type: type,
            parentId: parentId,
            code: codeController.text.trim(),
          );

    if (!mounted) return;

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  Future<void> _delete(LocationTreeNode node, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Usuń $label'),
        content: Text(
          node.children.isEmpty
              ? 'Usunąć "${node.name}"?'
              : 'Usunąć "${node.name}" razem z całą zawartością znajdującą się niżej?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = getIt<LocationRepository>();
    final result = await repo.deleteLocation(node.id);

    if (!mounted) return;

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (_) => _load(),
    );
  }

  Widget _buildShelfRow(LocationTreeNode shelf) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 8),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(shelf.name),
        subtitle: shelf.code != null && shelf.code!.isNotEmpty ? Text(shelf.code!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showLocationDialog(
                type: 'polka',
                title: 'Edytuj półkę',
                id: shelf.id,
                initialName: shelf.name,
                initialCode: shelf.code,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _delete(shelf, 'półkę'),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShelfBatchesView(
                shelf: LocationEntity(id: shelf.id, code: shelf.code, name: shelf.name, type: shelf.type),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRackTile(LocationTreeNode rack) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.view_column_outlined),
        title: Text(rack.name),
        subtitle: Text(
          '${rack.code != null && rack.code!.isNotEmpty ? '${rack.code} • ' : ''}${rack.children.length} półek',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Dodaj półkę',
              onPressed: () => _showLocationDialog(
                type: 'polka',
                title: 'Nowa półka',
                parentId: rack.id,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showLocationDialog(
                type: 'regal',
                title: 'Edytuj regał',
                parentId: rack.id,
                id: rack.id,
                initialName: rack.name,
                initialCode: rack.code,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _delete(rack, 'regał'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        children: rack.children.isEmpty
            ? [const Padding(padding: EdgeInsets.only(left: 32, bottom: 8), child: Text('Brak półek'))]
            : rack.children.map(_buildShelfRow).toList(),
      ),
    );
  }

  Widget _buildSectorTile(LocationTreeNode sector) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.warehouse_outlined),
        title: Text(sector.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${sector.code != null && sector.code!.isNotEmpty ? '${sector.code} • ' : ''}${sector.children.length} regałów',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Dodaj regał',
              onPressed: () => _showLocationDialog(
                type: 'regal',
                title: 'Nowy regał',
                parentId: sector.id,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showLocationDialog(
                type: 'sektor',
                title: 'Edytuj sektor',
                id: sector.id,
                initialName: sector.name,
                initialCode: sector.code,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _delete(sector, 'sektor'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        children: sector.children.isEmpty
            ? [const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('Brak regałów'))]
            : sector.children.map(_buildRackTile).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lokalizacje')),
      body: ResponsiveContainer(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _sectors.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('Brak sektorów. Dodaj pierwszy przyciskiem poniżej.')),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: _sectors.map(_buildSectorTile).toList(),
                        ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationDialog(type: 'sektor', title: 'Nowy sektor'),
        icon: const Icon(Icons.add),
        label: const Text('Sektor'),
      ),
    );
  }
}