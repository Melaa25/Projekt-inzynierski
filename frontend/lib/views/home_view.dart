import 'package:flutter/material.dart';

import '../core/di/injection_container.dart';
import '../services/auth_service.dart';
import 'auth/login_view.dart';
import 'admin/users_admin_view.dart';
import 'materials/materials_view.dart';
import 'locations/locations_view.dart';
import 'scanner/scanner_view.dart';
import 'movements/receipts_view.dart';
import 'movements/issues_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();

    return AnimatedBuilder(
      animation: authService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Panel główny')),
          drawer: const _AppDrawer(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _HeaderPanel(),
              const SizedBox(height: 16),
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
                          builder: (_) => const MaterialsView(),
                        ),
                      );
                    },
                  ),
                  _DashboardTile(
                    title: 'Lokalizacje',
                    subtitle: 'Strefy, sektory i miejsca',
                    icon: Icons.place_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LocationsView(),
                        ),
                      );
                    },
                  ),
                  if (authService.isAdmin)
                    _DashboardTile(
                      title: 'Panel administratora',
                      subtitle: 'Użytkownicy i role',
                      icon: Icons.admin_panel_settings_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const UsersAdminView(),
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
                          builder: (_) => const ScannerView(),
                        ),
                      );
                    },
                  ),
                  _DashboardTile(
                    title: 'Przyjęcia',
                    subtitle: 'Rejestr dostaw',
                    icon: Icons.move_to_inbox_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReceiptsView(),
                        ),
                      );
                    },
                  ),
                  _DashboardTile(
                    title: 'Wydania',
                    subtitle: 'Historia wyjść z magazynu',
                    icon: Icons.local_shipping_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const IssuesView(),
                        ),
                      );
                    },
                  ),
                  _DashboardTile(
                    title: 'Raporty',
                    subtitle: 'Analiza i zestawienia',
                    icon: Icons.insights_rounded,
                    onTap: () => _showSoonSnackBar(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFE5FFF1)),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF4D5751)),
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
    final authService = getIt<AuthService>();

    return AnimatedBuilder(
      animation: authService,
      builder: (context, _) {
        final currentUser = authService.currentUser;

        return Drawer(
          child: SafeArea(
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
                      const SizedBox(height: 6),
                      Text(
                        currentUser == null
                            ? 'Niezalogowany'
                            : '${currentUser.name} (${currentUser.roleLabel})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFE5FFF1),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: const Text('Lista materiałów'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MaterialsView(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.place_rounded),
                  title: const Text('Lokalizacje'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LocationsView(),
                      ),
                    );
                  },
                ),
                if (authService.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: const Text('Panel administratora'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const UsersAdminView(),
                        ),
                      );
                    },
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
                            builder: (_) => const ScannerView(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.move_to_inbox_rounded),
                      title: const Text('Przyjęcia'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReceiptsView(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_shipping_rounded),
                      title: const Text('Wydania'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const IssuesView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Wyloguj'),
                  onTap: () async {
                    await authService.logout();
                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginView(),
                      ),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSoonSnackBar(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ten moduł będzie dodany w kolejnym etapie.'),
      ),
    );
  }
}
