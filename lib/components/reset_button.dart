import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_klondike/klondike_game.dart';

class ResetButton extends PositionComponent
    with TapCallbacks, HasGameRef<KlondikeGame> {
  late final Sprite image;
  @override
  Future<void>? onLoad() async {
    image = await gameRef.loadSprite('buttons.png');
  }

  @override
  void onTapUp(TapUpEvent event) {
    // gameRef.undoMove();
    print('reset');
    gameRef.resetGame();
  }

  @override
  void render(Canvas canvas) {
    image.render(canvas, size: Vector2(500, 300));
  }
}
