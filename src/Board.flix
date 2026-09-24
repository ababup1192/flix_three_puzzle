// Board — 三目並べのルール（盤・置く・勝ち負け・引き分け）。
//
// 盤は 9 マスを 1 列に並べた配列。C で書く int board[9] と同じ並びで、番号は
//     0 | 1 | 2
//     3 | 4 | 5
//     6 | 7 | 8
// 列 = 番号 % 3、行 = 番号 / 3。
//
// 盤そのもの（Vector）は書き換えられない値なので、中身を変えるときは
// 「配列（Array）に写す → Array.put で 1 マス書き換える → 盤へ戻す」の 3 手で行う。
// 調べる処理は foreach のループと、書き換えられる変数（Ref）で数える — C の for 文と
// int のカウンタと同じ考え方。
// `region rc { ... }` は「この中で作った配列と Ref は、この括弧を出たら捨てる」という囲い。
mod Board {

    /// マスの中身。
    pub enum Mark with Eq, ToString {
        case Empty
        case O
        case X
    }

    /// 勝負の状態。Won の中身は勝ったマーカー。
    pub enum Result with Eq, ToString {
        case Playing
        case Won(Mark)
        case Draw
    }

    /// 盤の 1 辺のマス数（3×3）。
    pub def size(): Int32 = 3

    /// マスの総数。
    pub def cellCount(): Int32 = size() * size()

    /// 全部が空の盤。
    pub def empty(): Vector[Mark] =
        region rc {
            let cells = Array.repeat(rc, cellCount(), Mark.Empty);
            Array.toVector(cells)
        }

    /// 1 直線に並ぶ 3 マスの組（横 3 本・縦 3 本・斜め 2 本 = 8 本）。
    /// C なら int lines[8][3] と書く表。
    pub def lines(): List[Vector[Int32]] =
        Vector#{0, 1, 2} :: Vector#{3, 4, 5} :: Vector#{6, 7, 8} ::   // 横
        Vector#{0, 3, 6} :: Vector#{1, 4, 7} :: Vector#{2, 5, 8} ::   // 縦
        Vector#{0, 4, 8} :: Vector#{2, 4, 6} :: Nil                  // 斜め

    /// マス index に置けるか（盤の中で、まだ空いている）。
    pub def canPlace(index: Int32, board: Vector[Mark]): Bool =
        index >= 0 and index < cellCount() and Vector.get(index, board) == Mark.Empty

    /// マス index に mark を置いた盤。置けないときは盤をそのまま返す。
    pub def place(index: Int32, mark: Mark, board: Vector[Mark]): Vector[Mark] =
        if (not canPlace(index, board))
            board
        else
            region rc {
                let cells = Vector.toArray(rc, board);
                Array.put(mark, index, cells);
                Array.toVector(cells)
            }

    /// 同じマーカーが 3 つ並んだ列を探す。見つかればその 3 マスの番号を返す。
    pub def winLineOf(board: Vector[Mark]): Option[Vector[Int32]] =
        region rc {
            let found = Ref.fresh(rc, None);
            foreach (line <- lines()) {
                let first = Vector.get(Vector.get(0, line), board);
                let second = Vector.get(Vector.get(1, line), board);
                let third = Vector.get(Vector.get(2, line), board);
                let isLine = first != Mark.Empty and first == second and first == third;
                if (isLine and Option.isEmpty(Ref.get(found)))
                    Ref.put(Some(line), found)
                else
                    ()
            };
            Ref.get(found)
        }

    /// 3 つ並べたマーカー（まだ誰も並べていなければ None）。
    pub def winnerOf(board: Vector[Mark]): Option[Mark] =
        match winLineOf(board) {
            case Some(line) => Some(Vector.get(Vector.get(0, line), board))
            case None       => None
        }

    /// 9 マス全部が埋まったか。
    pub def isFull(board: Vector[Mark]): Bool =
        region rc {
            let filled = Ref.fresh(rc, 0);
            foreach (i <- List.range(0, cellCount())) {
                if (Vector.get(i, board) != Mark.Empty)
                    Ref.put(Ref.get(filled) + 1, filled)
                else
                    ()
            };
            Ref.get(filled) == cellCount()
        }

    /// 盤から勝負の状態を決める。並びを先に見る —
    /// 最後の 1 マスで 3 つ並んだときは、埋まっていても引き分けでなく勝ち。
    pub def resultOf(board: Vector[Mark]): Result =
        match winnerOf(board) {
            case Some(mark) => Result.Won(mark)
            case None       => if (isFull(board)) Result.Draw else Result.Playing
        }

    /// 次の手番（O の次は X、X の次は O）。
    pub def nextTurn(mark: Mark): Mark =
        match mark {
            case Mark.O     => Mark.X
            case Mark.X     => Mark.O
            case Mark.Empty => Mark.Empty
        }

    /// マス index から (dx, dy) だけ隣へ動いたマス。盤の端では止まる。
    pub def moveCursor(index: Int32, dx: Int32, dy: Int32): Int32 =
        let col = Num.clampInt(0, size() - 1, (index `Int32.remainder` size()) + dx);
        let row = Num.clampInt(0, size() - 1, index / size() + dy);
        row * size() + col
}
