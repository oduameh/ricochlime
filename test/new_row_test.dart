import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ricochlime/flame/components/gate.dart';
import 'package:ricochlime/flame/components/monster.dart';
import 'package:ricochlime/flame/ricochlime_game.dart';

void main() {
  group('New row generation', () {
    test('At least ${RicochlimeGame.minMonstersInRow} and '
        'at most ${Monster.monstersPerRow} monsters are generated', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await RicochlimeGame.instance.preloadSprites.future;

      final random = Random(12);
      expect(RicochlimeGame.minMonstersInRow, lessThan(Monster.monstersPerRow));

      for (var t = 0; t < 100; ++t) {
        final row = RicochlimeGame.createMonsterRow(
          random: random,
          monsterHp: 1,
          score: 1,
        );
        final monsters = row.whereType<Monster>();
        expect(
          monsters.length,
          greaterThanOrEqualTo(RicochlimeGame.minMonstersInRow),
        );
        expect(monsters.length, lessThanOrEqualTo(Monster.monstersPerRow));
      }
    });

    test('Every ${RicochlimeGame.gateRowEvery}th row is a gate row', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await RicochlimeGame.instance.preloadSprites.future;

      final random = Random(12);

      for (var score = 1; score <= 100; score++) {
        final row = RicochlimeGame.createNewRow(
          random: random,
          monsterHp: score,
          score: score,
        );
        final gates = row.whereType<Gate>();
        if (score % RicochlimeGame.gateRowEvery == 0) {
          expect(gates, isNotEmpty, reason: 'score $score should give gates');
          expect(row.whereType<Monster>(), isEmpty);
          for (final gate in gates) {
            expect(gate.multiplier, greaterThan(1));
          }
        } else {
          expect(gates, isEmpty, reason: 'score $score should not give gates');
        }
      }
    });
  });

  group('Number of new rows each round', () {
    test('at score 1-49', () {
      expect(RicochlimeGame.getNumNewRowsEachRound(1), 1);
      expect(RicochlimeGame.getNumNewRowsEachRound(49), 1);
      expect(RicochlimeGame.getNumNewRowsEachRound(50), isNot(1));
    });
    test('at score 50-149', () {
      expect(RicochlimeGame.getNumNewRowsEachRound(50), 2);
      expect(RicochlimeGame.getNumNewRowsEachRound(149), 2);
      expect(RicochlimeGame.getNumNewRowsEachRound(150), isNot(2));
    });
    test('at score 150-299', () {
      expect(RicochlimeGame.getNumNewRowsEachRound(150), 3);
      expect(RicochlimeGame.getNumNewRowsEachRound(299), 3);
      expect(RicochlimeGame.getNumNewRowsEachRound(300), isNot(3));
    });
  });
}
