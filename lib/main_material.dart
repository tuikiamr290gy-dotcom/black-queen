import 'package:flutter/material.dart';

import 'bot_player.dart';
import 'game_logic.dart';

void main() => runApp(const BlackQueenApp());

class BlackQueenApp extends StatelessWidget {
  const BlackQueenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Black Queen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: const GamePage(),
      );
}

String seatName(int seat) => seat == 0 ? 'You' : 'Bot $seat';

/// One card drawn on the screen.
class CardView extends StatelessWidget {
  final PlayingCard card;
  final bool dimmed;
  final VoidCallback? onTap;

  const CardView({super.key, required this.card, this.dimmed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final red = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.35 : 1,
        child: Container(
          width: 48,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: card.isBlackQueen ? Colors.amber : Colors.black26,
              width: card.isBlackQueen ? 3 : 1,
            ),
          ),
          child: Text(
            card.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: red ? Colors.red : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final BlackQueenGame game = BlackQueenGame();
  final BotPlayer bot = BotPlayer(level: BotLevel.hard);

  List<PlayedCard> table = []; // cards shown in the middle
  String message = '';
  bool busy = false; // true while bots are playing or a round is showing

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

  /// Bots play until it is your turn or the deal is over.
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
    // The round is finished: show the 4 cards and the winner for a moment.
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
              // Scoreboard (lowest points is best)
              Row(
                children: [
                  for (var i = 0; i < BlackQueenGame.seats; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: game.currentSeat == i && !game.dealOver
                              ? Colors.amber
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(seatName(i),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${game.scores[i]}',
                                style: const TextStyle(fontSize: 22)),
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
              // Cards on the table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var seat = 0; seat < BlackQueenGame.seats; seat++)
                    Column(
                      children: [
                        Text(seatName(seat),
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 68,
                          child: table.any((p) => p.seat == seat)
                              ? CardView(
                                  card: table.firstWhere((p) => p.seat == seat).card)
                              : const SizedBox(width: 48),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(status,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              // Your cards
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
                FilledButton(
                  onPressed: _startDeal,
                  child: const Text('Next deal'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
