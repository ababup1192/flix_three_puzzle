// Board（ルールの部品）を 1 関数ずつテストする。
// 盤は 9 文字の文字列で書く: 'O' / 'X' / '.'（空）。左上から右へ、行が終わったら次の行へ
// （Board の番号 0〜8 と同じ並び）。
mod TestBoard {
    use Board.Mark

    /// "OX.O....." のような 9 文字から盤を作る。
    def boardOf(cells: String): Vector[Mark] =
        cells
            |> String.toList
            |> List.map(ch -> match ch {
                case 'O' => Mark.O
                case 'X' => Mark.X
                case _   => Mark.Empty
            })
            |> List.toVector

    // ── canPlace: 置けるか ──

    @Test
    def testCanPlaceOnEmptyCell(): Unit \ Assert =
        Assert.assertEq(expected = true, Board.canPlace(4, Board.empty()))

    @Test
    def testCannotPlaceOnFilledCell(): Unit \ Assert =
        Assert.assertEq(expected = false, Board.canPlace(4, boardOf("....X....")))

    @Test
    def testCannotPlaceOutsideBoard(): Unit \ Assert =
        Assert.assertEq(expected = (false, false),
            (Board.canPlace(-1, Board.empty()), Board.canPlace(Board.cellCount(), Board.empty())))

    // ── place: 置く ──

    @Test
    def testPlacePutsMarkAtIndex(): Unit \ Assert =
        Assert.assertEq(expected = boardOf("..O......"), Board.place(2, Mark.O, Board.empty()))

    @Test
    def testPlaceKeepsOriginalBoard(): Unit \ Assert =
        // 置いた盤は新しく作られ、元の盤は空のまま。
        let before = Board.empty();
        let after = Board.place(2, Mark.O, before);
        Assert.assertEq(expected = (Board.empty(), boardOf("..O......")), (before, after))

    @Test
    def testPlaceOnFilledCellChangesNothing(): Unit \ Assert =
        let board = boardOf("X........");
        Assert.assertEq(expected = board, Board.place(0, Mark.O, board))

    // ── winLineOf / winnerOf: 3 つ並んだか ──

    @Test
    def testNoLineOnEmptyBoard(): Unit \ Assert =
        Assert.assertEq(expected = None, Board.winLineOf(Board.empty()))

    @Test
    def testFindsRow(): Unit \ Assert =
        Assert.assertEq(expected = Some(Vector#{3, 4, 5}), Board.winLineOf(boardOf("O.OXXXO..")))

    @Test
    def testFindsColumn(): Unit \ Assert =
        Assert.assertEq(expected = Some(Vector#{1, 4, 7}), Board.winLineOf(boardOf("XO..OX.O.")))

    @Test
    def testFindsDiagonal(): Unit \ Assert =
        Assert.assertEq(expected = Some(Vector#{2, 4, 6}), Board.winLineOf(boardOf("O.X.XOX..")))

    @Test
    def testMixedMarksAreNotALine(): Unit \ Assert =
        // 上の行は O・O・X で、そろっていない。
        Assert.assertEq(expected = None, Board.winLineOf(boardOf("OOX......")))

    @Test
    def testWinnerIsTheMarkOnTheLine(): Unit \ Assert =
        Assert.assertEq(expected = Some(Mark.X), Board.winnerOf(boardOf("O.X.XOX..")))

    // ── isFull: 9 マス埋まったか ──

    @Test
    def testEmptyBoardIsNotFull(): Unit \ Assert =
        Assert.assertEq(expected = false, Board.isFull(Board.empty()))

    @Test
    def testEightMarksIsNotFull(): Unit \ Assert =
        Assert.assertEq(expected = false, Board.isFull(boardOf("OXOXXOOX.")))

    @Test
    def testNineMarksIsFull(): Unit \ Assert =
        Assert.assertEq(expected = true, Board.isFull(boardOf("OXOXXOOXO")))

    // ── resultOf: 勝負の状態 ──

    @Test
    def testResultPlayingWhileOpen(): Unit \ Assert =
        Assert.assertEq(expected = Board.Result.Playing, Board.resultOf(boardOf("OX.......")))

    @Test
    def testResultWonWhenLined(): Unit \ Assert =
        Assert.assertEq(expected = Board.Result.Won(Mark.O), Board.resultOf(boardOf("OOOXX....")))

    @Test
    def testResultDrawWhenFullWithoutLine(): Unit \ Assert =
        Assert.assertEq(expected = Board.Result.Draw, Board.resultOf(boardOf("OXOOXXXOO")))

    @Test
    def testResultWonBeatsFull(): Unit \ Assert =
        // 埋まっていても、並んでいれば引き分けでなく勝ち。
        Assert.assertEq(expected = Board.Result.Won(Mark.O), Board.resultOf(boardOf("OXOXOXXOO")))

    // ── nextTurn: 手番の交代 ──

    @Test
    def testNextTurnAlternates(): Unit \ Assert =
        Assert.assertEq(expected = (Mark.X, Mark.O), (Board.nextTurn(Mark.O), Board.nextTurn(Mark.X)))

    // ── moveCursor: 隣のマスへ ──

    @Test
    def testMoveRight(): Unit \ Assert =
        Assert.assertEq(expected = 5, Board.moveCursor(4, 1, 0))

    @Test
    def testMoveDown(): Unit \ Assert =
        Assert.assertEq(expected = 7, Board.moveCursor(4, 0, 1))

    @Test
    def testMoveStopsAtLeftEdge(): Unit \ Assert =
        // 左端の列（3）からさらに左へは行かない。1 つ上の行の右端（2）へ回り込まない。
        Assert.assertEq(expected = 3, Board.moveCursor(3, -1, 0))

    @Test
    def testMoveStopsAtCorner(): Unit \ Assert =
        Assert.assertEq(expected = 8, Board.moveCursor(8, 1, 1))
}
