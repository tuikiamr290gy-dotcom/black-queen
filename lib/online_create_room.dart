import 'dart:math';

import 'package:flutter/material.dart';

class OnlineCreateRoomPage extends StatefulWidget {
  const OnlineCreateRoomPage({super.key});

  @override
  State<OnlineCreateRoomPage> createState() =>
      _OnlineCreateRoomPageState();
}

class _OnlineCreateRoomPageState
    extends State<OnlineCreateRoomPage> {
  late String roomCode;

  final TextEditingController nameController =
      TextEditingController(text: 'Player');

  final List<String> players = [];

  @override
  void initState() {
    super.initState();
    roomCode = _generateRoomCode();
    players.add('Player');
  }

  String _generateRoomCode() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    return List.generate(
      6,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _updateName() {
    final name = nameController.text.trim();

    if (name.isEmpty) return;

    setState(() {
      players[0] = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(
        title: const Text('Create Online Room'),
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
                    size: 60,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'ONLINE ROOM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Create a room and invite your friends',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Room code
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ROOM CODE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          roomCode,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Share this code with your friends',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Player name
                  TextField(
                    controller: nameController,
                    onChanged: (_) => _updateName(),
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      labelStyle: const TextStyle(
                        color: Colors.white70,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Players
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Players ${players.length}/4',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...List.generate(
                    4,
                    (index) {
                      final occupied = index < players.length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              occupied
                                  ? Icons.person
                                  : Icons.person_outline,
                              color: occupied
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              occupied
                                  ? players[index]
                                  : 'Waiting for player...',
                              style: TextStyle(
                                color: occupied
                                    ? Colors.white
                                    : Colors.white38,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: players.length >= 2
                          ? () {
                              // Online game start will be connected
                              // after the backend is added.
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Waiting for online server connection.',
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        child: Text(
                          'START GAME',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}
