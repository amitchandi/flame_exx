import 'components/card.dart';
import 'pile.dart';

class Move {
  int id;
  Pile fromPile;
  Pile toPile;
  List<Card> movedCards;
  Card? formerParent;
  bool? formerWasFlipped;

  Move(this.id, this.fromPile, this.toPile, this.movedCards, this.formerParent,
      this.formerWasFlipped);

  @override
  String toString() {
    return 'id: $id, fromPile: $fromPile, toPile: $toPile, movedCards: $movedCards, formerParent: $formerParent, formerWasFlipped: $formerWasFlipped';
  }
}
