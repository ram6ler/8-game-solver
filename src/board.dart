import 'dart:math' show Random;

const n = 3;
final rand = Random();

class Board {
  static const blank = n * n - 1;
  static int indexToRow(int index) => index ~/ n;
  static int indexToColumn(int index) => index % n;
  static int toIndex(int row, int column) => row * n + column;
  final List<int> tiles;
  Board(this.tiles);

  factory Board.from(Board that, int move) {
    final result = Board([for (final t in that.tiles) t])..heuristic();
    result.move(move);
    return result;
  }

  /// Moves tile with face value `tile`. Assumes `tile` is a valid move.
  void move(int tile) {
    final tileIndex = tiles.indexOf(tile), blankIndex = tiles.indexOf(blank);
    tiles[tileIndex] = blank;
    tiles[blankIndex] = tile;
    _heuristic = -1;
  }

  /// Returns the available moves as tile face values.
  List<int> validMoves() {
    final blankIndex = tiles.indexOf(blank),
        row = indexToRow(blankIndex),
        column = indexToColumn(blankIndex),
        moves = <int>[];

    for (var r = row - 1; r <= row + 1; r++) {
      if (r >= 0 && r < n) {
        for (var c = column - 1; c <= column + 1; c++) {
          if (c >= 0 && c < n) {
            if (r == row && c != column || r != row && c == column) {
              moves.add(tiles[toIndex(r, c)]);
            }
          }
        }
      }
    }
    return moves;
  }

  int _heuristic = -1;

  /// Sum of Manhattan distances to correct positions as
  ///  an optimistic estimate of number of moves required.
  int heuristic() {
    if (_heuristic == -1) {
      var s = 0;
      for (var position = 0; position < n * n; position++) {
        final faceValue = tiles[position];
        if (faceValue != blank) {
          final row = indexToRow(position),
              column = indexToColumn(position),
              r = indexToRow(faceValue),
              c = indexToColumn(faceValue);
          s += (row - r).abs() + (column - c).abs();
        }
      }
      _heuristic = s;
    }
    return _heuristic;
  }

  void shuffle() {
    for (var _ = 0; _ < 1000; _++) {
      final moves = validMoves();
      move(moves[rand.nextInt(moves.length)]);
    }
  }

  @override
  String toString() {
    final sb = StringBuffer();
    for (var i = 0; i < n * n; i++) {
      if (i % n == 0) sb.write("\n");
      if (tiles[i] == blank) {
        sb.write(".");
      } else {
        sb.write((tiles[i] + 1).toRadixString(16));
      }
    }
    sb.write("\n\n");
    return sb.toString();
  }

  @override
  bool operator ==(that) => that is Board && that.toString() == toString();
  @override
  int get hashCode => toString().hashCode;
}

class Node {
  Board state;
  Node? parent;
  int action;
  int g;
  Node(this.state, this.parent, this.action, this.g);
  @override
  String toString() => "g: $g, previous:\n$parent";
}

// Turn list into a priority queue...
extension _ on List<Node> {
  void insertInOrder(Node n) {
    var start = 0, end = this.length;
    while (start != end) {
      final index = (end + start) ~/ 2;
      if (this[index].g < n.g) {
        start = index + 1;
      } else {
        end = index;
      }
    }
    this.insert(start, n);
  }
}

List<Board> a_star_solve(Board board) {
  final node0 = Node(board, null, -1, 0),
      frontier = [node0],
      reached = {board: node0};

  late Node solution;
  while (frontier.isNotEmpty) {
    final best = frontier.first;
    frontier.remove(best);

    if (best.state.heuristic() == 0) {
      solution = best;
      break;
    }

    for (final move in best.state.validMoves()) {
      final nextBoard = Board.from(best.state, move);
      if (!reached.containsKey(nextBoard)) {
        final nextNode = Node(nextBoard, best, move, best.g + 1);
        reached[nextBoard] = nextNode;
        frontier.insertInOrder(nextNode);
      } else if (reached[nextBoard]!.g > best.g + 1) {
        reached[nextBoard]!
          ..parent = best
          ..g = best.g + 1;
        frontier.insertInOrder(reached[nextBoard]!);
      }
    }
  }
  final result = <Board>[];
  while (solution.state != board) {
    result.add(solution.state);
    solution = solution.parent!;
  }
  return [for (final board in result.reversed) board];
}
