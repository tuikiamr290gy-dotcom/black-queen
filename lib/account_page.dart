import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_storage.dart';


class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _nameController = TextEditingController();

  String _accountType = 'Guest';
  String _playerName = '';
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
      _playerName = name ?? '';
      _accountType = type;
      _nameController.text = _playerName;
      _loading = false;
    });
  }

  Future<void> _saveGuest() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a player name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await AccountStorage.saveGuestName(name);

    if (!mounted) return;

    setState(() {
      _playerName = name;
      _accountType = 'Guest';
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name is ready to play!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _changePlayer() {
    _nameController.text = _playerName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 14,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F5EE),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.style_rounded,
                  size: 34,
                  color: Color(0xFF376B3B),
                ),
                const SizedBox(height: 8),
                const Text(
                  'CHANGE PLAYER',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This name will be shown to other players.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 18,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Enter player name',
                    prefixIcon: const Icon(Icons.person_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _saveGuest();
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'SAVE PLAYER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _socialLogin(String provider) async {
  try {
    final auth = FirebaseAuth.instance;
    UserCredential result;

        final AuthProvider authProvider =
        provider == 'Google' ? GoogleAuthProvider() : FacebookAuthProvider();
    if (kIsWeb) {
      result = await auth.signInWithPopup(authProvider);
    } else {
      result = await auth.signInWithProvider(authProvider);
    }

    final user = result.user;

    if (!mounted || user == null) return;

    setState(() {
      _playerName = user.displayName ?? user.email ?? 'Player';
      _accountType = provider;
      _nameController.text = _playerName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider login successful!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider login failed: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  }

  Future<void> _signOut() async {
    await AccountStorage.clearAccount();

    if (!mounted) return;

    setState(() {
      _playerName = '';
      _accountType = 'Guest';
      _nameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been signed out.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlayer = _playerName.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ACCOUNT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        // Main profile card.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF111111),
                                Color(0xFF333333),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(.08),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 55,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    right: 1,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE6B84A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'PLAYER ACCOUNT',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                hasPlayer ? _playerName : 'No player yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6B84A),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  _accountType.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 49,
                                child: OutlinedButton.icon(
                                  onPressed: _changePlayer,
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'CHANGE PLAYER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white38,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PLAY AS GUEST',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1E5C7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Guest Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: _changePlayer,
                                child: Text(
                                  hasPlayer ? 'CHANGE' : 'CHOOSE',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'SIGN IN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black45,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 15),

                        _loginButton(
                          icon: Icons.g_mobiledata_rounded,
                          text: 'CONTINUE WITH GOOGLE',
                          onTap: () => _socialLogin('Google'),
                        ),
                        const SizedBox(height: 10),
                        _loginButton(
                          icon: Icons.facebook_rounded,
                          text: 'CONTINUE WITH FACEBOOK',
                          onTap: () => _socialLogin('Facebook'),
                        ),

                        const SizedBox(height: 20),

                        // Keep SIGN OUT as a real separate action.
                        TextButton.icon(
                          onPressed: hasPlayer ? _signOut : null,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'SIGN OUT',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Guest names are saved on this device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _loginButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}
