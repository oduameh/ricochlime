import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:ricochlime/flame/components/bullet.dart';
import 'package:ricochlime/flame/components/monster.dart';
import 'package:ricochlime/flame/components/row_entity.dart';
import 'package:ricochlime/flame/ricochlime_game.dart';
import 'package:ricochlime/utils/ricochlime_palette.dart';

/// A static numbered block with HP.
///
/// Bullets bounce off it, losing it 1 HP per hit.
/// When its HP reaches 0, the block is destroyed.
class Block extends BodyComponent
    with ContactCallbacks, RowEntityMovement
    implements RowEntity {
  // ignore: public_member_api_docs
  Block({required this.initialPosition, required this.maxHp, int? hp})
    : _hp = hp ?? maxHp,
      super(
        renderBody: false,
        priority: rowEntityPriority(initialPosition),
        bodyDef: BodyDef(position: initialPosition, fixedRotation: true),
      ) {
    fixtureDefs = [
      FixtureDef(
        PolygonShape()
          ..setAsBox(
            staticWidth / 2,
            staticHeight / 2,
            Vector2(staticWidth / 2, staticHeight / 2),
            0,
          ),
        userData: this,
      ),
    ];

    add(_hpText);
  }

  /// Creates a Block from JSON data.
  factory Block.fromJson(Map<String, dynamic> json) {
    final maxHp = json['maxHp'] as int;
    return Block(
      initialPosition: Vector2(json['px'] as double, json['py'] as double),
      maxHp: maxHp,
      hp: json['hp'] as int? ?? maxHp,
    );
  }

  /// Converts the block's data to a JSON map.
  Map<String, dynamic> toJson() => {
    'px': position.x,
    'py': position.y,
    'maxHp': maxHp,
    if (hp != maxHp) 'hp': hp,
  };

  /// The width of the block: exactly one grid column.
  static const staticWidth = Monster.staticWidth;

  /// The height of the block.
  static const staticHeight = Monster.staticHeight;

  /// The initial position of the block (top-left corner of its cell).
  final Vector2 initialPosition;

  /// The maximum health.
  final int maxHp;

  /// The current health.
  int get hp => _hp;
  int _hp;
  set hp(int value) {
    _hp = value;
    _hpText.text = '$value';
  }

  /// Whether the block has been destroyed.
  bool get isDead => hp <= 0;

  late final TextComponent _hpText = TextComponent(
    text: '$hp',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 6,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    ),
    anchor: Anchor.center,
    position: Vector2(staticWidth / 2, staticHeight / 2),
    priority: 1,
  );

  @override
  Vector2 get position {
    if (isLoaded) {
      return body.position;
    } else {
      return initialPosition;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      if (body.isActive) body.setActive(false);
      removeFromParent();
      return;
    }

    updateRowMovement(dt);
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & const Size(staticWidth, staticHeight);
    const inset = 0.5;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(inset),
          const Radius.circular(1.5),
        ),
        Paint()..color = RicochlimePalette.monsterColor.withValues(alpha: 0.85),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(inset),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    if (isDead) return;

    if (other is Bullet) {
      hp -= 1;
      (game as RicochlimeGame).audio.playHitSfx();
    }
  }
}
