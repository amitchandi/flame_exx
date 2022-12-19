import 'dart:ui';

import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import '../suit.dart';
import 'card.dart';

class FoundationPile extends PositionComponent
    with HasGameRef<KlondikeGame>
    implements Pile {
  FoundationPile(int intSuit, {super.position})
      : suit = Suit.fromInt(intSuit),
        super(size: KlondikeGame.cardSize);

  final Suit suit;
  final List<Card> _cards = [];
  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0x50ffffff);

  @override
  void acquireCard(Card card) {
    assert(card.isFaceUp);
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
    card.pile = this;
    gameRef.isRunningUndo = false;
    gameRef.place.start(volume: 0.1);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
    suit.sprite.render(
      canvas,
      position: size / 2,
      anchor: Anchor.center,
      size: suit.value == 1 || suit.value == 3
          ? Vector2(KlondikeGame.cardWidth * 0.4, KlondikeGame.cardWidth * 0.6)
          : Vector2.all(KlondikeGame.cardWidth * 0.6),
    );
  }

  @override
  bool canMoveCard(Card card) => false;

  @override
  bool canAcceptCard(Card card) {
    final topCardRank = _cards.isEmpty ? 0 : _cards.last.rank.value;
    return card.suit == suit &&
        card.rank.value == topCardRank + 1 &&
        card.attachedCards.isEmpty;
  }

  @override
  void removeCard(Card card) {
    _cards.remove(card);
  }

  @override
  void removeAllCards() {
    _cards.clear();
  }

  @override
  void returnCard(Card card) {
    card.position = position;
    card.priority = _cards.indexOf(card);
  }

  @override
  Card? getLastCard() => null;
}
