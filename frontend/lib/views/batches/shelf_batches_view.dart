import 'package:flutter/material.dart';

import '../../components/batches/batch_card.dart';
import '../../components/common/responsive_container.dart';
import '../../core/di/injection_container.dart';
import '../../models/location_entity.dart';
import '../../models/material_batch_entity.dart';
import '../../services/material_batch_repository.dart';
import 'batch_details_view.dart';

class ShelfBatchesView extends StatefulWidget {
  final LocationEntity shelf;

  const ShelfBatchesView({super.key, required this.shelf});

  @override
  State<ShelfBatchesView> createState() => _ShelfBatchesViewState();
}

class _ShelfBatchesViewState extends State<ShelfBatchesView> {
  bool _isLoading = true;
  List<MaterialBatchEntity> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final repo = getIt<MaterialBatchRepository>();
    final res = await repo.getBatches(locationId: widget.shelf.id);

    res.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))),
      (list) => _batches = list,
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shelf.name)),
      body: ResponsiveContainer(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _batches.isEmpty
                ? const Center(child: Text('Ta półka jest pusta'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _batches.map((batch) {
                      return BatchCard(
                        batch: batch,
                        isSelectionMode: false,
                        isSelected: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BatchDetailsView(batchCode: batch.batchCode)),
                          ).then((_) => _load());
                        },
                        onLongPress: () {},
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}