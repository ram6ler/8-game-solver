import 'dart:html';
import "board.dart";

class BoardWidget {
  final widgetDiv = DivElement(),
      heuristicDiv = DivElement()..classes.add("heuristic"),
      boardDiv = DivElement()..classes.add("board"),
      thinking = DivElement()..classes.add("thinking");
  late final List<DivElement> tileDiv;
  late final ButtonElement shuffle, solve;
  var isInteractive = true;
  Board board;

  BoardWidget(this.board) {
    tileDiv = [
      for (var i = 0; i < n * n; i++)
        DivElement()
          ..classes.add("tile")
          ..onClick.listen((_) {
            userMove(i);
          })
    ];
    boardDiv.children = tileDiv;
    update();

    shuffle = ButtonElement()
      ..innerHtml = "Shuffle!"
      ..onClick.listen((_) {
        if (isInteractive) {
          board.shuffle();
          update();
        }
      });

    solve = ButtonElement()
      ..innerHtml = "Solve!"
      ..onClick.listen((_) {
        if (isInteractive) {
          isInteractive = false;
          shuffle.style.visibility = "hidden";
          solve.style.visibility = "hidden";
          thinking.innerHtml = "Thinking about it...";
          Future.delayed(Duration.zero).then((_) {
            final solution = a_star_solve(board);
            showSolution(solution);
          });
        }
      });

    widgetDiv.children = [
      boardDiv,
      heuristicDiv,
      thinking,
      shuffle,
      solve,
    ];
  }

  void update() {
    for (var i = 0; i < n * n; i++) {
      if (board.tiles[i] == Board.blank) {
        tileDiv[i].classes.add("blank");
        tileDiv[i].innerHtml = "";
      } else {
        tileDiv[i].classes.remove("blank");
        tileDiv[i].innerHtml = "${board.tiles[i] + 1}";
      }
    }
    heuristicDiv.innerHtml = "Heuristic: ${board.heuristic()}";
  }

  void userMove(int index) {
    final tile = board.tiles[index];
    if (board.validMoves().contains(tile)) {
      board.move(tile);
      update();
    }
  }

  void showSolution(List<Board> solution) {
    thinking.innerHtml = "";
    if (solution.isEmpty) {
      isInteractive = true;
      shuffle.style.visibility = "visible";
      solve.style.visibility = "visible";
      return;
    }
    board = solution.first;
    update();
    Future.delayed(Duration(milliseconds: 500))
        .then((_) => showSolution(solution.sublist(1)));
  }
}

main() {
  final boardContainer = querySelector("#board-container")! as DivElement,
      board = Board([for (var i = 0; i < n * n; i++) i]),
      boardWidget = BoardWidget(board);

  boardContainer.children = [boardWidget.widgetDiv];
}
