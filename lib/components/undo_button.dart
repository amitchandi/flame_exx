import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_ex/klondike_game.dart';

class UndoButton extends PositionComponent
    with TapCallbacks, HasGameRef<KlondikeGame> {
  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0xFF3F5B5D);
  final _circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 100
    ..color = const Color(0x883F5B5D);
  late final Sprite image;
  @override
  Future<void>? onLoad() async {
    debugMode = true;
    image = await gameRef.loadSprite('undo.png');
  }

  @override
  void onTapUp(TapUpEvent event) {
    gameRef.undoMove();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      KlondikeGame.cardWidth * 0.3,
      _circlePaint,
    );
    image.render(canvas);
  }
}
