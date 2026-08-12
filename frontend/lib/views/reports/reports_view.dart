import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../components/forms/form_cards.dart';
import '../../core/di/injection_container.dart';
import '../../services/report_repository.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _isExportingStock = false;
  bool _isExportingMovements = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _movementTypeFilter;

  Future<void> _exportStock() async {
    setState(() => _isExportingStock = true);

    final repo = getIt<ReportRepository>();
    final result = await repo.getStockCsv();

    if (!mounted) return;
    setState(() => _isExportingStock = false);

    await result.fold(
      (error) async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      },
      (bytes) async {
        await _saveAndShare(bytes, 'stan_magazynowy.csv');
      },
    );
  }

  Future<void> _exportMovements() async {
    setState(() => _isExportingMovements = true);

    final repo = getIt<ReportRepository>();
    final result = await repo.getMovementsCsv(
      from: _fromDate,
      to: _toDate,
      type: _movementTypeFilter,
    );

    if (!mounted) return;
    setState(() => _isExportingMovements = false);

    await result.fold(
      (error) async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      },
      (bytes) async {
        await _saveAndShare(bytes, 'historia_ruchow.csv');
      },
    );
  }

  Future<void> _saveAndShare(List<int> bytes, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Raport z systemu magazynowego',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać pliku: $e')),
      );
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nie wybrano';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporty')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FormHeaderCard(
            icon: Icons.insights_rounded,
            title: 'Raporty CSV',
            subtitle:
                'Wyeksportuj dane z magazynu do pliku CSV, który otworzysz w Excelu.',
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            title: 'Stan magazynowy',
            subtitle: 'Lista wszystkich aktualnych partii materiałów i odpadów.',
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExportingStock ? null : _exportStock,
                icon: _isExportingStock
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isExportingStock ? 'Eksportowanie...' : 'Eksportuj stan magazynowy',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FormSectionCard(
            title: 'Historia ruchów',
            subtitle:
                'Przyjęcia, wydania i zmiany statusów. Możesz zawęzić zakres dat.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromDate,
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text('Od: ${_formatDate(_fromDate)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickToDate,
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text('Do: ${_formatDate(_toDate)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: _movementTypeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Typ ruchu (opcjonalnie)',
                    prefixIcon: Icon(Icons.filter_alt_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Wszystkie')),
                    DropdownMenuItem(value: 'received', child: Text('Przyjęcia')),
                    DropdownMenuItem(value: 'issued', child: Text('Wydania')),
                    DropdownMenuItem(value: 'status_change', child: Text('Zmiany statusu')),
                  ],
                  onChanged: (value) => setState(() => _movementTypeFilter = value),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isExportingMovements ? null : _exportMovements,
                  icon: _isExportingMovements
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isExportingMovements ? 'Eksportowanie...' : 'Eksportuj historię ruchów',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}