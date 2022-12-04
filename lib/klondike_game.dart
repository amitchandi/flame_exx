import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/experimental.dart';
import 'package:flame_ex/components/undo_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/effects.dart';

import 'components/card.dart';
import 'components/stock.dart';
import 'components/foundation.dart';
import 'components/pile.dart';
import 'components/waste.dart';
import 'move.dart';
import 'pile.dart';

class KlondikeGame extends FlameGame
    with HasTappableComponents, HasDraggableComponents {
  static const double cardWidth = 1000.0;
  static const double cardHeight = 1400.0;
  static const double cardGap = 175.0;
  static const double cardRadius = 100.0;
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);

  static final cardRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, cardWidth, cardHeight),
    const Radius.circular(cardRadius),
  );

  @override
  Future<void> onLoad() async {
    //this.debugMode = true;
    await Flame.images.load('klondike-sprites.png');
    await Flame.images.load('undo.png');
    final stock = StockPile()
      ..size = cardSize
      ..position = Vector2(cardGap, cardGap);
    final waste = WastePile()
      ..size = cardSize
      ..position = Vector2(cardWidth + 2 * cardGap, cardGap);
    final undoButton = UndoButton()
      ..size = Vector2(500, 200)
      ..position = Vector2(3000, cardGap);
    final foundations = List.generate(
      4,
      (i) => FoundationPile(
        i,
        position: Vector2((i + 3) * (cardWidth + cardGap) + cardGap, cardGap),
      )
        ..size = cardSize
        ..position =
            Vector2((i + 3) * (cardWidth + cardGap) + cardGap, cardGap),
    );
    final piles = List.generate(
      7,
      (i) => TableauPile()
        ..size = cardSize
        ..position = Vector2(
          cardGap + i * (cardWidth + cardGap),
          cardHeight + 2 * cardGap,
        ),
    );

    final world = World()
      ..add(stock)
      ..add(waste)
      ..add(undoButton)
      ..addAll(foundations)
      ..addAll(piles);
    add(world);

    final camera = CameraComponent(world: world)
      ..viewfinder.visibleGameSize =
          Vector2(cardWidth * 7 + cardGap * 8, 4 * cardHeight + 3 * cardGap)
      ..viewfinder.position = Vector2(cardWidth * 3.5 + cardGap * 4, 0)
      ..viewfinder.anchor = Anchor.topCenter;
    add(camera);

    final cards = [
      for (var rank = 1; rank <= 13; rank++)
        for (var suit = 0; suit < 4; suit++) Card(rank, suit)
    ];
    cards.shuffle();
    world.addAll(cards);

    for (var i = 0; i < 7; i++) {
      for (var j = i; j < 7; j++) {
        piles[j].acquireCard(cards.removeLast());
      }
      piles[i].flipTopCard();
    }
    for (var element in cards) {
      stock.acquireCard(element);
    }
  }

  final List<Move> moves = [];

  void undoMove() {
    if (moves.isEmpty) {
      return;
    }
    Move lastmove = moves.removeLast();
    // use lastmove to return cards to original source
    if (lastmove.fromPile is TableauPile && lastmove.toPile is TableauPile) {
      if (lastmove.formerWasFlipped!) {
        lastmove.formerParent?.flip();
      }
      Card fCard = lastmove.movedCards.first;
      lastmove.toPile.removeCard(fCard);
      if (lastmove.movedCards.length == 1) {
        (lastmove.fromPile as TableauPile).acquireCardUndo(fCard);
      } else {
        (lastmove.fromPile as TableauPile)
            .acquireMultiCardUndo(lastmove.movedCards);
      }
      // for (Card card in lastmove.movedCards) {
      //   (lastmove.fromPile as TableauPile).acquireCardUndo(card);
      // }
    } else if (lastmove.fromPile is StockPile && lastmove.toPile is WastePile) {
      for (Card card in lastmove.movedCards.reversed) {
        card.flip();
        lastmove.toPile.removeCard(card);
        lastmove.fromPile.acquireCard(card);
      }
    } else if (lastmove.fromPile is WastePile && lastmove.toPile is StockPile) {
      for (Card card in lastmove.movedCards.reversed) {
        card.flip();
        lastmove.toPile.removeCard(card);
        lastmove.fromPile.acquireCard(card);
      }
    } else if (lastmove.fromPile is WastePile &&
        (lastmove.toPile is TableauPile || lastmove.toPile is FoundationPile)) {
      lastmove.toPile.removeCard(lastmove.movedCards.first);
      (lastmove.fromPile as WastePile)
          .acquireCardUndo(lastmove.movedCards.first, lastmove.formerParent);
    } else if (lastmove.fromPile is TableauPile &&
        lastmove.toPile is FoundationPile) {
      if (lastmove.formerWasFlipped != null && lastmove.formerWasFlipped!) {
        lastmove.formerParent?.flip();
      }
      lastmove.toPile.removeCard(lastmove.movedCards.first);
      (lastmove.fromPile as TableauPile)
          .acquireCardUndo(lastmove.movedCards.first);
    }
  }

  void addMove(Pile fromPile, Pile toPile, List<Card> movedCards,
      Card? formerParent, bool? formerWasFlipped) {
    Move move = Move(moves.length, fromPile, toPile, movedCards, formerParent,
        formerWasFlipped);
    if (kDebugMode) {
      print(move);
    }
    moves.add(move);
  }
}

Sprite klondikeSprite(double x, double y, double width, double height) {
  return Sprite(
    Flame.images.fromCache('klondike-sprites.png'),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}
