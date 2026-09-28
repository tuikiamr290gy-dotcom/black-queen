import 'dart:math';

/// The four suits.
enum Suit { spades, hearts, diamonds, clubs }

/// One playing card. Rank: 2..10, 11 = Jack, 12 = Queen, 13 = King, 14 = Ace.
class PlayingCard {
  final Suit suit;
  final int rank;

  const PlayingCard(this.suit, this.rank);

  /// Queen of Spades, the "Black Queen".
  bool get isBlackQueen => suit == Suit.spades && rank == 12;

  bool get isHeart => suit == Suit.hearts;

  /// Black Queen = 12 points, each heart = 1 point, everything else = 0.
  int get points => isBlackQueen ? 12 : (isHeart ? 1 : 0);

  String get rankLabel {
    switch (rank) {
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      case 14:
        return 'A';
      default:
        return '$rank';
    }
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  String get label => '$rankLabel$suitSymbol';

  // Used later to send cards over the wifi connection.
  Map<String, int> toJson() => {'s': suit.index, 'r': rank};

  factory PlayingCard.fromJson(Map<String, dynamic> json) =>
      PlayingCard(Suit.values[json['s'] as int], json['r'] as int);

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => label;
}

/// A card that a certain seat has put on the table.
class PlayedCard {
  final int seat;
  final PlayingCard card;

  const PlayedCard(this.seat, this.card);
}

/// Card rules that do not depend on the game state.
class Rules {
  /// A new shuffled deck of 52 cards.
  static List<PlayingCard> newDeck(Random random) {
    final deck = <PlayingCard>[
      for (final suit in Suit.values)
        for (var rank = 2; rank <= 14; rank++) PlayingCard(suit, rank),
    ];
    deck.shuffle(random);
    return deck;
  }

  /// Sort a hand by suit, then by rank (high to low), so it is easy to read.
  static void sortHand(List<PlayingCard> hand) {
    hand.sort((a, b) {
      final bySuit = a.suit.index.compareTo(b.suit.index);
      if (bySuit != 0) return bySuit;
      return b.rank.compareTo(a.rank);
    });
  }

  /// Which cards a player may put.
  /// - First card of the round: any card.
  /// - Otherwise: must follow the first suit if they have it.
  /// - If they have none of that suit: any card.
  static List<PlayingCard> legalCards(List<PlayingCard> hand, Suit? ledSuit) {
    if (ledSuit == null) return List<PlayingCard>.from(hand);
    final sameSuit = hand.where((c) => c.suit == ledSuit).toList();
    return sameSuit.isNotEmpty ? sameSuit : List<PlayingCard>.from(hand);
  }

  /// The winner is the highest card of the first suit (Ace high).
  static int trickWinner(List<PlayedCard> trick) {
    final ledSuit = trick.first.card.suit;
    var best = trick.first;
    for (final played in trick) {
      if (played.card.suit == ledSuit && played.card.rank > best.card.rank) {
        best = played;
      }
    }
    return best.seat;
  }

  /// Total points inside a round's cards.
  static int trickPoints(List<PlayedCard> trick) =>
      trick.fold(0, (sum, p) => sum + p.card.points);
}

/// The whole game: 4 seats, unlimited deals, scores keep adding up.
/// Lowest score is best.
class BlackQueenGame {
  static const int seats = 4;
  static const int cardsPerPlayer = 13;

  final Random _random;

  final List<List<PlayingCard>> hands =
      List.generate(seats, (_) => <PlayingCard>[]);
  final List<int> scores = List.filled(seats, 0);

  /// Cards on the table in the current round.
  List<PlayedCard> trick = [];

  /// Whose turn it is.
  int currentSeat = 0;

  /// How many new-card deals have been played (starts at 1 after startDeal).
  int dealNumber = 0;

  /// How many rounds are finished in the current deal (0..13).
  int tricksPlayed = 0;

  /// True when all 13 rounds of the deal are finished.
  bool dealOver = false;

  // Info about the round that just finished, so the screen can show it.
  List<PlayedCard> lastTrick = [];
  int? lastTrickWinner;
  int lastTrickPoints = 0;

  BlackQueenGame({Random? random}) : _random = random ?? Random();

  /// The suit of the first card on the table, or null if the table is empty.
  Suit? get ledSuit => trick.isEmpty ? null : trick.first.card.suit;

  /// Start a new deal with fresh cards. Scores are kept.
  /// The winner of the last round starts; seat 0 starts the very first deal.
  void startDeal() {
    final deck = Rules.newDeck(_random);
    for (var seat = 0; seat < seats; seat++) {
      hands[seat]
        ..clear()
        ..addAll(deck.sublist(seat * cardsPerPlayer, (seat + 1) * cardsPerPlayer));
      Rules.sortHand(hands[seat]);
    }
    trick = [];
    tricksPlayed = 0;
    dealOver = false;
    dealNumber++;
    currentSeat = lastTrickWinner ?? 0;
  }

  /// Cards the given seat is allowed to put right now.
  List<PlayingCard> legalMoves(int seat) {
    if (seat != currentSeat || dealOver) return [];
    return Rules.legalCards(hands[seat], ledSuit);
  }

  /// Try to play a card. Returns null if OK, or a message if the move is wrong.
  String? playCard(int seat, PlayingCard card) {
    if (dealOver) return 'This deal is finished. Start a new deal.';
    if (seat != currentSeat) return 'It is not your turn.';
    if (!hands[seat].contains(card)) return 'You do not have this card.';
    if (!legalMoves(seat).contains(card)) {
      return 'You must play a card of the first suit.';
    }

    hands[seat].remove(card);
    trick.add(PlayedCard(seat, card));

    if (trick.length < seats) {
      currentSeat = (seat + 1) % seats;
      return null;
    }

    // Everyone has played: find the winner and give the points.
    final winner = Rules.trickWinner(trick);
    final points = Rules.trickPoints(trick);
    scores[winner] += points;

    lastTrick = trick;
    lastTrickWinner = winner;
    lastTrickPoints = points;

    trick = [];
    tricksPlayed++;
    currentSeat = winner;
    if (tricksPlayed == cardsPerPlayer) dealOver = true;
    return null;
  }
}
