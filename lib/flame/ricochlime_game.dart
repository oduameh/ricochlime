import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Block;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:forge2d/src/settings.dart' as physics_settings;
import 'package:logging/logging.dart';
import 'package:ricochlime/flame/components/background/background.dart';
import 'package:ricochlime/flame/components/block.dart';
import 'package:ricochlime/flame/components/bullet.dart';
import 'package:ricochlime/flame/components/gate.dart';
import 'package:ricochlime/flame/components/monster.dart';
import 'package:ricochlime/flame/components/player.dart';
import 'package:ricochlime/flame/components/row_entity.dart';
import 'package:ricochlime/flame/components/walls.dart';
import 'package:ricochlime/flame/game_data.dart';
import 'package:ricochlime/flame/ticker.dart';
import 'package:ricochlime/pages/game_over.dart';
import 'package:ricochlime/utils/ricochlime_audio.dart';
import 'package:ricochlime/utils/ricochlime_palette.dart';
import 'package:ricochlime/utils/shop_items.dart';
import 'package:ricochlime/utils/stows.dart';

enum GameState { idle, shooting, monstersMoving, gameOver }

class RicochlimeGame extends Forge2DGame
    with PanDetector, TapCallbacks, SingleGameInstance {
  RicochlimeGame._() : super(gravity: Vector2.zero(), zoom: 1) {
    /// Sets the maximum movement per time step to [Bullet.speed].
    /// This effectively sets the max time step to 1s,
    /// rather than the default value which is much lower.
    physics_settings.maxTranslation = Bullet.speed;
  }

  static final instance = RicochlimeGame._();
  static final log = Logger('RicochlimeGame');

  /// Width to height aspect ratio
  static const aspectRatio = 0.6;

  static const expectedWidth = 128.0;
  static const expectedHeight = expectedWidth / aspectRatio;

  /// How long the player auto-fires before the rows advance.
  static const shootingPhaseSecs = 4.0;

  /// The delay between volleys during the shooting phase.
  static const volleyIntervalSecs = 0.9;

  /// The maximum number of bullets allowed on screen at once.
  /// Gate clones beyond this limit are dropped.
  static const maxBullets = 300;

  /// Every [gateRowEvery]th row is a row of multiplier gates
  /// instead of a row of monsters/blocks.
  static const gateRowEvery = 4;

  late final ValueNotifier<GameState> state = ValueNotifier(.idle)
    ..addListener(() {
      if (state.value != .shooting) {
        timeDilation.value = 1.0;
      }
    });

  late final player = Player();
  late final background = Background();
  late final audio = RicochlimeAudio();
  bool get inputAllowed => state.value == .idle;
  bool inputCancelled = false;

  late var random = Random();

  static final score = ValueNotifier(0);
  static final isDarkMode = ValueNotifier(false);
  int numBullets = 1;
  int numNewRowsEachRound = 1;

  final Ticker ticker = Ticker();
  static final timeDilation = ValueNotifier<double>(1);

  Future<GameOverAction> Function()? showGameOverDialog;

  /// A completer that completes when all the sprites are loaded.
  late final preloadSprites = () {
    final completer = Completer<bool>();
    Future.wait([
      Background.preloadSprites(game: this),
      MonsterAnimation.preloadSprites(game: this),
      Player.preloadSprites(game: this),
      ShopItems.preloadSprites(game: this),
    ]).then((_) => completer.complete(true));
    return completer;
  }();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    assert(
      size.x.round() == expectedWidth.round(),
      'Expected width: $expectedWidth but got: ${size.x}',
    );
    assert(
      size.y.round() == expectedHeight.round(),
      'Expected height: $expectedHeight but got: ${size.y}',
    );

    add(background);

    createBoundaries(
      expectedWidth,
      expectedHeight,
      includeBottom: false,
    ).forEach(add);

    add(player);

    await stows.currentGame.waitUntilRead();
    importFromGame(stows.currentGame.value);
  }

  /// Reduces sprite animations to make golden tests more predictable.
  /// If true, certain animations will just show the first frame.
  static bool reproducibleGoldenMode = false;

  /// Whether the user has the "Reduce motion" accessibility setting enabled.
  /// Not to be confused with [reproducibleGoldenMode] which turns off sprite
  /// animations and doesn't reduce moving elements.
  static bool reduceMotion = false;

  /// Imports the game state from [data], or resets the game if [data] is null.
  ///
  /// If [showGameOverDialog] is true, the game over dialog will be shown
  /// if [isGameOver] returns true.
  void importFromGame(GameData? data, {bool showGameOverDialog = true}) {
    if (data == null) {
      // new game
      _reset();
      return;
    }

    int numMonstersThatGiveBullets = 0;
    bool topGapNeedsAdjusting = false;
    for (final monsterJson in data.monsters) {
      final monster = Monster.fromJson(monsterJson);
      add(monster);

      if (monster.killReward == .bullet) numMonstersThatGiveBullets++;
      if (monster.position.y <= 0) topGapNeedsAdjusting = true;
    }

    if (topGapNeedsAdjusting) {
      // the top gap needs adjusting because the monsters were imported from a
      // previous version of the game
      for (final monster in children.whereType<Monster>()) {
        monster.position.y += Monster.topGap;
      }
    }

    for (final blockJson in data.blocks) {
      add(Block.fromJson(blockJson));
    }
    for (final gateJson in data.gates) {
      add(Gate.fromJson(gateJson));
    }

    score.value = data.score;
    numBullets = 1 + score.value - numMonstersThatGiveBullets;
    assert(numBullets >= 1);
    assert(numBullets <= score.value);
    numNewRowsEachRound = getNumNewRowsEachRound(score.value);

    if (showGameOverDialog && isGameOver()) {
      if (reproducibleGoldenMode) {
        gameOver();
      } else {
        // allow the game to render before showing the game over dialog
        Future.delayed(const Duration(milliseconds: 200), gameOver);
      }
    } else {
      state.value = .idle;
      _startRoundsLoop();
    }
  }

  Future saveGame() async {
    final entities = children.whereType<RowEntity>().toList();
    assert(
      entities.any((entity) => entity.position.y <= Monster.topGap),
      'The new row of entities should be spawned before saving the game',
    );
    final monsters = children.whereType<Monster>().toList();
    if (monsters.any((monster) => monster.isRagdolling)) {
      log.warning('Not saving game because the monsters are ragdolling');
      return;
    }

    stows.currentGame.value = GameData(
      score: score.value,
      monsters: monsters.where((monster) => !monster.isDead),
      blocks: children.whereType<Block>().where((block) => !block.isDead),
      gates: children.whereType<Gate>(),
    );
    await stows.currentGame.waitUntilWritten();
  }

  Future<void> cancelCurrentTurn() async {
    if (inputAllowed) return;

    inputCancelled = true;
    while (!inputAllowed) {
      // wait for the current turn to cancel gracefully
      await ticker.delayed(const Duration(milliseconds: 50));
    }
    assert(!inputCancelled);

    resetChildren();
    importFromGame(stows.currentGame.value);
  }

  /// Clears the current bullets and row entities
  @visibleForTesting
  void resetChildren() {
    removeWhere((component) => component is Bullet);
    removeWhere((component) => component is Monster);
    removeWhere((component) => component is MonsterAnimation);
    removeWhere((component) => component is Block);
    removeWhere((component) => component is Gate);
    _bulletCloneQueue.clear();
  }

  @override
  Color backgroundColor() => isDarkMode.value
      ? RicochlimePalette.waterColorDark
      : RicochlimePalette.waterColor;

  /// If the user wants to limit the frame rate to e.g. 30fps,
  /// this is used to sum up the dt values
  /// and only update the game when the sum is greater than 1/30.
  double groupedUpdateDt = 0;
  static const maxDt = 0.5;

  static final _fpsStreamController = StreamController<int>.broadcast();
  static final fpsStream = _fpsStreamController.stream;

  static int get fps => _fps;
  static int _fps = 0;
  static set fps(int fps) {
    if (fps == _fps) return;
    _fps = fps;
    if (_fpsStreamController.hasListener) _fpsStreamController.add(fps);
  }

  @override
  // ignore: must_call_super (super.update is called in [updateNow])
  void update(double dt) {
    if (dt > maxDt) {
      groupedUpdateDt = 0;
      fps = 0;
      // physics engine can't handle such a big dt, so just skip this frame
      return;
    }

    if (stows.maxFps.value <= 0) {
      // unlimited fps, don't group updates
      updateNow(dt, timeDilation.value);
      return;
    }

    final targetDt = 1 / stows.maxFps.value;

    groupedUpdateDt += dt;
    // *0.9 so e.g. 16ms is treated like 16.6666...ms
    if (groupedUpdateDt < targetDt * 0.9) return;
    updateNow(groupedUpdateDt, timeDilation.value);
    // may go below 0 to compensate for rounding errors
    groupedUpdateDt = min(groupedUpdateDt - targetDt, 0);
  }

  void updateNow(double dt, double timeDilation) {
    if (stows.showFpsCounter.value) fps = (1 / max(dt, 1 / 999)).round();
    dt = min(dt * timeDilation, maxDt);
    _spawnQueuedBulletClones();
    ticker.tick(dt);
    super.update(dt);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // slide the player left/right
    player.position.x = (player.position.x + info.delta.global.x).clamp(
      wallInset + Player.staticWidth / 2,
      expectedWidth - wallInset - Player.staticWidth / 2,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (state.value == .shooting) {
      timeDilation.value += 0.5;
    }
  }

  bool _roundsLoopRunning = false;

  /// Starts the rounds loop if it's not already running.
  ///
  /// Does nothing in [reproducibleGoldenMode] so that
  /// golden tests stay deterministic.
  void _startRoundsLoop() {
    if (reproducibleGoldenMode) return;
    unawaited(_runRoundsLoop());
  }

  /// The main game loop:
  /// auto-fire for a while, then advance the rows, and repeat.
  Future<void> _runRoundsLoop() async {
    if (_roundsLoopRunning) return;
    _roundsLoopRunning = true;
    try {
      while (state.value != .gameOver) {
        if (inputCancelled) return;
        await _shootingPhase();
        if (inputCancelled) return;
        if (state.value == .gameOver) return;
        await spawnNewMonsters();
      }
    } finally {
      _roundsLoopRunning = false;
      inputCancelled = false;
      if (state.value != .gameOver) {
        state.value = .idle;
      }
    }
  }

  /// Fires volleys of bullets for [shootingPhaseSecs] seconds.
  Future<void> _shootingPhase() async {
    state.value = .shooting;

    var elapsedSeconds = 0.0;
    var secondsSinceVolley = volleyIntervalSecs; // fire immediately
    await for (final dt in ticker.onTick) {
      if (inputCancelled) return;
      elapsedSeconds += dt;
      secondsSinceVolley += dt;

      if (secondsSinceVolley >= volleyIntervalSecs) {
        secondsSinceVolley = 0;
        unawaited(_fireVolley());
      }

      if (elapsedSeconds >= shootingPhaseSecs) return;
    }
  }

  /// Fires [numBullets] bullets straight up from the player's position.
  Future<void> _fireVolley() async {
    player.attack();

    final bulletY =
        player.position.y - Player.staticHeight / 2 - Bullet.radius - 0.5;
    for (var i = 0; i < numBullets; i++) {
      if (inputCancelled) return;
      if (state.value == .gameOver) return;
      if (children.whereType<Bullet>().length >= maxBullets) return;

      // fan the bullets out slightly
      final spread = (i - (numBullets - 1) / 2) * 0.03;
      add(
        Bullet(
          // follow the player if they're mid-drag
          initialPosition: Vector2(player.position.x, bulletY),
          direction: Vector2(spread, -1)..normalize(),
        ),
      );

      if (i < numBullets - 1) {
        await ticker.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  final _bulletCloneQueue =
      <
        ({Vector2 position, Vector2 direction, Set<Object> consumedGates})
      >[];

  /// Called when a [bullet] passes through a [gate].
  ///
  /// Each bullet family can only use each gate once.
  /// The extra bullets are queued and spawned on the next update,
  /// since bodies can't be created during a contact callback.
  void onBulletPassedThroughGate(Gate gate, Bullet bullet) {
    if (!bullet.consumedGates.add(gate)) return;

    final extraBullets = switch (gate.type) {
      .multiply => gate.multiplier - 1,
      .add => gate.multiplier,
    };
    if (extraBullets <= 0) return;

    final baseDirection = bullet.body.linearVelocity.normalized();
    for (var i = 1; i <= extraBullets; i++) {
      // fan the clones out slightly
      final angle = (i.isEven ? 1 : -1) * 0.06 * ((i + 1) ~/ 2);
      _bulletCloneQueue.add((
        position: bullet.body.position.clone(),
        direction: baseDirection.clone()..rotate(angle),
        consumedGates: bullet.consumedGates,
      ));
    }
  }

  void _spawnQueuedBulletClones() {
    while (_bulletCloneQueue.isNotEmpty) {
      final request = _bulletCloneQueue.removeAt(0);
      if (children.whereType<Bullet>().length >= maxBullets) continue;
      add(
        Bullet(
          initialPosition: request.position,
          direction: request.direction,
          consumedGates: request.consumedGates,
        ),
      );
    }
  }

  /// Moves the existing entities down and spawns new ones at the top
  Future<void> spawnNewMonsters() async {
    const monsterMoveDuration = Duration(seconds: 1);

    state.value = .monstersMoving;

    // move entities down and spawn new ones at the top
    assert(numNewRowsEachRound == getNumNewRowsEachRound(score.value));
    for (int i = 0; i < numNewRowsEachRound; ++i) {
      // move existing entities down
      for (final entity in children.whereType<RowEntity>()) {
        entity.moveDown(monsterMoveDuration);
      }

      // spawn new entities at the top
      score.value++;
      final row = createNewRow(
        random: random,
        monsterHp: score.value,
        score: score.value,
      );
      for (final entity in row.nonNulls) {
        add(entity as Component);
      }

      // wait until all entities are loaded
      await Future.wait(
        row.nonNulls.map((entity) => (entity as Component).loaded),
      );
      if (inputCancelled) return;

      // move the new entities in from the top
      for (final entity in row.nonNulls) {
        entity.moveInFromTop(monsterMoveDuration);
      }

      // wait for the entities to move
      await ticker.delayed(
        monsterMoveDuration,
        onTick: () => inputCancelled ? .stopEarly : null,
      );
      if (inputCancelled) return;

      // gates that reach the player just disappear
      final threshold = player.bottomY - Monster.staticHeight * 2;
      for (final gate in children.whereType<Gate>()) {
        if (gate.position.y >= threshold) {
          gate.removeFromParent();
        }
      }

      // check if the player has lost
      if (isGameOver()) {
        stows.totalGameOvers.value++;
        unawaited(saveGame());
        unawaited(gameOver());
        return;
      }
    }
    numNewRowsEachRound = getNumNewRowsEachRound(score.value);
    state.value = .idle;

    await saveGame();
  }

  bool isGameOver() {
    final threshold = player.bottomY - Monster.staticHeight * 2;
    return children.whereType<Monster>().any(
          (monster) => monster.position.y >= threshold,
        ) ||
        children.whereType<Block>().any(
          (block) => block.position.y >= threshold,
        );
  }

  Future<void> gameOver() async {
    state.value = .gameOver;
    assert(!inputAllowed);

    // all monsters drop down
    bool startedRagdolling = false;
    for (final monster in children.whereType<Monster>()) {
      if (monster.isRagdolling) continue;
      startedRagdolling = true;
      monster.startRagdoll();
    }
    if (startedRagdolling) await ticker.delayed(const Duration(seconds: 2));

    final gameOverAction = showGameOverDialog == null
        ? GameOverAction.nothingYet
        : await showGameOverDialog!.call();
    log.info('gameOverAction: $gameOverAction');

    switch (gameOverAction) {
      case .nothingYet:
        // do nothing
        break;
      case .continueGame:
        state.value = .monstersMoving;
        importFromGame(stows.currentGame.value, showGameOverDialog: false);

        final totalRowsToRemove = max(
          // clears 3 rounds worth of entities
          // plus the one that killed the player
          numNewRowsEachRound * 3 + 1,
          // or at least 5 rows
          5,
        );
        try {
          for (
            int numRowsToRemove = 0;
            numRowsToRemove < totalRowsToRemove;
            ++numRowsToRemove
          ) {
            final threshold =
                player.bottomY - numRowsToRemove * Monster.staticHeight;
            log.info(
              'Removing row $numRowsToRemove out of $totalRowsToRemove '
              '(entities with y > $threshold)',
            );

            bool removedAnyEntities = false;
            for (final monster in children.whereType<Monster>()) {
              if (monster.position.y > threshold) {
                removedAnyEntities = true;
                monster.hp = 0;
              }
            }
            for (final block in children.whereType<Block>()) {
              if (block.position.y > threshold) {
                removedAnyEntities = true;
                block.hp = 0;
              }
            }
            for (final gate in children.whereType<Gate>()) {
              if (gate.position.y > threshold) {
                removedAnyEntities = true;
                gate.removeFromParent();
              }
            }

            if (removedAnyEntities && numRowsToRemove < totalRowsToRemove - 1) {
              await ticker.delayed(const Duration(milliseconds: 500));
            }
          }

          await saveGame();
        } finally {
          state.value = .idle;
        }
      case .restartGame:
        restartGame();
    }
  }

  /// Restarts the game:
  /// Saves the high score,
  /// and clears the current game.
  void restartGame() {
    stows.highScore.value = max(stows.highScore.value, score.value);
    stows.currentGame.value = null;
    _reset();
  }

  /// Resets the game:
  /// sets the score to zero,
  /// and spawns a single row of monsters.
  Future<void> _reset() async {
    // cancel any currently running rounds loop
    inputCancelled = true;
    while (_roundsLoopRunning) {
      await ticker.delayed(const Duration(milliseconds: 50));
    }

    state.value = .idle;
    inputCancelled = false;
    score.value = 0;
    numBullets = 1;
    numNewRowsEachRound = 1;
    resetChildren();
    try {
      await spawnNewMonsters();
    } finally {
      inputCancelled = false;
      if (state.value != .gameOver) {
        state.value = .idle;
        _startRoundsLoop();
      }
    }
  }

  @visibleForTesting
  static int getNumNewRowsEachRound(int score) {
    const int roundsBeforeIncreasingRows = 50;
    int numNewRows = 1;
    int maxScoreInRow = numNewRows * roundsBeforeIncreasingRows;
    while (score >= maxScoreInRow) {
      numNewRows++;
      maxScoreInRow += numNewRows * roundsBeforeIncreasingRows;
    }
    return numNewRows;
  }

  @visibleForTesting
  static int minMonstersInRow = 2;

  /// Creates a new row of entities:
  /// a row of multiplier gates every [gateRowEvery] rows,
  /// otherwise a row of monsters and blocks.
  @visibleForTesting
  static List<RowEntity?> createNewRow({
    required Random random,
    required int monsterHp,
    required int score,
  }) {
    if (score % gateRowEvery == 0) {
      return createGateRow(random: random);
    }
    return createMonsterRow(random: random, monsterHp: monsterHp, score: score);
  }

  /// Creates a row of 2-3 multiplier gates, each spanning 2 columns.
  @visibleForTesting
  static List<RowEntity?> createGateRow({required Random random}) {
    final row = List<RowEntity?>.filled(Monster.monstersPerRow, null);

    final slots = List.generate(Monster.monstersPerRow ~/ 2, (i) => i)
      ..shuffle(random);
    final numGates = 2 + random.nextInt(2); // 2 or 3 gates
    for (var i = 0; i < numGates && i < slots.length; i++) {
      final column = slots[i] * 2;
      final (type, multiplier) = switch (random.nextInt(10)) {
        0 || 1 || 2 || 3 => (GateType.multiply, 2),
        4 || 5 || 6 => (GateType.add, 3),
        7 || 8 => (GateType.multiply, 3),
        _ => (GateType.add, 5),
      };
      row[column] = Gate(
        initialPosition: Vector2(Monster.staticWidth * column, Monster.topGap),
        columns: 2,
        type: type,
        multiplier: multiplier,
      );
    }

    return row;
  }

  /// Creates a row of monsters and blocks.
  @visibleForTesting
  static List<RowEntity?> createMonsterRow({
    required Random random,
    required int monsterHp,
    required int score,
  }) {
    final occupied = List.filled(Monster.monstersPerRow, false);
    for (var i = 0; i < Monster.monstersPerRow; i++) {
      occupied[i] = random.nextDouble() < 0.3;
    }
    while (occupied.where((e) => e).length < minMonstersInRow) {
      occupied[random.nextInt(occupied.length)] = true;
    }

    // the chance of an occupied cell being a block
    // (instead of a monster) grows with the score
    final blockProbability = min(0.5, 0.15 + score / 200);

    Vector2 positionOf(int column) =>
        Vector2(Monster.staticWidth * column, Monster.topGap);

    Monster newMonster(int column) =>
        Monster(initialPosition: positionOf(column), maxHp: monsterHp);

    final row = <RowEntity?>[
      for (var i = 0; i < occupied.length; i++)
        if (!occupied[i])
          null
        else if (random.nextDouble() < blockProbability)
          Block(initialPosition: positionOf(i), maxHp: monsterHp * 2)
        else
          newMonster(i),
    ];

    // make sure there are enough monsters to hand out the kill rewards
    while (row.whereType<Monster>().length < minMonstersInRow) {
      final i = random.nextInt(row.length);
      row[i] = newMonster(i);
    }

    // hand out the kill rewards to random monsters
    final monsterIndices = [
      for (var i = 0; i < row.length; i++)
        if (row[i] is Monster) i,
    ]..shuffle(random);
    (row[monsterIndices[0]]! as Monster).killReward = .bullet;
    (row[monsterIndices[1]]! as Monster).killReward = .coin;

    // Note: If you're adding new rewards, make sure to update
    // [minMonstersInRow] to avoid an infinite loop.

    return row;
  }

  @override
  @Deprecated('RicochlimeGame is never expected to be disposed')
  void dispose() {
    _fpsStreamController.close();
    inputCancelled = true;
  }
}
