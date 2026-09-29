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

  @override
  Widget build(BuildContext context) {
    final canPlay = !busy && game.currentSeat == 0 && !game.dealOver;
    final legal = canPlay ? game.legalMoves(0) : <PlayingCard>[];

    String status;
    if (game.dealOver) {
      status = 'All cards are finished';
    } else if (canPlay) {
      status = 'Your turn';
    } else {
      status = '${seatName(game.currentSeat)} is playing...';
    }

    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(title: Text('Black Queen  •  Deal ${game.dealNumber}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < BlackQueenGame.seats; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            PlayerBadge(
                              name: seatName(i),
                              isBot: i != 0,
                              active: game.currentSeat == i && !game.dealOver,
                            ),
                            const SizedBox(height: 2),
                            Text('${game.scores[i]}',
                                style: const TextStyle(fontSize: 20, color: Colors.white)),
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
                  for (var seat = 0; seat < BlackQueenGame.seats; seat++)
                    Column(
                      children: [
                        PlayerBadge(
                          name: seatName(seat),
                          isBot: seat != 0,
                          active: game.currentSeat == seat && !game.dealOver,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 74,
                          child: table.any((p) => p.seat == seat)
                              ? CardView(card: table.firstWhere((p) => p.seat == seat).card)
                              : const SizedBox(width: 52),
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
                  for (final card in game.hands[0])
                    CardView(
                      card: card,
                      dimmed: canPlay && !legal.contains(card),
                      onTap: () => _onTapCard(card),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (game.dealOver && !busy)
                FilledButton(onPressed: _startDeal, child: const Text('Next deal')),
            ],
          ),
        ),
      ),
    );
  }
}
