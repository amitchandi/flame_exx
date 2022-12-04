import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';

import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';
import 'waste.dart';

class StockPile extends PositionComponent
    with TapCallbacks, HasGameRef<KlondikeGame>
    implements Pile {
  StockPile({super.position}) : super(size: KlondikeGame.cardSize);

  /// Which cards are currently placed onto this pile. The first card in the
  /// list is at the bottom, the last card is on top.
  final List<Card> _cards = [];
  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0xFF3F5B5D);
  final _circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 100
    ..color = const Color(0x883F5B5D);

  @override
  void acquireCard(Card card) {
    assert(!card.isFaceUp);
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
    card.pile = this;
  }

  @override
  void onTapUp(TapUpEvent event) {
    final wastePile = parent!.firstChild<WastePile>()!;
    if (_cards.isEmpty) {
      List<Card> movedCards = [];
      wastePile.removeAllCards().reversed.forEach((card) {
        card.flip();
        acquireCard(card);
        movedCards.add(card);
      });
      gameRef.addMove(wastePile, this, movedCards, null, null);
    } else {
      List<Card> movedCards = [];
      for (var i = 0; i < 3; i++) {
        if (_cards.isNotEmpty) {
          final card = _cards.removeLast();
          card.flip();
          wastePile.acquireCard(card);
          movedCards.add(card);
        }
      }
      gameRef.addMove(this, wastePile, movedCards, null, null);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      KlondikeGame.cardWidth * 0.3,
      _circlePaint,
    );
  }

  @override
  bool canMoveCard(Card card) => false;

  @override
  bool canAcceptCard(Card card) {
    return false;
  }

  @override
  void removeCard(Card card) {
    _cards.removeLast();
  }

  @override
  void returnCard(Card card) =>
      throw StateError('cannot remove cards from here');

  @override
  Card? getLastCard() {
    return _cards.isEmpty ? null : _cards.last;
  }
}
