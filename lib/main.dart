import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bot_player.dart';
import 'card_view.dart';
import 'game_logic.dart';
import 'multiplayer_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const BlackQueenApp());
}

class BlackQueenApp extends StatelessWidget {
  const BlackQueenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Black Queen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: const HomePage(),
      );
}

/// Practice mode: play against 3 bots on this one phone.
/// Table layout: Bot 2 across the top, Bot 1 on the left, Bot 3 on the
/// right, and you at the bottom.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final BlackQueenGame game = BlackQueenGame();
  final BotPlayer bot = BotPlayer(level: BotLevel.hard);

  List<PlayedCard> table = [];
  String message = '';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _startDeal();
  }

  Future<void> _startDeal() async {
    busy = true;
    setState(() {
      game.startDeal();
      table = [];
      message = '';
    });
    await _botsPlay();
    if (mounted) setState(() => busy = false);
  }

  Future<void> _botsPlay() async {
    while (mounted && !game.dealOver && game.currentSeat != 0) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final seat = game.currentSeat;
      await _play(seat, bot.chooseCard(game, seat));
    }
  }

  Future<void> _play(int seat, PlayingCard card) async {
    final error = game.playCard(seat, card);
    if (error != null) {
      setState(() => message = error);
      return;
    }
    if (game.trick.isNotEmpty) {
      setState(() {
        table = List.of(game.trick);
        message = '';
      });
      return;
    }
    setState(() {
      table = List.of(game.lastTrick);
      message = '${seatName(game.lastTrickWinner!)} won the round '
          '(+${game.lastTrickPoints} points)';
    });
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() {
      table = [];
      message = game.dealOver ? 'Deal finished!' : '';
    });
  }

  Future<void> _onTapCard(PlayingCard card) async {
    if (busy || game.currentSeat != 0 || game.dealOver) return;
    busy = true;
    await _play(0, card);
    await _botsPlay();
    if (mounted) setState(() => busy = false);
  }

  PlayingCard? _cardAt(int seat) {
    final match = table.where((p) => p.seat == seat);
    return match.isEmpty ? null : match.first.card;
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = !busy && game.currentSeat == 0 && !game.dealOver;
    final legal = canPlay ? game.legalMoves(0) : <PlayingCard>[];

    final status = game.dealOver
        ? 'All cards are finished'
        : canPlay
            ? 'Your turn'
            : '${seatName(game.currentSeat)} is playing...';

    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(title: Text('Black Queen  •  Deal ${game.dealNumber}'), toolbarHeight: 40),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Text('Lowest points wins  •  Black Queen = 12  •  Heart = 1',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SeatMarker(
                        name: seatName(2),
                        isBot: true,
                        score: game.scores[2],
                        active: game.currentSeat == 2 && !game.dealOver,
                        playedCard: _cardAt(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SeatMarker(
                        name: seatName(1),
                        isBot: true,
                        score: game.scores[1],
                        active: game.currentSeat == 1 && !game.dealOver,
                        playedCard: _cardAt(1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SeatMarker(
                        name: seatName(3),
                        isBot: true,
                        score: game.scores[3],
                        active: game.currentSeat == 3 && !game.dealOver,
                        playedCard: _cardAt(3),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 90),
                      child: Text(message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    left: 90,
                    right: 90,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('You: ${game.scores[0]}  •  $status',
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 78,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final card in game.hands[0])
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: CardView(
                                      card: card,
                                      dimmed: canPlay && !legal.contains(card),
                                      onTap: () => _onTapCard(card),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (game.dealOver && !busy)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: FilledButton(onPressed: _startDeal, child: const Text('Next deal')),
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
    );
  }
}
