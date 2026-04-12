import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection_container.dart';
import '../../../materials/domain/entities/material_entity.dart';
import '../../../materials/domain/repositories/material_repository.dart';
import '../../../materials/presentation/pages/material_details_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.code128, BarcodeFormat.code39, BarcodeFormat.qrCode],
  );

  final TextEditingController _manualCodeController = TextEditingController();

  bool _isTorchOn = false;
  bool _isSearching = false;
  bool _isHandlingScan = false;

  String? _lastScannedCode;
  String? _statusMessage;
  MaterialEntity? _matchedMaterial;

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skanowanie kodu'),
        actions: [
          IconButton(
            tooltip: 'Przełącz kamerę',
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
          IconButton(
            tooltip: _isTorchOn ? 'Wyłącz latarkę' : 'Włącz latarkę',
            onPressed: _toggleTorch,
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScannerCard(),
          const SizedBox(height: 12),
          _buildManualInputCard(),
          const SizedBox(height: 12),
          _buildResultCard(context),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const _ScannerOverlay(),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xCC000000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Ustaw kod seryjny w ramce i przytrzymaj stabilnie.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wpisz kod ręcznie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _manualCodeController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Np. BL-0001',
                prefixIcon: Icon(Icons.qr_code_2_rounded),
              ),
              onSubmitted: (value) => _searchByCode(value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSearching
                    ? null
                    : () => _searchByCode(_manualCodeController.text),
                icon: _isSearching
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(_isSearching ? 'Wyszukiwanie...' : 'Wyszukaj materiał'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final hasError = _statusMessage != null && _matchedMaterial == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? const Color(0xFFE6C4C4) : const Color(0xFFDCE8E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wynik skanowania',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (_lastScannedCode != null)
            Text('Ostatni kod: $_lastScannedCode'),
          if (_statusMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _statusMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasError ? const Color(0xFF8E1B1B) : const Color(0xFF245E3F),
                  ),
            ),
          ],
          if (_matchedMaterial != null) ...[
            const SizedBox(height: 10),
            _MatchedMaterialTile(
              material: _matchedMaterial!,
              onOpenDetails: () => _openMaterialDetails(_matchedMaterial!),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _switchCamera() async {
    await _controller.switchCamera();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) {
      return;
    }

    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) {
      return;
    }

    final value = capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) {
      return;
    }

    _isHandlingScan = true;
    await _searchByCode(value, fromScanner: true);
    _isHandlingScan = false;
  }

  Future<void> _searchByCode(String rawCode, {bool fromScanner = false}) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _statusMessage = 'Podaj kod do wyszukania.';
        _matchedMaterial = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _lastScannedCode = code;
      _statusMessage = null;
      _matchedMaterial = null;
    });

    final repository = getIt<MaterialRepository>();
    final result = await repository.getMaterials();

    if (!mounted) {
      return;
    }

    result.fold(
      (error) {
        setState(() {
          _statusMessage = 'Błąd pobierania: $error';
          _isSearching = false;
        });
      },
      (materials) {
        final match = materials.where((item) => item.serialNumber.toUpperCase() == code).cast<MaterialEntity?>().firstWhere(
              (item) => item != null,
              orElse: () => null,
            );

        setState(() {
          _matchedMaterial = match;
          _statusMessage = match == null
              ? 'Nie znaleziono materiału dla kodu $code.'
              : fromScanner
                  ? 'Znaleziono materiał dla zeskanowanego kodu.'
                  : 'Znaleziono materiał.';
          _isSearching = false;
        });
      },
    );
  }

  Future<void> _openMaterialDetails(MaterialEntity material) async {
    final hasChanges = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MaterialDetailsPage(material: material),
      ),
    );

    if (hasChanges == true && mounted && _lastScannedCode != null) {
      await _searchByCode(_lastScannedCode!);
    }
  }
}

class _MatchedMaterialTile extends StatelessWidget {
  final MaterialEntity material;
  final VoidCallback onOpenDetails;

  const _MatchedMaterialTile({
    required this.material,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onOpenDetails,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E7DC)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x1A00A54F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF006B38)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text('Kod: ${material.serialNumber}'),
                  Text('Lokalizacja: ${material.location ?? '-'}'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 230,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5EF3AA), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6600A54F),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
