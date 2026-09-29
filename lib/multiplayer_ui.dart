import 'package:flutter/material.dart';

import 'game_logic.dart';
import 'main.dart' show CardView, GamePage;
import 'network.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _button(BuildContext context, String label, Widget page) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FilledButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Text(label),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.green.shade900,
        appBar: AppBar(title: const Text('Black Queen')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Black Queen',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              _button(context, 'Practice vs Bots', const GamePage()),
              _button(context, 'Host Game (Wifi)', const HostLobbyPage()),
              _button(context, 'Join Game (Wifi)', const JoinPage()),
            ],
          ),
        ),
      );
}

class HostLobbyPage extends StatefulWidget {
  const HostLobbyPage({super.key});

  @override
  State<HostLobbyPage> createState() => _HostLobbyPageState();
}

class _HostLobbyPageState extends State<HostLobbyPage> {
  final HostServer host = HostServer();
  String? address;
  List<SeatInfo> seats = [];

  @override
  void initState() {
    super.initState();
    seats = host.seats;
    host.lobbyUpdates.listen((s) => setState(() => seats = s));
    host.start().then((addr) => setState(() => address = addr));
  }

  void _startGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NetworkGamePage(
          mySeat: 0,
          link: host.selfLink(),
          initialNames: seats.map((s) => s.name).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.green.shade900,
        appBar: AppBar(title: const Text('Host Game')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Turn on your phone\'s wifi hotspot, then share this address with the other players:',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  address == null ? 'Finding address...' : address!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Seats', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              for (final s in seats)
                ListTile(
                  tileColor: Colors.white10,
                  title: Text(s.name, style: const TextStyle(color: Colors.white)),
                  trailing: Text(s.isBot ? 'Bot' : 'Player', style: const TextStyle(color: Colors.amber)),
                ),
              const Spacer(),
              FilledButton(onPressed: _startGame, child: const Text('Start Game')),
            ],
          ),
        ),
      );
}

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _addressController = TextEditingController();
  final _nameController = TextEditingController(text: 'Player');
  GameClient? client;
  String status = '';
  int? mySeat;

  Future<void> _connect() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    setState(() => status = 'Connecting...');
    final c = GameClient();
    try {
      await c.connect(address, _nameController.text.trim());
    } catch (_) {
      setState(() => status = 'Could not connect. Check the address and try again.');
      return;
    }
    client = c;
    setState(() => status = 'Connected. Waiting for the host to start...');
    c.events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'welcome':
        mySeat = event['seat'] as int;
        break;
      case 'deal_start':
        final names = (event['names'] as List).map((e) => e as String).toList();
        if (mySeat != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => NetworkGamePage(mySeat: mySeat!, link: client!, initialNames: names),
            ),
          );
        }
        break;
      case 'error':
        setState(() => status = event['message'] as String? ?? 'Error');
        break;
      case 'disconnected':
        setState(() => status = 'Disconnected from host.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.green.shade900,
        appBar: AppBar(title: const Text('Join Game')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Connect to the same wifi hotspot as the host, then type their address below.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Your name', filled: true, fillColor: Colors.white10),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Host address (e.g. 192.168.43.1)', filled: true, fillColor: Colors.white10),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _connect, child: const Text('Connect')),
              const SizedBox(height: 16),
              Text(status, style: const TextStyle(color: Colors.amber)),
            ],
          ),
        ),
      );
}

/// The table screen used by every phone once a networked game has started.
class NetworkGamePage extends StatefulWidget {
  final int mySeat;
  final GameLink link;
  final List<String> initialNames;

  const NetworkGamePage({super.key, required this.mySeat, required this.link, required this.initialNames});

  @override
  State<NetworkGamePage> createState() => _NetworkGamePageState();
}

class _NetworkGamePageState extends State<NetworkGamePage> {
  late List<String> names = widget.initialNames;
  List<PlayingCard> myHand = [];
  List<MapEntry<int, PlayingCard>> table = [];
  List<int> scores = [0, 0, 0, 0];
  int currentSeat = 0;
  int dealNumber = 1;
  bool dealOver = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    widget.link.events.listen(_onEvent);
  }

  void _removePlayedFromHand(List trick) {
    for (final p in trick) {
      if (p['seat'] == widget.mySeat) {
        myHand.remove(cardFromMsg(p['card'] as Map<String, dynamic>));
      }
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'hand':
        {
          final cards = (event['hand'] as List).map((c) => cardFromMsg(c as Map<String, dynamic>)).toList();
          setState(() => myHand = cards);
        }
        break;
      case 'deal_start':
        setState(() {
          dealNumber = event['dealNumber'] as int;
          currentSeat = event['currentSeat'] as int;
          table = [];
          dealOver = false;
          message = '';
        });
        break;
      case 'played':
        {
          final trick = event['trick'] as List;
          _removePlayedFromHand(trick);
          setState(() {
            table = trick
                .map((p) => MapEntry(p['seat'] as int, cardFromMsg(p['card'] as Map<String, dynamic>)))
                .toList();
            currentSeat = event['currentSeat'] as int;
          });
        }
        break;
      case 'trick_result':
        {
          final trick = event['trick'] as List;
          _removePlayedFromHand(trick);
          setState(() {
            table = trick
                .map((p) => MapEntry(p['seat'] as int, cardFromMsg(p['card'] as Map<String, dynamic>)))
                .toList();
            scores = (event['scores'] as List).map((e) => e as int).toList();
            currentSeat = event['currentSeat'] as int;
            dealOver = event['dealOver'] as bool;
            message = '${names[event['winner'] as int]} won the round (+${event['points']} points)';
          });
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (!mounted) return;
            setState(() {
              table = [];
              message = dealOver ? 'Deal finished!' : '';
            });
          });
        }
        break;
      case 'error':
        setState(() => message = event['message'] as String? ?? '');
        break;
      case 'disconnected':
        setState(() => message = 'Disconnected from host.');
        break;
    }
  }

  void _onTapCard(PlayingCard card) {
    if (currentSeat != widget.mySeat || dealOver) return;
    widget.link.play(card);
  }

  @override
  void dispose() {
    widget.link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = currentSeat == widget.mySeat && !dealOver;
    final status =
        dealOver ? 'All cards are finished' : canPlay ? 'Your turn' : '${names[currentSeat]} is playing...';

    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(title: Text('Black Queen  •  Deal $dealNumber')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: currentSeat == i && !dealOver ? Colors.amber : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(names[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${scores[i]}', style: const TextStyle(fontSize: 22)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Lowest points wins  •  Black Queen = 12  •  Heart = 1',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var seat = 0; seat < 4; seat++)
                    Column(
                      children: [
                        Text(names[seat], style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 68,
                          child: table.any((e) => e.key == seat)
                              ? CardView(card: table.firstWhere((e) => e.key == seat).value)
                              : const SizedBox(width: 48),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(status, style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final card in myHand) CardView(card: card, onTap: () => _onTapCard(card)),
                ],
              ),
              const SizedBox(height: 12),
              if (dealOver && widget.mySeat == 0)
                FilledButton(onPressed: widget.link.nextDeal, child: const Text('Next deal')),
            ],
          ),
        ),
      ),
    );
  }
}
