import 'package:ricochlime/flame/components/block.dart';
import 'package:ricochlime/flame/components/gate.dart';
import 'package:ricochlime/flame/components/monster.dart';

class GameData {
  GameData({
    required this.score,
    required Iterable<Monster> monsters,
    Iterable<Block> blocks = const [],
    Iterable<Gate> gates = const [],
  }) : monsters = monsters.map((monster) => monster.toJson()).toList(),
       blocks = blocks.map((block) => block.toJson()).toList(),
       gates = gates.map((gate) => gate.toJson()).toList();

  GameData.fromJson(Map<String, dynamic> json)
    : score = json['score'] as int,
      monsters = ((json['monsters'] ?? json['slimes']) as List)
          .cast<Map<String, dynamic>>(),
      blocks =
          ((json['blocks'] as List?) ?? const [])
              .cast<Map<String, dynamic>>(),
      gates =
          ((json['gates'] as List?) ?? const []).cast<Map<String, dynamic>>();

  final int score;

  /// The result of calling [monster.toJson] on each monster in the game.
  final List<Map<String, dynamic>> monsters;

  /// The result of calling [block.toJson] on each block in the game.
  final List<Map<String, dynamic>> blocks;

  /// The result of calling [gate.toJson] on each gate in the game.
  final List<Map<String, dynamic>> gates;

  Map<String, dynamic> toJson() => {
    'score': score,
    'monsters': monsters,
    'blocks': blocks,
    'gates': gates,
  };
}
