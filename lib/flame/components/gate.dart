import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:ricochlime/flame/components/bullet.dart';
import 'package:ricochlime/flame/components/monster.dart';
import 'package:ricochlime/flame/components/row_entity.dart';
import 'package:ricochlime/flame/ricochlime_game.dart';

enum GateType {
  /// Multiplies the number of bullets, e.g. x2.
  multiply,

  /// Adds a fixed number of bullets, e.g. +3.
  add,
}

/// A multiplier gate.
///
/// Bullets pass through it freely (it's a sensor),
/// and each bullet that passes through spawns extra bullets,
/// once per gate per bullet family.
class Gate extends BodyComponent
    with ContactCallbacks, RowEntityMovement
    implements RowEntity {
  // ignore: public_member_api_docs
  Gate({
    required this.initialPosition,
    required this.columns,
    required this.type,
    required this.multiplier,
  }) : super(
         renderBody: false,
         priority: rowEntityPriority(initialPosition),
         bodyDef: BodyDef(position: initialPosition, fixedRotation: true),
       ) {
    fixtureDefs = [
      FixtureDef(
        PolygonShape()
          ..setAsBox(
            gateWidth / 2,
            gateHeight / 2,
            Vector2(gateWidth / 2, gateHeight / 2),
            0,
          ),
        userData: this,
        isSensor: true,
        filter: Filter()
          // gates are in their own collision category...
          ..categoryBits = gateCategory
          // ...and only interact with bullets
          ..maskBits = bulletCategory,
      ),
    ];

    add(
      TextComponent(
        text: label,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: gateHeight * 0.75,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(gateWidth / 2, gateHeight / 2),
        priority: 1,
      ),
    );
  }

  /// Creates a Gate from JSON data.
  factory Gate.fromJson(Map<String, dynamic> json) {
    return Gate(
      initialPosition: Vector2(json['px'] as double, json['py'] as double),
      columns: json['cols'] as int? ?? 2,
      type: GateType.values[json['type'] as int? ?? 0],
      multiplier: json['mult'] as int,
    );
  }

  /// Converts the gate's data to a JSON map.
  Map<String, dynamic> toJson() => {
    'px': position.x,
    'py': position.y,
    'cols': columns,
    'type': type.index,
    'mult': multiplier,
  };

  /// The collision category of gates.
  static const gateCategory = 1 << 3;

  /// The collision category of bullets, mirrored from `Bullet`.
  static const bulletCategory = 1 << 2;

  /// The height of the gate.
  static const gateHeight = 6.0;

  /// The initial position of the gate (top-left corner).
  final Vector2 initialPosition;

  /// How many grid columns the gate spans.
  final int columns;

  /// Whether this gate multiplies or adds bullets.
  final GateType type;

  /// The multiplier (e.g. 2 for x2) or the number of
  /// extra bullets (e.g. 3 for +3).
  final int multiplier;

  /// The width of the gate, based on how many [columns] it spans.
  double get gateWidth => Monster.staticWidth * columns;

  /// The text shown on the gate, e.g. `x2` or `+3`.
  String get label => switch (type) {
    .multiply => 'x$multiplier',
    .add => '+$multiplier',
  };

  Color get _color => switch (type) {
    .multiply => const Color(0xff2e9bd6),
    .add => const Color(0xffe8930c),
  };

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
    updateRowMovement(dt);

    // safety net: remove the gate once it's past the bottom of the screen
    if (position.y > RicochlimeGame.expectedHeight) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(gateWidth, gateHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1.5));
    canvas
      ..drawRRect(rrect, Paint()..color = _color.withValues(alpha: 0.35))
      ..drawRRect(
        rrect,
        Paint()
          ..color = _color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    if (other is Bullet) {
      (game as RicochlimeGame).onBulletPassedThroughGate(this, other);
    }
  }
}
