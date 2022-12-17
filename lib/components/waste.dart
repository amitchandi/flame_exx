import 'package:flame/components.dart';
import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';

class WastePile extends PositionComponent
    with HasGameRef<KlondikeGame>
    implements Pile {
  WastePile({super.position}) : super(size: KlondikeGame.cardSize);

  final List<Card> _cards = [];
  final Vector2 _fanOffset = Vector2(KlondikeGame.cardWidth * 0.2, 0);

  @override
  void acquireCard(Card card) {
    assert(card.isFaceUp);
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
    card.pile = this;
    fanOutTopCards();
  }

  void acquireCardsFromStock(List<Card> cards) {
    for (int i = 0; i < cards.length; i++) {
      Card card = cards[i];
      if (card.isFaceDown) {
        card.flip();
      }
      Vector2 pos = position.clone();
      if (i == cards.length - 2) {
        pos.add(_fanOffset);
      } else if (i == cards.length - 1) {
        pos.addScaled(_fanOffset, 2);
      }
      card.priority = 100 + i;
      card.moveCard(pos, () async {
        card.priority = _cards.length;
        _cards.add(card);
        card.pile = this;
        if (card == cards.last) {
          fanOutTopCards();
        }
      }, i <= 2);
    }
  }

  void fanOutTopCards() {
    final n = _cards.length;
    for (var i = 0; i < n; i++) {
      _cards[i].position = position;
    }
    if (n == 2) {
      _cards[1].position.add(_fanOffset);
    } else if (n >= 3) {
      _cards[n - 2].position.add(_fanOffset);
      _cards[n - 1].position.addScaled(_fanOffset, 2);
    }
  }

  @override
  List<Card> removeAllCards() {
    final cards = _cards.toList();
    _cards.clear();
    return cards;
  }

  @override
  bool canMoveCard(Card card) => _cards.isNotEmpty && card == _cards.last;

  @override
  bool canAcceptCard(Card card) {
    return false;
  }

  @override
  void removeCard(Card card) {
    assert(canMoveCard(card));
    _cards.removeLast();
    fanOutTopCards();
  }

  @override
  void returnCard(Card card) {
    card.priority = 100;
    Vector2 pos = position.clone();
    if (_cards.length == 2) {
      pos.add(_fanOffset);
    }
    if (_cards.length >= 3) {
      pos.addScaled(_fanOffset, 2);
    }
    card.moveCard(pos, () async {
      card.priority = _cards.indexOf(card);
      fanOutTopCards();
    }, true);
  }

  int indexOfCard(Card card) {
    return _cards.indexOf(card);
  }

  bool isEmpty() {
    return _cards.isEmpty;
  }

  @override
  Card? getLastCard() {
    return _cards.isEmpty ? null : _cards.last;
  }

  Card? cardOfIndex(int i) {
    return _cards.isEmpty ? null : _cards[i];
  }

  // acquire card for undo action
  void acquireCardUndo(Card card, Card? parentCard) {
    card.pile = this;
    Vector2 pos;
    if (_cards.isEmpty) {
      pos = position;
    } else if (_cards.length == 1) {
      pos = position.clone()..add(_fanOffset);
    } else {
      pos = position.clone()..addScaled(_fanOffset, 2);
    }
    card.priority = 100;
    card.moveCard(pos, () async {
      if (parentCard == null) {
        card.priority = 0;
        _cards.insert(0, card);
      } else {
        int i = indexOfCard(parentCard) + 1;
        _cards.insert(i, card);
        card.priority = i;
      }
      fanOutTopCards();
    }, true);
  }
}
