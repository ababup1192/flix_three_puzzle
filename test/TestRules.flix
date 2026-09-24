// ルールと進行だけをテストする（方針どおり）。座標や描画はテストしない。
// 期待値はリテラルでなく Doc の既定値（RulesDoc.defaults）と Board の関数から導く。
mod TestRules {

    def w0(): World.World =
        World.initial(RulesDoc.defaults(), KeysDoc.defaults(), TextsDoc.defaults(),
            ThemeDoc.defaults(), PxSpriteDoc.empty())

    def first(): Board.Mark = RulesDoc.defaults()#firstTurn

    /// マス番号の順に、手番どおり交互に置く。
    def play(cells: List[Int32], w: World.World): World.World =
        cells |> List.foldLeft((acc, i) -> World.pressPlace(World.withCursor(i, acc)), w)

    @Test
    def testFirstTurnComesFromDoc(): Unit \ Assert =
        Assert.assertEq(expected = first(), w0()#turn)

    @Test
    def testPlacingPassesTheTurn(): Unit \ Assert =
        let w = play(4 :: Nil, w0());
        Assert.assertEq(expected = Board.nextTurn(first()), w#turn)

    @Test
    def testCannotPlaceOnFilledCell(): Unit \ Assert =
        // 同じマスに 2 回置こうとしても、2 回目は何も起きない（手番も進まない）。
        let once = play(4 :: Nil, w0());
        let twice = play(4 :: Nil, once);
        Assert.assertEq(expected = (once#board, once#turn), (twice#board, twice#turn))

    @Test
    def testThreeInARowWins(): Unit \ Assert =
        // 先手が上の横一列（0, 1, 2）を並べる。後手は下の段に置く。
        let w = play(0 :: 6 :: 1 :: 7 :: 2 :: Nil, w0());
        Assert.assertEq(expected = Board.Result.Won(first()), w#result)

    @Test
    def testDiagonalWins(): Unit \ Assert =
        let w = play(2 :: 0 :: 4 :: 1 :: 6 :: Nil, w0());
        Assert.assertEq(expected = Board.Result.Won(first()), w#result)

    @Test
    def testFullBoardWithoutLineIsDraw(): Unit \ Assert =
        let w = play(0 :: 1 :: 2 :: 4 :: 3 :: 5 :: 7 :: 6 :: 8 :: Nil, w0());
        Assert.assertEq(expected = Board.Result.Draw, w#result)

    @Test
    def testLastCellCompletingALineIsWinNotDraw(): Unit \ Assert =
        // 9 手目で盤が埋まると同時に並んだら、引き分けでなく勝ち。
        let w = play(0 :: 1 :: 2 :: 3 :: 4 :: 5 :: 7 :: 6 :: 8 :: Nil, w0());
        Assert.assertEq(expected = Board.Result.Won(first()), w#result)

    @Test
    def testNoMoreMarksAfterGameEnds(): Unit \ Assert =
        // 勝負がついた後に置くキーを押すと、置かずに空の盤から始め直す（先手は Doc から）。
        let ended = play(0 :: 6 :: 1 :: 7 :: 2 :: Nil, w0());
        let again = World.pressPlace(World.withCursor(8, ended));
        Assert.assertEq(expected = (Board.empty(), first(), Board.Result.Playing),
            (again#board, again#turn, again#result))

    @Test
    def testHeroStopsAtBoardEdge(): Unit \ Assert =
        // 左上の角からさらに左・上へ押しても、盤の外へは出ない。
        let corner = World.withCursor(0, w0());
        let w = World.step({ dx = -1, dy = -1, place = false }, 0.0, corner);
        Assert.assertEq(expected = 0, w#cursor)

    @Test
    def testHeroMovesOneCellPerPress(): Unit \ Assert =
        let w = World.step({ dx = 1, dy = 0, place = false }, 0.0, World.withCursor(0, w0()));
        Assert.assertEq(expected = Board.moveCursor(0, 1, 0), w#cursor)
}
