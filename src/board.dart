import 'dart:math' show Random;

final debug = false;
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
  Board? previous;
  int g;
  Node([this.previous, int? g]) : this.g = g ?? 0;
  @override
  String toString() => "g: $g, previous:\n$previous";
}

List<Board> a_star_solve(Board board) {
  if (debug) {
    print("Solving:");
    print(board);
  }
  final visited = {board: Node(board, 0)}, frontier = {board};

  Board? solution;
  while (frontier.isNotEmpty) {
    final best = frontier.fold<Board>(
        frontier.first,
        (previousBoard, nextBoard) =>
            visited[previousBoard]!.g + previousBoard.heuristic() <
                    visited[nextBoard]!.g + nextBoard.heuristic()
                ? previousBoard
                : nextBoard);
    frontier.remove(best);
    final g = visited[best]!.g;

    if (debug) {
      print("-" * 50);
      print("In frontier: ${frontier.length}");
      print("Best:");
      print(best);
      print("Heuristic: ${best.heuristic()}");
      print("Recorded g: $g");
      print("-" * 50);
    }
    if (best.heuristic() == 0) {
      solution = best;
      break;
    }

    for (final move in best.validMoves()) {
      final nextBoard = Board.from(best, move);
      if (!visited.containsKey(nextBoard)) {
        visited[nextBoard] = Node(best, g + 1);
        frontier.add(nextBoard);
        if (debug) {
          print("Adding to frontier:");
          print(nextBoard);
          print("  Heuristic: ${nextBoard.heuristic()}");
          print("  Recording g: ${visited[nextBoard]!.g}");
        }
      } else if (visited[nextBoard]!.g > g + 1) {
        visited[nextBoard]!
          ..previous = best
          ..g = g + 1;
        frontier.add(nextBoard);
        if (debug) {
          print("Updating:");
          print(nextBoard);
          print("  Heuristic: ${nextBoard.heuristic()}");
          print("  Recording g: ${visited[nextBoard]!.g}");
        }
      }
    }
  }
  final result = <Board>[];
  while (solution != board) {
    if (debug) {
      print("Adding to solutions:");
      print(solution);
    }
    result.add(solution!);
    solution = visited[solution]!.previous;
  }
  return [for (final board in result.reversed) board];
}
