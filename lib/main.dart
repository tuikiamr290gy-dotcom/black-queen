import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bot_player.dart';
import 'game_logic.dart';
import 'multiplayer_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape / horizontal mode.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const BlackQueenApp());
}

class BlackQueenApp extends StatelessWidget {
  const BlackQueenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Black Queen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071A12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD9A441),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

String seatName(int seat) {
  return seat == 0 ? 'You' : 'Bot $seat';
}

// ============================================================
// CARD UI
// ============================================================

class CardView extends StatelessWidget {
  final PlayingCard card;
  final bool dimmed;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardView({
    super.key,
    required this.card,
    this.dimmed = false,
    this.onTap,
    this.width = 52,
    this.height = 74,
  });

  @override
  Widget build(BuildContext context) {
    final isRed =
        card.suit == Suit.hearts || card.suit == Suit.diamonds;

    final isQueen = card.isBlackQueen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: dimmed ? 0.30 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF5),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isQueen
                  ? const Color(0xFFE3B341)
                  : Colors.white.withOpacity(.65),
              width: isQueen ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: isQueen ? 9 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 5,
                top: 3,
                child: Column(
                  children: [
                    Text(
                      card.rankLabel,
                      style: TextStyle(
                        color: isRed
                            ? const Color(0xFFB51F2D)
                            : const Color(0xFF101313),
                        fontSize: width < 50 ? 13 : 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      card.suitSymbol,
                      style: TextStyle(
                        color: isRed
                            ? const Color(0xFFB51F2D)
                            : const Color(0xFF101313),
                        fontSize: width < 50 ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: isRed
                        ? const Color(0xFFB51F2D)
                        : const Color(0xFF101313),
                    fontSize: width < 50 ? 22 : 28,
                  ),
                ),
              ),

              if (isQueen)
                Positioned(
                  right: 5,
                  bottom: 3,
                  child: Text(
                    '12',
                    style: TextStyle(
                      color: const Color(0xFF9A711B),
                      fontSize: width < 50 ? 9 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PLAYER BADGE
// ============================================================

class _PlayerBadge extends StatelessWidget {
  final String name;
  final int score;
  final bool active;
  final bool you;

  const _PlayerBadge({
    required this.name,
    required this.score,
    required this.active,
    this.you = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFD9A441)
            : const Color(0xFF10291E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? const Color(0xFFFFE29A)
              : Colors.white.withOpacity(.09),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFD9A441)
                      .withOpacity(.25),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            you
                ? Icons.person_rounded
                : Icons.person_outline_rounded,
            size: 17,
            color: active
                ? const Color(0xFF20180B)
                : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: active
                  ? const Color(0xFF20180B)
                  : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '$score',
            style: TextStyle(
              color: active
                  ? const Color(0xFF20180B)
                  : const Color(0xFFE8C56D),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GAME PAGE
// ============================================================

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final BlackQueenGame game = BlackQueenGame();

  final BotPlayer bot = BotPlayer(
    level: BotLevel.hard,
  );

  List<PlayedCard> table = [];

  String message = '';

  bool busy = false;

  @override
  void initState() {
    super.initState();
    _startDeal();
  }

  // ----------------------------------------------------------
  // START DEAL
  // ----------------------------------------------------------

  Future<void> _startDeal() async {
    busy = true;

    setState(() {
      game.startDeal();
      table = [];
      message = '';
    });

    await _botsPlay();

    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  // ----------------------------------------------------------
  // BOT PLAY
  // ----------------------------------------------------------

  Future<void> _botsPlay() async {
    while (
        mounted &&
        !game.dealOver &&
        game.currentSeat != 0) {
      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      final seat = game.currentSeat;

      await _play(
        seat,
        bot.chooseCard(game, seat),
      );
    }
  }

  // ----------------------------------------------------------
  // PLAY CARD
  // ----------------------------------------------------------

  Future<void> _play(
    int seat,
    PlayingCard card,
  ) async {
    final error = game.playCard(
      seat,
      card,
    );

    if (error != null) {
      setState(() {
        message = error;
      });

      return;
    }

    // Trick is still being played.
    if (game.trick.isNotEmpty) {
      setState(() {
        table = List.of(game.trick);
        message = '';
      });

      return;
    }

    // Trick finished.
    setState(() {
      table = List.of(game.lastTrick);

      message =
          '${seatName(game.lastTrickWinner!)} won the round'
          '  •  +${game.lastTrickPoints}';
    });

    await Future.delayed(
      const Duration(milliseconds: 1300),
    );

    if (!mounted) return;

    setState(() {
      table = [];

      message = game.dealOver
          ? 'Deal finished!'
          : '';
    });
  }

  // ----------------------------------------------------------
  // USER CARD TAP
  // ----------------------------------------------------------

  Future<void> _onTapCard(
    PlayingCard card,
  ) async {
    if (busy ||
        game.currentSeat != 0 ||
        game.dealOver) {
      return;
    }

    busy = true;

    await _play(
      0,
      card,
    );

    await _botsPlay();

    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  // ----------------------------------------------------------
  // GET PLAYED CARD
  // ----------------------------------------------------------

  Widget _playedCard(
    int seat,
    double width,
    double height,
  ) {
    final played = table
        .where((p) => p.seat == seat)
        .toList();

    if (played.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
      );
    }

    return CardView(
      card: played.first.card,
      width: width,
      height: height,
    );
  }

  // ==========================================================
  // MAIN GAME UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final canPlay =
        !busy &&
        game.currentSeat == 0 &&
        !game.dealOver;

    final legal = canPlay
        ? game.legalMoves(0)
        : <PlayingCard>[];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final cardWidth =
                (constraints.maxWidth / 17)
                    .clamp(43.0, 62.0);

            final cardHeight =
                cardWidth * 1.42;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF092319),
                    Color(0xFF0D3826),
                    Color(0xFF06160F),
                  ],
                ),
              ),

              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter:
                          _TablePatternPainter(),
                    ),
                  ),

                  Column(
                    children: [

                      // ==================================================
                      // TOP BAR
                      // ==================================================

                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          14,
                          8,
                          14,
                          2,
                        ),
                        child: Row(
                          children: [

                            const Icon(
                              Icons.auto_awesome,
                              color:
                                  Color(0xFFE4C36B),
                              size: 20,
                            ),

                            const SizedBox(width: 7),

                            const Text(
                              'BLACK QUEEN',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              'DEAL ${game.dealNumber}',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white54,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // TABLE
                      // ==================================================

                      Expanded(
                        child: Stack(
                          alignment:
                              Alignment.center,
                          children: [

                            // TOP PLAYER
                            Positioned(
                              top: 5,
                              child: _PlayerBadge(
                                name: seatName(1),
                                score:
                                    game.scores[1],
                                active:
                                    game.currentSeat ==
                                            1 &&
                                        !game.dealOver,
                              ),
                            ),

                            // LEFT PLAYER
                            Positioned(
                              left: 10,
                              top: 0,
                              bottom: 5,
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child:
                                      _PlayerBadge(
                                    name:
                                        seatName(2),
                                    score:
                                        game.scores[2],
                                    active:
                                        game.currentSeat ==
                                                2 &&
                                            !game.dealOver,
                                  ),
                                ),
                              ),
                            ),

                            // RIGHT PLAYER
                            Positioned(
                              right: 10,
                              top: 0,
                              bottom: 5,
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child:
                                      _PlayerBadge(
                                    name:
                                        seatName(3),
                                    score:
                                        game.scores[3],
                                    active:
                                        game.currentSeat ==
                                                3 &&
                                            !game.dealOver,
                                  ),
                                ),
                              ),
                            ),

                            // ==================================================
                            // CENTER TABLE
                            // ==================================================

                            Container(
                              width:
                                  constraints.maxWidth *
                                      .46,
                              height:
                                  constraints.maxHeight *
                                      .53,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF0B2A1D,
                                ).withOpacity(.8),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  30,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xFFD9A441,
                                  ).withOpacity(.18),
                                  width: 1.5,
                                ),
                              ),
                            ),

                            Center(
                              child: SizedBox(
                                width:
                                    constraints
                                            .maxWidth *
                                        .43,
                                height:
                                    constraints
                                            .maxHeight *
                                        .47,
                                child: Stack(
                                  alignment:
                                      Alignment
                                          .center,
                                  children: [

                                    // BOT 1
                                    Positioned(
                                      top: 2,
                                      child:
                                          _playedCard(
                                        1,
                                        cardWidth *
                                            .92,
                                        cardHeight *
                                            .92,
                                      ),
                                    ),

                                    // BOT 2
                                    Positioned(
                                      left: 6,
                                      child:
                                          _playedCard(
                                        2,
                                        cardWidth *
                                            .92,
                                        cardHeight *
                                            .92,
                                      ),
                                    ),

                                    // BOT 3
                                    Positioned(
                                      right: 6,
                                      child:
                                          _playedCard(
                                        3,
                                        cardWidth *
                                            .92,
                                        cardHeight *
                                            .92,
                                      ),
                                    ),

                                    // PLAYER
                                    Positioned(
                                      bottom: 2,
                                      child:
                                          _playedCard(
                                        0,
                                        cardWidth *
                                            .92,
                                        cardHeight *
                                            .92,
                                      ),
                                    ),

                                    if (table.isEmpty &&
                                        !game.dealOver)
                                      const Column(
                                        mainAxisSize:
                                            MainAxisSize
                                                .min,
                                        children: [
                                          Icon(
                                            Icons
                                                .style_rounded,
                                            size: 32,
                                            color:
                                                Colors
                                                    .white12,
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            'PLAY AREA',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors
                                                      .white24,
                                              letterSpacing:
                                                  2,
                                              fontSize:
                                                  11,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // ==================================================
                            // SCORE RULE
                            // ==================================================

                            Positioned(
                              top: 9,
                              right: 14,
                              child:
                                  _ScoreStrip(
                                game: game,
                              ),
                            ),

                            // ==================================================
                            // PLAYER HAND
                            // ==================================================

                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [

                                  _StatusPill(
                                    text:
                                        message
                                                .isNotEmpty
                                            ? message
                                            : game.dealOver
                                                ? 'Deal finished'
                                                : canPlay
                                                    ? 'YOUR TURN • Choose a card'
                                                    : '${seatName(game.currentSeat)} is playing',
                                    highlight:
                                        message
                                                .isNotEmpty ||
                                            canPlay,
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  _PlayerBadge(
                                    name: 'You',
                                    score:
                                        game.scores[0],
                                    active:
                                        canPlay &&
                                            !game.dealOver,
                                    you: true,
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  SizedBox(
                                    height:
                                        cardHeight + 8,
                                    child:
                                        ListView.builder(
                                      scrollDirection:
                                          Axis.horizontal,
                                      shrinkWrap: true,
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 10,
                                      ),
                                      itemCount:
                                          game.hands[0]
                                              .length,
                                      itemBuilder:
                                          (
                                        context,
                                        index,
                                      ) {
                                        final card =
                                            game.hands[
                                                    0]
                                                [index];

                                        return CardView(
                                          card: card,
                                          width:
                                              cardWidth,
                                          height:
                                              cardHeight,
                                          dimmed: canPlay &&
                                              !legal.contains(
                                                card,
                                              ),
                                          onTap: () =>
                                              _onTapCard(
                                            card,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // ==================================================
                                  // NEXT DEAL
                                  // ==================================================

                                  if (game.dealOver &&
                                      !busy)
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(
                                        bottom: 3,
                                      ),
                                      child:
                                          FilledButton.icon(
                                        onPressed:
                                            _startDeal,
                                        icon: const Icon(
                                          Icons
                                              .refresh_rounded,
                                        ),
                                        label:
                                            const Text(
                                          'NEXT DEAL',
                                        ),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// SCORE STRIP
// ============================================================

class _ScoreStrip extends StatelessWidget {
  final BlackQueenGame game;

  const _ScoreStrip({
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.2),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Text(
        'LOWEST SCORE WINS  •  ♠Q = 12  •  ♥ = 1',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// STATUS MESSAGE
// ============================================================

class _StatusPill extends StatelessWidget {
  final String text;
  final bool highlight;

  const _StatusPill({
    required this.text,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 200),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFD9A441)
                .withOpacity(.15)
            : Colors.black.withOpacity(.18),
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color: highlight
              ? const Color(0xFFD9A441)
                  .withOpacity(.5)
              : Colors.white12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight
              ? const Color(0xFFF4D88A)
              : Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// TABLE BACKGROUND
// ============================================================

class _TablePatternPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color =
          Colors.white.withOpacity(.012);

    for (
      double x = -size.height;
      x < size.width;
      x += 38
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(
          x + size.height,
          size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
