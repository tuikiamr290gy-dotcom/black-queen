import 'dart:math';

import 'game_logic.dart';

/// Easy bot plays a random allowed card.
/// Hard bot tries to avoid hearts and the Black Queen.
enum BotLevel { easy, hard }

class BotPlayer {
  final BotLevel level;
  final Random _random;

  BotPlayer({this.level = BotLevel.hard, Random? random})
      : _random = random ?? Random();

  /// Choose a card for the given seat. Only allowed cards are ever returned,
  /// so a bot can never cheat.
  PlayingCard chooseCard(BlackQueenGame game, int seat) {
    final legal = game.legalMoves(seat);
    if (legal.isEmpty) {
      throw StateError('Seat $seat has no card to play right now.');
    }
    if (legal.length == 1) return legal.first;
    if (level == BotLevel.easy) {
      return legal[_random.nextInt(legal.length)];
    }
    return _smartChoice(game, seat, legal);
  }

  PlayingCard _smartChoice(
      BlackQueenGame game, int seat, List<PlayingCard> legal) {
    final led = game.ledSuit;
    final hand = game.hands[seat];

    // 1. The bot is the first to play in this round.
    if (led == null) return _chooseLead(legal);

    // 2. The bot has no card of the first suit: throw away a bad card.
    final hasLedSuit = hand.any((c) => c.suit == led);
    if (!hasLedSuit) return _chooseDiscard(legal);

    // 3. The bot must follow the first suit.
    return _chooseFollow(game, legal, led);
  }

  /// Lead with a low, safe card. Avoid hearts and the Black Queen.
  PlayingCard _chooseLead(List<PlayingCard> legal) {
    PlayingCard best = legal.first;
    var bestScore = 1 << 30;
    for (final card in legal) {
      var score = card.rank;
      if (card.isHeart) score += 3;
      if (card.isBlackQueen) score += 100;
      if (score < bestScore) {
        bestScore = score;
        best = card;
      }
    }
    return best;
  }

  /// No card of the first suit: give away the Black Queen first,
  /// then the highest heart, then the highest card.
  PlayingCard _chooseDiscard(List<PlayingCard> legal) {
    for (final card in legal) {
      if (card.isBlackQueen) return card;
    }
    final hearts = legal.where((c) => c.isHeart).toList();
    if (hearts.isNotEmpty) return _highest(hearts);
    return _highest(legal);
  }

  /// Must follow the suit. Try not to win rounds that have points.
  PlayingCard _chooseFollow(
      BlackQueenGame game, List<PlayingCard> legal, Suit led) {
    final trick = game.trick;

    var highestOnTable = 0;
    var pointsOnTable = 0;
    for (final played in trick) {
      if (played.card.suit == led && played.card.rank > highestOnTable) {
        highestOnTable = played.card.rank;
      }
      pointsOnTable += played.card.points;
    }

    // Cards that lose this round are safe to play.
    final safe = legal.where((c) => c.rank < highestOnTable).toList();
    if (safe.isNotEmpty) {
      // If the Black Queen is safe, get rid of it now.
      for (final card in safe) {
        if (card.isBlackQueen) return card;
      }
      return _highest(safe);
    }

    // Every card would win this round.
    final withoutQueen = legal.where((c) => !c.isBlackQueen).toList();
    final pool = withoutQueen.isNotEmpty ? withoutQueen : legal;

    // Last to play and no points on the table: winning costs nothing,
    // so get rid of a high card.
    final isLastToPlay = trick.length == BlackQueenGame.seats - 1;
    if (isLastToPlay && pointsOnTable == 0) return _highest(pool);

    return _lowest(pool);
  }

  PlayingCard _highest(List<PlayingCard> cards) =>
      cards.reduce((a, b) => a.rank >= b.rank ? a : b);

  PlayingCard _lowest(List<PlayingCard> cards) =>
      cards.reduce((a, b) => a.rank <= b.rank ? a : b);
}
