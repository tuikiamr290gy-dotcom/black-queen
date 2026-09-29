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

    final Color suitColor =
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
              // TOP LEFT
              Positioned(
                left: 4,
                top: 3,
                child: _corner(suitColor),
              ),

              // BOTTOM RIGHT
              Positioned(
                right: 4,
                bottom: 3,
                child: Transform.rotate(
                  angle: pi,
                  child: _corner(suitColor),
                ),
              ),

              // CENTER
              Positioned.fill(
                child: _center(suitColor),
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
            fontSize: width * 0.25,
            fontWeight: FontWeight.bold,
            height: 0.9,
          ),
        ),
        Text(
          card.suitSymbol,
          style: TextStyle(
            color: color,
            fontSize: width * 0.19,
            height: 0.9,
          ),
        ),
      ],
    );
  }

  Widget _center(Color color) {
    // ACE
    if (card.rank == 14) {
      return Center(
        child: Text(
          card.suitSymbol,
          style: TextStyle(
            color: color,
            fontSize: width * 0.65,
            height: 1,
          ),
        ),
      );
    }

    // JACK / QUEEN / KING
    if (card.rank == 11 ||
        card.rank == 12 ||
        card.rank == 13) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.rankLabel,
              style: TextStyle(
                color: color,
                fontSize: width * 0.52,
                fontWeight: FontWeight.bold,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.suitSymbol,
              style: TextStyle(
                color: color,
                fontSize: width * 0.32,
                height: 0.9,
              ),
            ),
          ],
        ),
      );
    }

    // NUMBER CARDS
    final pips = _pipLayouts[card.rank] ?? const [];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.10,
        vertical: height * 0.13,
      ),
      child: Stack(
        children: [
          for (final pip in pips)
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
                    fontSize: width * 0.19,
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
