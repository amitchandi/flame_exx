import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_klondike/klondike_game.dart';

class UndoButton extends PositionComponent
    with TapCallbacks, HasGameRef<KlondikeGame> {
  late final Sprite sprite;
  @override
  Future<void>? onLoad() async {
    sprite = iconSprite(0, 97, 96, 96);
    flipHorizontallyAroundCenter();
  }

  @override
  void onTapUp(TapUpEvent event) {
    gameRef.undoMove();
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: Vector2(500, 500));
  }
}
