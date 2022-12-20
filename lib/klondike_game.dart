import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/experimental.dart';
import 'package:flame_audio/audio_pool.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'components/card.dart';
import 'components/reset_button.dart';
import 'components/stock.dart';
import 'components/foundation.dart';
import 'components/pile.dart';
import 'components/waste.dart';
import 'components/undo_button.dart';
import 'move.dart';
import 'pile.dart';

class KlondikeGame extends FlameGame
    with HasTappableComponents, HasDraggableComponents, HasTappablesBridge {
  static const double cardWidth = 1000.0;
  static const double cardHeight = 1400.0;
  static const double cardGap = 175.0;
  static const double cardRadius = 100.0;
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);

  static final cardRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, cardWidth, cardHeight),
    const Radius.circular(cardRadius),
  );

  late final World world;

  late final StockPile stock;
  late final WastePile waste;
  late final List<FoundationPile> foundations;
  late final List<TableauPile> piles;

  late final AudioPool flip;
  late final AudioPool place;

  late final List<Card> cards;
  final List<Move> moves = [];
  bool isRunningUndo = false;
  bool isRunningInit = false;

  late List<CardSpriteData> cardSpritesData;

  bool isEasy = false;

  @override
  Future<void> onLoad() async {
    // Makes the game full screen and landscape only.
    Flame.device.fullScreen();
    Flame.device.setLandscape();

    //this.debugMode = true;
    await Flame.images.load('cards.png');
    await Flame.images.load('icons.png');
    await Flame.images.load('card_icons.png');
    await FlameAudio.audioCache.clearAll();
    flip = await FlameAudio.createPool('card_flip.mp3', maxPlayers: 2);
    place = await FlameAudio.createPool('card_place.wav', maxPlayers: 10);

    final String cardSpritesJSON =
        await rootBundle.loadString('assets/cards.json');
    cardSpritesData = (await json.decode(cardSpritesJSON) as List)
        .map((i) => CardSpriteData.fromJson(i))
        .toList();

    stock = StockPile()
      ..size = cardSize
      ..position = Vector2(cardGap, cardGap);
    waste = WastePile()
      ..size = cardSize
      ..position = Vector2(cardWidth + 2 * cardGap, cardGap);
    final undoButton = UndoButton()
      ..size = Vector2(512, 512)
      ..position = Vector2(3000, cardGap);
    final resetButton = ResetButton()
      ..size = Vector2(512, 512)
      ..position = Vector2(3000, 1000);
    foundations = List.generate(
      4,
      (i) => FoundationPile(
        i,
        position: Vector2((i + 3) * (cardWidth + cardGap) + cardGap, cardGap),
      )
        ..size = cardSize
        ..position =
            Vector2((i + 3) * (cardWidth + cardGap) + cardGap, cardGap),
    );
    piles = List.generate(
      7,
      (i) => TableauPile()
        ..size = cardSize
        ..position = Vector2(
          cardGap + i * (cardWidth + cardGap),
          cardHeight + 2 * cardGap,
        ),
    );

    world = World()
      ..add(stock)
      ..add(waste)
      ..add(undoButton)
      ..add(resetButton)
      ..addAll(foundations)
      ..addAll(piles);
    add(world);

    final camera = CameraComponent(world: world)
      ..viewfinder.visibleGameSize =
          Vector2(cardWidth * 7 + cardGap * 8, 4 * cardHeight + 3 * cardGap)
      ..viewfinder.position = Vector2(cardWidth * 3.5 + cardGap * 4, 0)
      ..viewfinder.anchor = Anchor.topCenter;

    add(camera);

    cards = [
      for (var rank = 1; rank <= 13; rank++)
        for (var suit = 0; suit < 4; suit++)
          Card(rank, suit)..position = waste.position
    ];
    cards.shuffle();
    world.addAll(cards);
  }

  void initCards() async {
    isRunningInit = true;
    for (var i = 0; i < 7; i++) {
      for (var j = i; j < 7; j++) {
        piles[j].acquireCardInit(cards.removeLast(), i.toDouble());
        await Future.delayed(const Duration(milliseconds: 100));
      }
      piles[i].flipTopCard();
    }
    for (var element in cards) {
      stock.acquireCard(element);
    }
    isRunningInit = false;
  }

  void undoMove() {
    if (moves.isEmpty) {
      return;
    }
    if (isRunningUndo) {
      return;
    }
    isRunningUndo = true;

    Move lastmove = moves.removeLast();
    // use lastmove to return cards to original source
    if (lastmove.fromPile is TableauPile && lastmove.toPile is TableauPile) {
      if (lastmove.formerWasFlipped != null && lastmove.formerWasFlipped!) {
        lastmove.formerParent?.flip();
      }
      Card fCard = lastmove.movedCards.first;
      lastmove.toPile.removeCard(fCard);
      (lastmove.fromPile as TableauPile).acquireCardsUndo(lastmove.movedCards);
    } else if (lastmove.fromPile is StockPile && lastmove.toPile is WastePile) {
      for (Card card in lastmove.movedCards.reversed) {
        card.flip();
        lastmove.toPile.removeCard(card);
      }
      (lastmove.fromPile as StockPile)
          .acquireCardsFromWaste(lastmove.movedCards.reversed.toList());
    } else if (lastmove.fromPile is WastePile && lastmove.toPile is StockPile) {
      for (Card card in lastmove.movedCards.reversed) {
        card.flip();
        lastmove.toPile.removeCard(card);
      }
      (lastmove.fromPile as WastePile)
          .acquireCardsFromStock(lastmove.movedCards.reversed.toList());
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
      (lastmove.fromPile as TableauPile).acquireCardsUndo(lastmove.movedCards);
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

  void finishGame() async {
    var allCards = (findGame()! as FlameGame)
        .children
        .whereType<World>()
        .first
        .children
        .whereType<Card>();

    var remainingCards =
        allCards.where((element) => element.pile is TableauPile).toList();

    remainingCards.sort(((a, b) {
      return a.rank.value.compareTo(b.rank.value);
    }));
    for (var cardR in remainingCards) {
      var foundation = allCards
          .where((cardA) =>
              cardA.suit == cardR.suit &&
              cardA.rank.value == cardR.rank.value - 1)
          .first;
      if (kDebugMode) {
        print('${cardR.toString()} <- $foundation');
      }
      cardR.priority = 100;
      cardR.moveCard(foundation.position, () async {
        foundation.pile?.acquireCard(cardR);
      }, true);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    overlays.add('GameOver');
  }

  void resetGame() {
    world.children.whereType<Pile>().forEach((pile) {
      pile.removeAllCards();
    });
    world.removeWhere((component) {
      return component is Card;
    });
    cards.clear();
    for (var rank = 1; rank <= 13; rank++) {
      for (var suit = 0; suit < 4; suit++) {
        cards.add(Card(rank, suit)..position = waste.position);
      }
    }
    cards.shuffle();
    world.addAll(cards);
    initCards();
  }

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 68, 163, 55);
  }
}

Sprite cardsSprite(double x, double y, double width, double height) {
  return Sprite(
    Flame.images.fromCache('cards.png'),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}

Sprite cardIconsSprite(double x, double y, double width, double height) {
  return Sprite(
    Flame.images.fromCache('card_icons.png'),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}

Sprite iconSprite(double x, double y, double width, double height) {
  return Sprite(
    Flame.images.fromCache('icons.png'),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}

class CardSpriteData {
  String name;
  int x;
  int y;
  int width;
  int height;

  CardSpriteData(this.name, this.x, this.y, this.width, this.height);

  CardSpriteData.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        x = json['x'],
        y = json['y'],
        width = json['width'],
        height = json['height'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}
