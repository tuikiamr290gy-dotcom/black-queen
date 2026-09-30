import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineMatchPage extends StatefulWidget {
  const OnlineMatchPage({super.key});

  @override
  State<OnlineMatchPage> createState() => _OnlineMatchPageState();
}

class _OnlineMatchPageState extends State<OnlineMatchPage> {
  static const String serverUrl =
      'wss://black-queen-server.onrender.com';

  final TextEditingController _nameController =
      TextEditingController();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  String _status = 'Enter your name';
  int _playersWaiting = 0;
  bool _searching = false;
  bool _connected = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _nameController.dispose();
    super.dispose();
  }

  void _findMatch() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _status = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _searching = true;
      _status = 'Connecting to server...';
      _playersWaiting = 0;
    });

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(serverUrl),
      );

      _channel = channel;

      _subscription = channel.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _searching = false;
            _connected = false;
            _status = 'Connection error';
          });
        },
        onDone: () {
          if (!mounted) return;

          if (_searching) {
            setState(() {
              _searching = false;
              _connected = false;
              _status = 'Disconnected from server';
            });
          }
        },
      );

      _connected = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || _channel == null) return;

        _send({
          'type': 'find_match',
          'name': name,
        });
      });
    } catch (e) {
      setState(() {
        _searching = false;
        _status = 'Could not connect to server';
      });
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());

      switch (data['type']) {
        case 'connected':
          if (!mounted) return;

          setState(() {
            _connected = true;
          });
          break;

        case 'searching':
          if (!mounted) return;

          setState(() {
            _searching = true;
            _playersWaiting =
                (data['playersWaiting'] ?? 1) as int;
            _status = 'Searching for players...';
          });
          break;

        case 'match_found':
          if (!mounted) return;

          setState(() {
            _searching = false;
            _status = 'Match found!';
            _playersWaiting = 4;
          });

          _showMatchFound(data);
          break;
          case 'game_over':
  if (!mounted) return;

  setState(() {
    _searching = false;
    _status = 'Game Over';
  });

  _showGameOver(data);
  break;

        case 'search_cancelled':
          if (!mounted) return;

          setState(() {
            _searching = false;
            _status = 'Search cancelled';
            _playersWaiting = 0;
          });
          break;
      }
    } catch (_) {
      // Ignore invalid server messages.
    }
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void _cancelSearch() {
    _send({
      'type': 'cancel_search',
    });

    _channel?.sink.close();

    setState(() {
      _searching = false;
      _connected = false;
      _playersWaiting = 0;
      _status = 'Search cancelled';
    });
  }

  void _showMatchFound(Map<String, dynamic> data) {
    final players = data['players'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Text('Match Found!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '4 players have been matched.',
              ),
              const SizedBox(height: 16),
              for (final player in players)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.person),
                  title: Text(
                    player['name']?.toString() ??
                        'Player',
                  ),
                  subtitle: Text(
                    'Seat ${(player['seat'] ?? 0) + 1}',
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
void _showGameOver(Map<String, dynamic> data) {
  final scores = (data['scores'] as List?)
          ?.map((e) => e as int)
          .toList() ??
      [0, 0, 0, 0];

  final winnerName =
      data['winnerName']?.toString() ?? 'Player';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber,
            ),
            SizedBox(width: 10),
            Text('GAME OVER'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Winner: $winnerName',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < scores.length; i++)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person),
                title: Text(
                  'Player ${i + 1}',
                ),
                trailing: Text(
                  '${scores[i]} points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'The player with the lowest score wins.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('BACK TO HOME'),
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(
        title: const Text('Find Match'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.public,
                    size: 80,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'FIND MATCH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: _nameController,
                    enabled: !_searching,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Your Name',
                      hintText: 'Enter your name',
                      prefixIcon:
                          const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (_searching) ...[
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Players found: $_playersWaiting / 4',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _cancelSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        child: const Text(
                          'CANCEL SEARCH',
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _findMatch,
                        icon: const Icon(
                          Icons.search,
                        ),
                        label: const Text(
                          'FIND MATCH',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        _connected
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: _connected
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connected
                            ? 'Server connected'
                            : 'Server not connected',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
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
