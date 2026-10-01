import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home.dart';
import 'bot_player.dart';
import 'card_view.dart';
import 'game_logic.dart';
import 'multiplayer_ui.dart';
import 'scoreboard_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  runApp(const BlackQueenApp());
}

class BlackQueenApp extends StatelessWidget {
  const BlackQueenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Black Queen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: const Home(),
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
  bool gameOver = false;

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
    
    if (game.dealOver) {
      unawaited(
        ScoreboardStorage.saveGame(
          mode: 'Practice',
          myName: 'You',
          myScore: game.scores[0],
          players: const [
            'You',
            'Bot 1',
            'Bot 2',
            'Bot 3',
          ],
          scores: game.scores,
        ),
      );

      setState(() {
        table = [];
        message = 'Deal finished!';
        gameOver = true;
      });
    } else {
      setState(() {
        table = [];
        message = '';
      });
    }
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

  /// Shows every card in the current trick together in the middle of the
  /// table. The cards are kept in seat order so their positions do not jump.
  Widget _centerTrick() {
    final cards = <Widget>[];
    for (var seat = 0; seat < BlackQueenGame.seats; seat++) {
      final card = _cardAt(seat);
      if (card == null) continue;
      cards.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: CardView(card: card, width: 52, height: 74),
      ));
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: cards,
    );
  }

  /// Score table shown in top left corner
  Widget _scoreTable() {
    final scores = game.scores;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SCORES',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _scoreRow('You', scores[0]),
          _scoreRow('Bot 1', scores[1]),
          _scoreRow('Bot 2', scores[2]),
          _scoreRow('Bot 3', scores[3]),
        ],
      ),
    );
  }

  Widget _scoreRow(String name, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the final scoreboard when the deal is over.
  Widget _scoreboardOverlay() {
    if (!gameOver) return const SizedBox.shrink();

    final scores = game.scores;
    final players = [
      (name: 'You', score: scores[0]),
      (name: 'Bot 1', score: scores[1]),
      (name: 'Bot 2', score: scores[2]),
      (name: 'Bot 3', score: scores[3]),
    ];

    // Sort by score (lowest first = best)
    players.sort((a, b) => a.score.compareTo(b.score));

    return Dialog(
      backgroundColor: Colors.green.shade900,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [Color(0xFF1F6B2B), Color(0xFF0C3315)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DEAL FINISHED',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(players.length, (index) {
              final player = players[index];
              final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '  ';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      medal,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${player.name}:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${player.score} points',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() {
                  gameOver = false;
                });
                _startDeal();
              },
              child: const Text('Next Deal'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a fanned hand of cards like a real card game with all cards visible
  Widget _buildCardHand() {
    final hand = game.hands[0];
    if (hand.isEmpty) return const SizedBox.shrink();

    final canPlay = !busy && game.currentSeat == 0 && !game.dealOver;
    final legal = canPlay ? game.legalMoves(0) : <PlayingCard>[];

    return SizedBox(
      height: 130,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Draw cards in a fanned pattern with proper spacing
              for (int i = 0; i < hand.length; i++)
                Positioned(
                  bottom: 0,
                  left: i * 50.0, // More space between cards so all 13 are visible
                  child: Transform.rotate(
                    angle: (i - hand.length / 2) * 0.06, // Subtle rotation
                    child: CardView(
                      card: hand[i],
                      width: 65, // Bigger card width
                      height: 92, // Bigger card height
                      dimmed: canPlay && !legal.contains(hand[i]),
                      onTap: () => _onTapCard(hand[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = !busy && game.currentSeat == 0 && !game.dealOver;

    final status = game.dealOver
        ? 'All cards are finished'
        : canPlay
            ? 'YOUR TURN'
            : '${seatName(game.currentSeat).toUpperCase()} IS PLAYING...';

    return Scaffold(
      backgroundColor: Colors.green.shade900,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [Color(0xFF1F6B2B), Color(0xFF0C3315)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
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
                            name: seatName(2).toUpperCase(),
                            isBot: true,
                            score: game.scores[2],
                            active: game.currentSeat == 2 && !game.dealOver,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: SeatMarker(
                            name: seatName(1).toUpperCase(),
                            isBot: true,
                            score: game.scores[1],
                            active: game.currentSeat == 1 && !game.dealOver,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: SeatMarker(
                            name: seatName(3).toUpperCase(),
                            isBot: true,
                            score: game.scores[3],
                            active: game.currentSeat == 3 && !game.dealOver,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 90),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _centerTrick(),
                              if (table.isNotEmpty) const SizedBox(height: 6),
                              Text(message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Score table in top left corner
            Positioned(
              top: 0,
              left: 0,
              child: _scoreTable(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('YOU: ${game.scores[0]} POINTS  •  $status',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCardHand(),
                  ),
                ],
              ),
            ),
            if (gameOver) _scoreboardOverlay(),
          ],
        ),
      ),
    );
  }
}
