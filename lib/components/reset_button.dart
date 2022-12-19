import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_klondike/klondike_game.dart';

class ResetButton extends PositionComponent
    with TapCallbacks, HasGameRef<KlondikeGame> {
  late final Sprite sprite;
  @override
  Future<void>? onLoad() async {
    sprite = newGameSprite;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!gameRef.isRunningInit) {
      gameRef.resetGame();
    }
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: Vector2(500, 500));
  }
}
