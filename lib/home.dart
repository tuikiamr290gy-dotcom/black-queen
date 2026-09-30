import 'main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'multiplayer_ui.dart';
import 'online_create_room.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final PageController _pageController =
      PageController(viewportFraction: 0.78);

  int _currentPage = 0;

  final List<_GameMode> _modes = const [
    _GameMode(
      title: 'Practice',
      subtitle: 'Play against Computer',
      icon: Icons.smart_toy_rounded,
      color1: Color(0xFF1C1C1C),
      color2: Color(0xFF4A4A4A),
    ),

    _GameMode(
      title: 'Wi-Fi Multiplayer',
      subtitle: 'Play with friends nearby',
      icon: Icons.wifi_rounded,
      color1: Color(0xFF173B5E),
      color2: Color(0xFF2E7699),
    ),

    _GameMode(
      title: 'Online Multiplayer',
      subtitle: 'Play with friends over the Internet',
      icon: Icons.public_rounded,
      color1: Color(0xFF145A32),
      color2: Color(0xFF27AE60),
    ),

    _GameMode(
      title: 'Scoreboard',
      subtitle: 'View your scores',
      icon: Icons.emoji_events_rounded,
      color1: Color(0xFF684B16),
      color2: Color(0xFFB4862C),
    ),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Title
            const Text(
              'BLACK QUEEN',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Choose your game mode',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 22),

            // Large swipe cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _modes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final mode = _modes[index];

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;

                      if (_pageController.position.haveDimensions) {
                        final page =
                            _pageController.page ??
                            _currentPage.toDouble();

                        final distance =
                            (page - index).abs();

                        scale = (1 - distance * 0.12)
                            .clamp(0.88, 1.0);
                      }

                      return Center(
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        _openMode(index);
                      },
                      child: _modeCard(mode),
                    ),
                  );
                },
              ),
            ),

            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _modes.length,
                (index) {
                  final selected =
                      index == _currentPage;

                  return AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    width: selected ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.black
                          : Colors.black26,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Bottom section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _selectedModeInfo(),
                  ),

                  const SizedBox(width: 14),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _openMode(_currentPage);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'PLAY',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(_GameMode mode) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mode.color1,
            mode.color2,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative card symbols
          const Positioned(
            top: 22,
            left: 22,
            child: Text(
              '♠',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 70,
              ),
            ),
          ),

          const Positioned(
            bottom: 22,
            right: 22,
            child: Text(
              '♥',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 70,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    mode.icon,
                    size: 58,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  mode.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  mode.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white24,
                    ),
                  ),
                  child: const Text(
                    'TAP TO SELECT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedModeInfo() {
    final mode = _modes[_currentPage];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          mode.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          mode.subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _openMode(int index) {
    switch (index) {
      case 0:
        // Practice
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GamePage(),
          ),
        );
        break;

      case 1:
        // Wi-Fi Multiplayer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MultiplayerMenuPage(),
          ),
        );
        break;

      case 2:
        // Online Multiplayer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const OnlineMenuPage(),
          ),
        );
        break;

      case 3:
        // Scoreboard
        _showComingSoon('Scoreboard');
        break;
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title selected'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _GameMode {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;

  const _GameMode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color1,
    required this.color2,
  });
}

class MultiplayerMenuPage extends StatelessWidget {
  const MultiplayerMenuPage({super.key});

  Widget _menuButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: 420,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white70,
          ),

          const SizedBox(width: 8),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(
        title: const Text('Wi-Fi Multiplayer'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'WI-FI MULTIPLAYER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _sectionTitle(
                  'Wi-Fi',
                  Icons.wifi,
                ),

                _menuButton(
                  context,
                  'Host Game',
                  'Create a game on your local Wi-Fi',
                  Icons.wifi_tethering,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const HostLobbyPage(),
                      ),
                    );
                  },
                ),

                _menuButton(
                  context,
                  'Join Game',
                  'Join a game using the host address',
                  Icons.login,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const JoinPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnlineMenuPage extends StatelessWidget {
  const OnlineMenuPage({super.key});

  Widget _button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: 420,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(
        title: const Text('Online Multiplayer'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.public,
                  color: Colors.white,
                  size: 60,
                ),

                const SizedBox(height: 10),

                const Text(
                  'ONLINE MULTIPLAYER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                _button(
                  context,
                  'Create Room',
                  'Create a room and invite friends',
                  Icons.add_circle_outline,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OnlineCreateRoomPage(),
                      ),
                    );
                  },
                ),

                _button(
                  context,
                  'Join Room',
                  'Enter a room code to join friends',
                  Icons.meeting_room_outlined,
                  () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Join Room will be added next.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
