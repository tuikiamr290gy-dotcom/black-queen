```dart
import 'dart:math';

import 'package:flutter/material.dart';

import 'game_logic.dart';

String seatName(int seat) => seat == 0 ? 'You' : 'Bot $seat';

/// Displays a card using the PNG artwork from the Call Break project.
///
/// PNG naming:
///   2C.png  = 2 of Clubs
///   10H.png = 10 of Hearts
///   11S.png = Jack of Spades
///   12S.png = Queen of Spades
///   13S.png = King of Spades
///   14S.png = Ace of Spades
///
/// Put all 52 PNG files inside:
///   assets/cards/
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

  /// Converts the Black Queen suit into the Call Break PNG code.
  String get _suitCode {
    switch (card.suit) {
      case Suit.clubs:
        return 'C';
      case Suit.diamonds:
        return 'D';
      case Suit.hearts:
        return 'H';
      case Suit.spades:
        return 'S';
    }
  }

  /// Example:
  /// rank 14 + spades = 14S.png
  String get _assetPath {
    return 'assets/cards/${card.rank}$_suitCode.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: dimmed ? 0.35 : 1.0,
        child: SizedBox(
          width: width,
          height: height,
          child: Image.asset(
            _assetPath,
            width: width,
            height: height,
            fit: BoxFit.fill,

            // If an image is missing, show a useful fallback
            // instead of crashing the card table.
            errorBuilder: (context, error, stackTrace) {
              return _fallbackCard();
            },
          ),
        ),
      ),
    );
  }

  Widget _fallbackCard() {
    final red =
        card.suit == Suit.hearts ||
        card.suit == Suit.diamonds;

    final color = red ? Colors.red.shade700 : Colors.black87;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: card.isBlackQueen
              ? Colors.amber.shade700
              : Colors.black26,
          width: card.isBlackQueen ? 2.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 3,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 3,
            top: 2,
            child: _cornerText(color),
          ),

          Positioned(
            right: 3,
            bottom: 2,
            child: Transform.rotate(
              angle: pi,
              child: _cornerText(color),
            ),
          ),

          Center(
            child: Text(
              card.suitSymbol,
              style: TextStyle(
                fontSize: 26,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerText(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rankLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
        Text(
          card.suitSymbol,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// A small badge for a player seat.
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

/// One player's position at the table.
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
```
  
