import 'package:flutter/material.dart';

import 'account_storage.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _nameController = TextEditingController();
  String _accountType = 'Guest';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await AccountStorage.loadName();
    final type = await AccountStorage.loadAccountType();
    if (!mounted) return;
    setState(() {
      _accountType = type;
      _nameController.text = name ?? '';
      _loading = false;
    });
  }

  Future<void> _saveGuest() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }
    await AccountStorage.saveGuestName(name);
    if (!mounted) return;
    setState(() => _accountType = 'Guest');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guest name saved.')),
    );
  }

  void _socialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider login requires Firebase Authentication setup for this project.',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _signOut() async {
    await AccountStorage.clearAccount();
    if (!mounted) return;
    setState(() {
      _accountType = 'Guest';
      _nameController.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      appBar: AppBar(
        title: const Text('Account',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const CircleAvatar(
                          radius: 42,
                          child: Icon(Icons.person, size: 46),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'PLAYER ACCOUNT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Account type: $_accountType',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Player name',
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _saveGuest,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('SAVE AS GUEST'),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 18),
                        const Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _socialLogin('Google'),
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('CONTINUE WITH GOOGLE'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _socialLogin('Facebook'),
                          icon: const Icon(Icons.facebook),
                          label: const Text('CONTINUE WITH FACEBOOK'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('SIGN OUT'),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Guest names are saved on this device. Google and Facebook sign-in require Firebase Authentication configuration.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
