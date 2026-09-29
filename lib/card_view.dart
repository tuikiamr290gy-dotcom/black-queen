import 'dart:math';

import 'package:flutter/material.dart';

import 'game_logic.dart';

String seatName(int seat) => seat == 0 ? 'You' : 'Bot $seat';

/// Position of a suit symbol on a number card.
class _Pip {
  final double dx;
  final double dy;
  final bool flipped;

  const _Pip(
    this.dx,
    this.dy, {
    this.flipped = false,
  });
}

/// Pip layouts for number cards.
const Map<int, List<_Pip>> _pipLayouts = {
  2: [
    _Pip(0.50, 0.22),
    _Pip(0.50, 0.78, flipped: true),
  ],
  3: [
    _Pip(0.50, 0.20),
    _Pip(0.50, 0.50),
    _Pip(0.50, 0.80, flipped: true),
  ],
  4: [
    _Pip(0.28, 0.22),
    _Pip(0.72, 0.22),
    _Pip(0.28, 0.78, flipped: true),
    _Pip(0.72, 0.78, flipped: true),
  ],
  5: [
    _Pip(0.28, 0.22),
    _Pip(0.72, 0.22),
    _Pip(0.50, 0.50),
    _Pip(0.28, 0.78, flipped: true),
    _Pip(0.72, 0.78, flipped: true),
  ],
  6: [
    _Pip(0.28, 0.20),
    _Pip(0.72, 0.20),
    _Pip(0.28, 0.50),
    _Pip(0.72, 0.50),
    _Pip(0.28, 0.80, flipped: true),
    _Pip(0.72, 0.80, flipped: true),
  ],
  7: [
    _Pip(0.28, 0.18),
    _Pip(0.72, 0.18),
    _Pip(0.50, 0.34),
    _Pip(0.28, 0.50),
    _Pip(0.72, 0.50),
    _Pip(0.28, 0.82, flipped: true),
    _Pip(0.72, 0.82, flipped: true),
  ],
  8: [
    _Pip(0.28, 0.16),
    _Pip(0.72, 0.16),
    _Pip(0.50, 0.32),
    _Pip(0.28, 0.50),
    _Pip(0.72, 0.50),
    _Pip(0.50, 0.68, flipped: true),
    _Pip(0.28, 0.84, flipped: true),
    _Pip(0.72, 0.84, flipped: true),
  ],
  9: [
    _Pip(0.28, 0.14),
    _Pip(0.72, 0.14),
    _Pip(0.28, 0.36),
    _Pip(0.72, 0.36),
    _Pip(0.50, 0.50),
    _Pip(0.28, 0.64, flipped: true),
    _Pip(0.72, 0.64, flipped: true),
    _Pip(0.28, 0.86, flipped: true),
    _Pip(0.72, 0.86, flipped: true),
  ],
  10: [
    _Pip(0.28, 0.12),
    _Pip(0.72, 0.12),
    _Pip(0.50, 0.24),
    _Pip(0.28, 0.38),
    _Pip(0.72, 0.38),
    _Pip(0.28, 0.62, flipped: true),
    _Pip(0.72, 0.62, flipped: true),
    _Pip(0.50, 0.76, flipped: true),
    _Pip(0.28, 0.88, flipped: true),
    _Pip(0.72, 0.88, flipped: true),
  ],
};

/// Simple symbols for face cards.
const Map<int, IconData> _faceIcons = {
  11: Icons.person,       // Jack
  12: Icons.diamond,      // Queen
  13: Icons.workspace_premium, // King
};

/// Playing card widget.
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
    final bool isRed =
        card.suit == Suit.hearts || card.suit == Suit.diamonds;

    final Color cardColor =
        isRed ? const Color(0xFFD32F2F) : const Color(0xFF111111);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1.0,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: card.isBlackQueen
                  ? const Color(0xFFFFB300)
                  : const Color(0xFF777777),
              width: card.isBlackQueen ? 3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top-left corner.
              Positioned(
                left: 4,
                top: 4,
                child: _corner(cardColor),
              ),

              // Bottom-right corner.
              Positioned(
                right: 4,
                bottom: 4,
                child: Transform.rotate(
                  angle: pi,
                  child: _corner(cardColor),
                ),
              ),

              // Center of card.
              Positioned.fill(
                child: _centerContent(cardColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rankLabel,
          style: TextStyle(
            color: color,
            fontSize: width * 0.24,
            fontWeight: FontWeight.bold,
            height: 0.9,
          ),
        ),
        Text(
          card.suitSymbol,
          style: TextStyle(
            color: color,
            fontSize: width * 0.18,
            height: 0.9,
          ),
        ),
      ],
    );
  }

  Widget _centerContent(Color color) {
    // Ace.
    if (card.rank == 14) {
      return Center(
        child: Text(
          card.suitSymbol,
          style: TextStyle(
            color: color,
            fontSize: width * 0.60,
            height: 1,
          ),
        ),
      );
    }

    // Jack, Queen, King.
    if (card.rank == 11 ||
        card.rank == 12 ||
        card.rank == 13) {
      return Center(
        child: Container(
          width: width * 0.62,
          height: height * 0.58,
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.35),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.rankLabel,
                style: TextStyle(
                  color: color,
                  fontSize: width * 0.38,
                  fontWeight: FontWeight.bold,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                card.suitSymbol,
                style: TextStyle(
                  color: color,
                  fontSize: width * 0.28,
                  height: 0.9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Number cards.
    final List<_Pip> pips = _pipLayouts[card.rank] ?? const [];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.10,
        vertical: height * 0.10,
      ),
      child: Stack(
        children: [
          for (final _Pip pip in pips)
            Align(
              alignment: Alignment(
                pip.dx * 2 - 1,
                pip.dy * 2 - 1,
              ),
              child: Transform.rotate(
                angle: pip.flipped ? pi : 0,
                child: Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.18,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Player badge.
class PlayerBadge extends StatelessWidget {
  final String name;
  final bool isBot;
  final bool active;

  const PlayerBadge({
    super.key,
    required this.name,
    required this.isBot,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              active ? Colors.amber : Colors.white24,
          child: Icon(
            isBot ? Icons.smart_toy : Icons.person,
            size: 16,
            color: active ? Colors.black : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Seat marker used for the three opponents.
class SeatMarker extends StatelessWidget {
  final String name;
  final bool isBot;
  final bool active;
  final int score;
  final PlayingCard? playedCard;

  const SeatMarker({
    super.key,
    required this.name,
    required this.isBot,
    required this.score,
    this.active = false,
    this.playedCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerBadge(
          name: name,
          isBot: isBot,
          active: active,
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 62,
          width: 44,
          child: playedCard != null
              ? CardView(
                  card: playedCard!,
                  width: 44,
                  height: 62,
                )
              : null,
        ),
      ],
    );
  }
}
