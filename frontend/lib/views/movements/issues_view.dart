import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/material_movement_entity.dart';
import '../../services/material_batch_repository.dart';
import '../scanner/scanner_view.dart';

class IssuesView extends StatefulWidget {
  const IssuesView({super.key});

  @override
  State<IssuesView> createState() => _IssuesViewState();
}

class _IssuesViewState extends State<IssuesView> {
  bool _isLoading = true;
  String? _error;
  List<MaterialMovementEntity> _items = [];

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

    final repository = getIt<MaterialBatchRepository>();
    final result = await repository.getMovements(type: 'issued');

    result.fold(
      (err) => setState(() {
        _error = err;
        _isLoading = false;
      }),
      (data) => setState(() {
        _items = data;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wydania'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Szybkie wydania',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zeskanuj etykietę na regale, aby wydać materiał z partii.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Otwórz skaner'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ScannerView(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historia wydań',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text('Błąd: ${_error ?? ''}'),
                  ] else if (_items.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Brak wydanych partii.'),
                  ] else ...[
                    const SizedBox(height: 8),
                    ..._items.map((m) => _buildMovementTile(m)).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(MaterialMovementEntity m) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      title: Text('${m.batch?.batchCode ?? '-'} (${m.quantityDelta} szt.)'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.userName != null) Text('Użytkownik: ${m.userName}'),
          if (m.destination != null && m.destination!.isNotEmpty) Text('Cel: ${m.destination}'),
          if (m.batch?.currentLocation != null) Text('Lokalizacja: ${m.batch!.currentLocation!.name}'),
          if (m.note != null && m.note!.isNotEmpty) Text('Uwagi: ${m.note}'),
          Text('Data: ${m.createdAt.toLocal()}'),
        ],
      ),
    );
  }
}