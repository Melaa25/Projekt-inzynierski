import 'package:flutter/material.dart';

import '../../core/di/injection_container.dart';
import '../../models/managed_user.dart';
import '../../services/auth_service.dart';
import '../../services/user_repository.dart';

class UsersAdminView extends StatefulWidget {
  const UsersAdminView({super.key});

  @override
  State<UsersAdminView> createState() => _UsersAdminViewState();
}

class _UsersAdminViewState extends State<UsersAdminView> {
  bool _isLoading = true;
  List<ManagedUser> _users = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = getIt<UserRepository>();
    final result = await repo.getUsers();

    if (!mounted) {
      return;
    }

    result.fold(
      (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
      (users) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _openUserDialog({ManagedUser? user}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'pracownik';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            user == null ? 'Dodaj użytkownika' : 'Edytuj użytkownika',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Imię i nazwisko',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Podaj nazwę użytkownika';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Podaj email';
                      }
                      if (!text.contains('@')) {
                        return 'Podaj poprawny email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: user == null
                          ? 'Hasło'
                          : 'Hasło (zostaw puste, aby nie zmieniać)',
                    ),
                    validator: (value) {
                      if (user == null && (value ?? '').trim().isEmpty) {
                        return 'Podaj hasło';
                      }
                      if (user == null && (value ?? '').trim().length < 6) {
                        return 'Hasło musi mieć co najmniej 6 znaków';
                      }
                      if (user != null &&
                          (value ?? '').isNotEmpty &&
                          value!.trim().length < 6) {
                        return 'Hasło musi mieć co najmniej 6 znaków';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rola'),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrator'),
                      ),
                      DropdownMenuItem(
                        value: 'kierownik',
                        child: Text('Kierownik'),
                      ),
                      DropdownMenuItem(
                        value: 'pracownik',
                        child: Text('Pracownik'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedRole = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || !mounted) {
      return;
    }

    final repo = getIt<UserRepository>();
    final result = user == null
        ? await repo.createUser(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            role: selectedRole,
          )
        : await repo.updateUser(
            id: user.id,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim().isEmpty
                ? null
                : passwordController.text.trim(),
            role: selectedRole,
          );

    if (!mounted) {
      return;
    }

    result.fold(
      (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
      (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user == null
                  ? 'Użytkownik został dodany.'
                  : 'Użytkownik został zaktualizowany.',
            ),
          ),
        );
        await _loadUsers();
      },
    );
  }

  Future<void> _deleteUser(ManagedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń użytkownika'),
        content: Text('Na pewno usunąć ${user.name}?'),
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
      ),
    );

    if (confirmed != true) {
      return;
    }

    final repo = getIt<UserRepository>();
    final result = await repo.deleteUser(user.id);

    if (!mounted) {
      return;
    }

    result.fold(
      (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error))),
      (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Użytkownik został usunięty.')),
        );
        await _loadUsers();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    final currentUser = authService.currentUser;

    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel administratora')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Ten panel jest dostępny tylko dla administratora.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel administratora'),
        actions: [
          IconButton(
            tooltip: 'Dodaj użytkownika',
            onPressed: () => _openUserDialog(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF006B38),
                ),
                title: Text(currentUser?.name ?? 'Administrator'),
                subtitle: Text(currentUser?.roleLabel ?? 'Administrator'),
                trailing: const Icon(Icons.verified_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text('Nie udało się pobrać użytkowników'),
                  subtitle: Text(_error!),
                  trailing: IconButton(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              )
            else if (_users.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Brak użytkowników do wyświetlenia.'),
                ),
              )
            else
              ..._users.map(
                (user) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF006B38),
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.email}\n${user.roleLabel}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _openUserDialog(user: user),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          onPressed: () => _deleteUser(user),
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUserDialog(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Dodaj użytkownika'),
      ),
    );
  }
}
