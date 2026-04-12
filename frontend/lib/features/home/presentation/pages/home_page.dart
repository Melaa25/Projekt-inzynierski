import 'package:flutter/material.dart';

import '../../../materials/presentation/pages/materials_page.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel główny'),
      ),
      drawer: const _AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeaderPanel(),
          const SizedBox(height: 16),
          // Kafelki główne modułu magazynowego.
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            shrinkWrap: true,
            children: [
              _DashboardTile(
                title: 'Lista materiałów',
                subtitle: 'Podgląd aktualnych pozycji',
                icon: Icons.inventory_2_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MaterialsPage(),
                    ),
                  );
                },
              ),
              _DashboardTile(
                title: 'Skanowanie',
                subtitle: 'Skan kodów i szybkie wyszukiwanie',
                icon: Icons.qr_code_scanner_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScannerPage(),
                    ),
                  );
                },
              ),
              _DashboardTile(
                title: 'Przyjęcia',
                subtitle: 'Rejestr dostaw',
                icon: Icons.move_to_inbox_rounded,
                onTap: () => _showSoonSnackBar(context),
              ),
              _DashboardTile(
                title: 'Wydania',
                subtitle: 'Historia wyjść z magazynu',
                icon: Icons.local_shipping_rounded,
                onTap: () => _showSoonSnackBar(context),
              ),
              _DashboardTile(
                title: 'Raporty',
                subtitle: 'Analiza i zestawienia',
                icon: Icons.insights_rounded,
                onTap: () => _showSoonSnackBar(context),
              ),
              _DashboardTile(
                title: 'Kontrahenci',
                subtitle: 'Baza klientów i dostawców',
                icon: Icons.groups_rounded,
                onTap: () => _showSoonSnackBar(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ten moduł będzie dodany w kolejnym etapie.'),
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            'System magazynowy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Szybki dostęp do najważniejszych funkcji magazynu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE5FFF1),
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E9E4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1A00A54F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF006B38)),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF111111),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4D5751),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        // Rozwijana nawigacja podzielona na sekcje.
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF00A54F),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warehouse_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nawigacja',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Magazyn'),
              children: [
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: const Text('Lista materiałów'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MaterialsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.move_to_inbox_rounded),
                  title: const Text('Przyjęcia'),
                  onTap: () => _showSoonSnackBar(context),
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_rounded),
                  title: const Text('Wydania'),
                  onTap: () => _showSoonSnackBar(context),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.build_circle_outlined),
                  title: const Text('Narzędzia'),
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: const Text('Skanowanie'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ScannerPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: const Text('Raporty'),
                  onTap: () => _showSoonSnackBar(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSoonSnackBar(BuildContext context) {
    // Komunikat tymczasowy dla modułów, które będą dodane później.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ten moduł będzie dodany w kolejnym etapie.'),
      ),
    );
  }
}
