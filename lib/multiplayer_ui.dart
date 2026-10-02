import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'card_view.dart';
import 'game_logic.dart';
import 'main.dart' show GamePage;
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

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    seats = host.seats;
    host.lobbyUpdates.listen((s) => setState(() => seats = s));
    host.start().then((addr) => setState(() => address = addr));
  }

  void _startGame() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NetworkGamePage(
          mySeat: 0,
          link: host.selfLink(),
          initialNames: seats.map((s) => s.name).toList(),
          initialIsBot: seats.map((s) => s.isBot).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.green.shade900,
        appBar: AppBar(title: const Text('Host Game')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Turn on your phone\'s wifi hotspot, then share this address with the other players:',
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
                    leading: Icon(s.isBot ? Icons.smart_toy : Icons.person, color: Colors.white),
                    title: Text(s.name, style: const TextStyle(color: Colors.white)),
                    trailing: Text(s.isBot ? 'Bot' : 'Player', style: const TextStyle(color: Colors.amber)),
                  ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _startGame, child: const Text('Start Game')),
              ],
            ),
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
        final isBot = (event['isBot'] as List).map((e) => e as bool).toList();
        if (mySeat != null) {
          if (!kIsWeb) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => NetworkGamePage(
                mySeat: mySeat!,
                link: client!,
                initialNames: names,
                initialIsBot: isBot,
                initialEvents: List<Map<String, dynamic>>.from(client!.log),
              ),
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
  void dispose() {
    client?.dispose();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.green.shade900,
        appBar: AppBar(title: const Text('Join Game')),
        body: SafeArea(
          child: SingleChildScrollView(
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
                  decoration:
                      const InputDecoration(labelText: 'Your name', filled: true, fillColor: Colors.white10),
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
        ),
      );
}

class NetworkGamePage extends StatefulWidget {
  final int mySeat;
  final GameLink link;
  final List<String> initialNames;
  final List<bool> initialIsBot;
  final List<Map<String, dynamic>> initialEvents;

  const NetworkGamePage({
    super.key,
    required this.mySeat,
    required this.link,
    required this.initialNames,
    required this.initialIsBot,
    this.initialEvents = const [],
  });

  @override
  State<NetworkGamePage> createState() => _NetworkGamePageState();
}

class _NetworkGamePageState extends State<NetworkGamePage> {
  late List<String> names = widget.initialNames;
  late List<bool> isBot = widget.initialIsBot;
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

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    for (final event in widget.initialEvents) {
      _onEvent(event);
    }
    widget.link.events.listen(_onEvent);
  }

  String _displayName(int seat) => seat == widget.mySeat ? 'You' : names[seat];

  int _seatAt(int position) => (widget.mySeat + position) % 4;

  PlayingCard? _cardAt(int seat) {
    final match = table.where((e) => e.key == seat);
    return match.isEmpty ? null : match.first.value;
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
        final cards = (event['hand'] as List)
            .map((c) => cardFromMsg(c as Map<String, dynamic>))
            .toList();
        setState(() => myHand = cards);
        break;

      case 'deal_start':
        setState(() {
          dealNumber = event['dealNumber'] as int;
          currentSeat = event['currentSeat'] as int;
          names = (event['names'] as List).map((e) => e as String).toList();
          isBot = (event['isBot'] as List).map((e) => e as bool).toList();
          table = [];
          dealOver = false;
          message = '';
        });
        break;

      case 'played':
        final trick = event['trick'] as List;
        _removePlayedFromHand(trick);
        setState(() {
          table = trick
              .map((p) => MapEntry(p['seat'] as int,
                  cardFromMsg(p['card'] as Map<String, dynamic>)))
              .toList();
          currentSeat = event['currentSeat'] as int;
        });
        break;

      case 'trick_result':
        final trick = event['trick'] as List;
        _removePlayedFromHand(trick);
        setState(() {
          table = trick
              .map((p) => MapEntry(p['seat'] as int,
                  cardFromMsg(p['card'] as Map<String, dynamic>)))
              .toList();
          scores = (event['scores'] as List).map((e) => e as int).toList();
          currentSeat = event['currentSeat'] as int;
          dealOver = event['dealOver'] as bool;
          message = '${_displayName(event['winner'] as int)} won the round (+${event['points']} points)';
        });
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (!mounted) return;
          setState(() {
            table = [];
            message = dealOver ? 'Deal finished!' : '';
          });
        });
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

    final ledSuit = table.isEmpty ? null : table.first.value.suit;
    final legalCards = Rules.legalCards(myHand, ledSuit);
    if (!legalCards.contains(card)) {
      setState(() => message = 'You must follow the first suit.');
      return;
    }

    widget.link.play(card);
  }

  @override
  void dispose() {
    widget.link.dispose();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = currentSeat == widget.mySeat && !dealOver;
    final status = dealOver
        ? 'All cards are finished'
        : canPlay
            ? 'Your turn'
            : '${_displayName(currentSeat)} is playing...';

    Widget seatMarkerFor(int position) {
      final seat = _seatAt(position);
      return SeatMarker(
        name: _displayName(seat),
        isBot: isBot[seat],
        score: scores[seat],
        active: currentSeat == seat && !dealOver,
        playedCard: _cardAt(seat),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade900,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Color(0xFF1F6B2B), Color(0xFF0C3315)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Center(child: seatMarkerFor(2)),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(child: seatMarkerFor(1)),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(child: seatMarkerFor(3)),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_cardAt(widget.mySeat) != null) ...[
                              CardView(
                                card: _cardAt(widget.mySeat)!,
                                width: 50,
                                height: 70,
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You: ${scores[widget.mySeat]}  •  $status',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 92,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final card in myHand)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 0),
                                      child: Transform.translate(
                                        offset: const Offset(-7, 0),
                                        child: CardView(
                                          card: card,
                                          width: 58,
                                          height: 82,
                                          onTap: () => _onTapCard(card),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (dealOver && widget.mySeat == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 2),
                              child: FilledButton(
                                onPressed: widget.link.nextDeal,
                                child: const Text('Next deal'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
