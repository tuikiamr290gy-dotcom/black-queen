import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      title: 'Multiplayer',
      subtitle: 'Play with friends',
      icon: Icons.people_alt_rounded,
      color1: Color(0xFF173B5E),
      color2: Color(0xFF2E7699),
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
                    color: Colors.white.withOpacity(0.12),
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
        // Practice vs Computer
        //
        // Connect this to your existing
        // Black Queen practice/game screen.
        _showComingSoon('Practice vs Computer');
        break;

      case 1:
        // Multiplayer
        //
        // Connect this to your existing
        // Host / Join multiplayer screen.
        _showComingSoon('Multiplayer');
        break;

      case 2:
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
