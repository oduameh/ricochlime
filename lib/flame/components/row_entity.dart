import 'dart:ui' show lerpDouble;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:ricochlime/flame/ricochlime_game.dart';

/// How far down an entity moves each round,
/// matching [Monster.moveDownHeight].
const rowMoveDownHeight = 16.0;

/// The render priority for a row entity at [position],
/// so that lower rows draw over upper rows.
///
/// Mirrors `Monster.getPriorityFromPosition`.
int rowEntityPriority(Vector2 position) {
  const maxPriority = 0;
  const minPriority = -100;
  final yRelative = position.y / RicochlimeGame.expectedHeight;
  return lerpDouble(minPriority, maxPriority, yRelative)!.round();
}

/// An entity that lives in the grid of rows that
/// advances towards the player each round:
/// monsters, blocks and gates.
abstract interface class RowEntity {
  /// Moves the entity down to the next row.
  void moveDown(Duration duration);

  /// Moves a newly spawned entity in from the top of the screen.
  void moveInFromTop(Duration duration);

  /// The current position of the entity (top-left corner of its cell).
  Vector2 get position;
}

/// Data about a row movement of an entity,
/// including the [startingPosition] and [targetPosition].
class RowMovement {
  RowMovement({
    required this.startingPosition,
    required this.targetPosition,
    required this.totalSeconds,
  });

  final Vector2 startingPosition;
  final Vector2 targetPosition;
  final double totalSeconds;
  double elapsedSeconds = 0;

  late final Vector2 velocity =
      (targetPosition - startingPosition) / totalSeconds;

  bool get isFinished => elapsedSeconds >= totalSeconds;
}

/// Implements [RowEntity] movement for [BodyComponent]s
/// that don't need any extra animation hooks
/// (unlike `Monster`, which has its own implementation).
mixin RowEntityMovement on BodyComponent implements RowEntity {
  RowMovement? _rowMovement;

  @override
  void moveDown(Duration duration) {
    _startRowMovement(
      RowMovement(
        startingPosition: body.position.clone(),
        targetPosition: body.position + Vector2(0, rowMoveDownHeight),
        totalSeconds: duration.inMilliseconds / 1000,
      ),
    );
  }

  @override
  void moveInFromTop(Duration duration) {
    _startRowMovement(
      RowMovement(
        startingPosition: body.position.clone()..y -= rowMoveDownHeight,
        targetPosition: body.position.clone(),
        totalSeconds: duration.inMilliseconds / 1000,
      ),
    );
  }

  void _startRowMovement(RowMovement movement) {
    _rowMovement = movement;
    body
      ..setType(BodyType.kinematic)
      ..position.setFrom(movement.startingPosition)
      ..linearVelocity = movement.velocity;
  }

  /// Advances the current row movement, if any.
  /// Call this from the component's `update` method.
  void updateRowMovement(double dt) {
    final movement = _rowMovement;
    if (movement == null) return;

    movement.elapsedSeconds += dt;
    if (movement.isFinished) {
      body
        ..setType(BodyType.static)
        ..linearVelocity = Vector2.zero()
        ..position.setFrom(movement.targetPosition);
      _rowMovement = null;
    }
  }
}
