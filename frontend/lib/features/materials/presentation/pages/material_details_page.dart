import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/material_repository.dart';
import 'edit_material_page.dart';

class MaterialDetailsPage extends StatefulWidget {
  final MaterialEntity material;

  const MaterialDetailsPage({
    super.key,
    required this.material,
  });

  @override
  State<MaterialDetailsPage> createState() => _MaterialDetailsPageState();
}

class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
  late MaterialEntity _material;
  bool _hasChanges = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _material = widget.material;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          title: const Text('Szczegóły materiału'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A54F), Color(0xFF006B38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _material.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${_material.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFE5FFF1),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openEditPage,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edytuj'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isDeleting ? null : _confirmDelete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_rounded),
                    label: Text(_isDeleting ? 'Usuwanie...' : 'Usuń'),
                    style: FilledButton.styleFrom(
                      foregroundColor: const Color(0xFF8E1B1B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailsCard(
              title: 'Numer seryjny',
              value: _material.serialNumber,
              icon: Icons.qr_code_rounded,
            ),
            _DetailsCard(
              title: 'Waga',
              value: _material.weight.toStringAsFixed(2),
              icon: Icons.scale_rounded,
            ),
            _DetailsCard(
              title: 'Długość',
              value: _material.length.toStringAsFixed(2),
              icon: Icons.straighten_rounded,
            ),
            _DetailsCard(
              title: 'Lokalizacja',
              value: _material.location ?? '-',
              icon: Icons.place_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditPage() async {
    final updatedMaterial = await Navigator.of(context).push<MaterialEntity>(
      MaterialPageRoute<MaterialEntity>(
        builder: (_) => EditMaterialPage(material: _material),
      ),
    );

    if (updatedMaterial != null && mounted) {
      setState(() {
        _material = updatedMaterial;
        _hasChanges = true;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Potwierdzenie usunięcia'),
              content: Text(
                'Czy na pewno chcesz usunąć materiał "${_material.name}"?',
              ),
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
            );
          },
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final repository = getIt<MaterialRepository>();
    final result = await repository.deleteMaterial(_material.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isDeleting = false;
    });

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materiał został usunięty.')),
        );
        Navigator.of(context).pop(true);
      },
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DetailsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x1A00A54F),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF006B38), size: 18),
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
