import 'dart:math';

import 'package:flutter/material.dart';

import 'game_logic.dart';

String seatName(int seat) => seat == 0 ? 'You' : 'Bot $seat';

/// Where one pip sits on a number card, as a fraction of the card's
/// width/height (0,0 = top-left corner, 1,1 = bottom-right corner).
/// "flipped" pips are drawn upside-down, like the bottom half of a real card.
class _Pip {
  final double dx;
  final double dy;
  final bool flipped;
  const _Pip(this.dx, this.dy, {this.flipped = false});
}

const Map<int, List<_Pip>> _pipLayouts = {
  2: [_Pip(0.5, 0.22), _Pip(0.5, 0.78, flipped: true)],
  3: [_Pip(0.5, 0.2), _Pip(0.5, 0.5), _Pip(0.5, 0.8, flipped: true)],
  4: [
    _Pip(0.28, 0.22), _Pip(0.72, 0.22),
    _Pip(0.28, 0.78, flipped: true), _Pip(0.72, 0.78, flipped: true),
  ],
  5: [
    _Pip(0.28, 0.22), _Pip(0.72, 0.22),
    _Pip(0.5, 0.5),
    _Pip(0.28, 0.78, flipped: true), _Pip(0.72, 0.78, flipped: true),
  ],
  6: [
    _Pip(0.28, 0.2), _Pip(0.72, 0.2),
    _Pip(0.28, 0.5), _Pip(0.72, 0.5),
    _Pip(0.28, 0.8, flipped: true), _Pip(0.72, 0.8, flipped: true),
  ],
  7: [
    _Pip(0.28, 0.18), _Pip(0.72, 0.18),
    _Pip(0.5, 0.34),
    _Pip(0.28, 0.5), _Pip(0.72, 0.5),
    _Pip(0.28, 0.82, flipped: true), _Pip(0.72, 0.82, flipped: true),
  ],
  8: [
    _Pip(0.28, 0.16), _Pip(0.72, 0.16),
    _Pip(0.5, 0.32),
    _Pip(0.28, 0.5), _Pip(0.72, 0.5),
    _Pip(0.5, 0.68, flipped: true),
    _Pip(0.28, 0.84, flipped: true), _Pip(0.72, 0.84, flipped: true),
  ],
  9: [
    _Pip(0.28, 0.14), _Pip(0.72, 0.14),
    _Pip(0.28, 0.36), _Pip(0.72, 0.36),
    _Pip(0.5, 0.5),
    _Pip(0.28, 0.64, flipped: true), _Pip(0.72, 0.64, flipped: true),
    _Pip(0.28, 0.86, flipped: true), _Pip(0.72, 0.86, flipped: true),
  ],
  10: [
    _Pip(0.28, 0.12), _Pip(0.72, 0.12),
    _Pip(0.5, 0.24),
    _Pip(0.28, 0.38), _Pip(0.72, 0.38),
    _Pip(0.28, 0.62, flipped: true), _Pip(0.72, 0.62, flipped: true),
    _Pip(0.5, 0.76, flipped: true),
    _Pip(0.28, 0.88, flipped: true), _Pip(0.72, 0.88, flipped: true),
  ],
};

/// A small icon standing in for an illustrated face, one per court card.
const Map<int, IconData> _faceIcons = {
  11: Icons.shield, // Jack
  12: Icons.local_florist, // Queen
  13: Icons.emoji_events, // King
};

/// One playing card, drawn to look like a real card: corner rank and suit,
/// a pip pattern for number cards, and a small icon for face cards.
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
    final red = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = red ? Colors.red.shade700 : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.35 : 1,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: card.isBlackQueen ? Colors.amber.shade700 : Colors.black26,
              width: card.isBlackQueen ? 2.5 : 1,
            ),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(1, 1))],
          ),
          child: Stack(
            children: [
              Positioned(left: 3, top: 2, child: _cornerText(color)),
              Positioned(
                right: 3,
                bottom: 2,
                child: Transform.rotate(angle: pi, child: _cornerText(color)),
              ),
              Center(child: _centerContent(color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cornerText(Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(card.rankLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, height: 1)),
          Text(card.suitSymbol, style: TextStyle(fontSize: 10, color: color, height: 1)),
        ],
      );

  Widget _centerContent(Color color) {
    if (card.rank == 14) {
      return Text(card.suitSymbol, style: TextStyle(fontSize: 22, color: color));
    }
    final icon = _faceIcons[card.rank];
    if (icon != null) {
      return Icon(icon, size: 20, color: color);
    }
    final pips = _pipLayouts[card.rank] ?? const [];
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (final pip in pips)
            Align(
              alignment: Alignment(pip.dx * 2 - 1, pip.dy * 2 - 1),
              child: Transform.rotate(
                angle: pip.flipped ? pi : 0,
                child: Text(card.suitSymbol, style: TextStyle(fontSize: 9, color: color)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small badge for a seat: a person icon for a human player, a robot
/// icon for a bot, highlighted when it is that seat's turn.
class PlayerBadge extends StatelessWidget {
  final String name;
  final bool isBot;
  final bool active;

  const PlayerBadge({super.key, required this.name, required this.isBot, this.active = false});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: active ? Colors.amber : Colors.white24,
            child: Icon(isBot ? Icons.smart_toy : Icons.person,
                size: 16, color: active ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}
