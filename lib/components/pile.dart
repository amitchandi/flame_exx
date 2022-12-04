import 'dart:ui';
import 'package:flame/components.dart';
import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';

class TableauPile extends PositionComponent implements Pile {
  TableauPile({super.position}) : super(size: KlondikeGame.cardSize);

  final List<Card> _cards = [];
  final Vector2 _fanOffset1 = Vector2(0, KlondikeGame.cardHeight * 0.05);
  final Vector2 _fanOffset2 = Vector2(0, KlondikeGame.cardHeight * 0.20);

  @override
  void acquireCard(Card card) {
    if (_cards.isEmpty) {
      card.position = position;
    } else {
      card.position = _cards.last.position + _fanOffset1;
    }
    card.priority = _cards.length;
    _cards.add(card);
    card.pile = this;
    layOutCards();
  }

  void acquireCardUndo(Card card) {
    Vector2 pos = _cards.isEmpty ? position : position + _fanOffset1;
    card.priority = 100;
    _cards.add(card);
    card.pile = this;
    card.moveCard(pos, () {
      card.priority = _cards.length;
      layOutCards();
    });
  }

  void acquireMultiCardUndo(List<Card> cards) {
    Card prevCard = _cards.last;
    Vector2 pos = Vector2.copy(_cards.isEmpty ? position : prevCard.position);
    for (int i = 0; i < cards.length; i++) {
      Card card = cards[i];
      pos.add(prevCard.isFaceDown && card == cards.first
          ? _fanOffset1
          : _fanOffset2);
      card.priority = 100 + i;
      _cards.add(card);
      card.pile = this;
      card.moveCard(pos, () {
        card.priority = _cards.length;
        if (card == cards.last) {
          layOutCards();
        }
      });
    }
  }

  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0x50ffffff);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
  }

  void flipTopCard() {
    assert(_cards.last.isFaceDown);
    _cards.last.flip();
  }

  @override
  bool canMoveCard(Card card) => card.isFaceUp;

  @override
  bool canAcceptCard(Card card) {
    if (_cards.isEmpty) {
      return card.rank.value == 13;
    } else {
      final topCard = _cards.last;
      return card.suit.isRed == !topCard.suit.isRed &&
          card.rank.value == topCard.rank.value - 1;
    }
  }

  @override
  void removeCard(Card card) {
    assert(_cards.contains(card) && card.isFaceUp);
    final index = _cards.indexOf(card);
    _cards.removeRange(index, _cards.length);
    if (_cards.isNotEmpty && _cards.last.isFaceDown) {
      flipTopCard();
    }
    layOutCards();
  }

  @override
  void returnCard(Card card) async {
    final index = _cards.indexOf(card);
    card.priority = 100;
    card.moveCard(
        index == 0
            ? position
            : _cards[index - 1].position +
                (_cards[index - 1].isFaceDown ? _fanOffset1 : _fanOffset2), () {
      card.priority = index;
      layOutCards();
    });
  }

  void returnCards(List<Card> cards) {
    Card prevCard = _cards[_cards.indexOf(cards.first) - 1];
    Vector2 pos = Vector2.copy(_cards.isEmpty ? position : prevCard.position);
    for (int i = 0; i < cards.length; i++) {
      Card card = cards[i];
      pos.add(prevCard.isFaceDown && card == cards.first
          ? _fanOffset1
          : _fanOffset2);
      final index = _cards.indexOf(card);
      card.priority = 100 + i;
      card.moveCard(pos, () {
        if (card == cards.last) {
          card.priority = index;
          layOutCards();
        }
      });
    }
  }

  void layOutCards() {
    if (_cards.isEmpty) {
      return;
    }
    _cards[0].position.setFrom(position);
    _cards[0].priority = 0;
    for (var i = 1; i < _cards.length; i++) {
      _cards[i].position
        ..setFrom(_cards[i - 1].position)
        ..add(_cards[i - 1].isFaceDown ? _fanOffset1 : _fanOffset2);
      _cards[i].priority = i;
    }
    height = KlondikeGame.cardHeight * 1.5 + _cards.last.y - _cards.first.y;
  }

  List<Card> cardsOnTop(Card card) {
    assert(card.isFaceUp && _cards.contains(card));
    final index = _cards.indexOf(card);
    return _cards.getRange(index + 1, _cards.length).toList();
  }

  @override
  Card? getLastCard() {
    return _cards.isEmpty ? null : _cards.last;
  }

  Card? getParentCard(Card card) {
    int i = _cards.indexOf(card);
    if (i > 0) {
      return _cards[i - 1];
    } else {
      return null;
    }
  }
}
