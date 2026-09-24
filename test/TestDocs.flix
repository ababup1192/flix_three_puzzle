// JSON 橋渡しのテスト（1 Doc につき最大 3 本まで。同型の重複は書かない）。
mod TestDocs {

    @Test
    def testRulesBrokenJsonFallsBackToDefaults(): Unit \ Assert =
        let doc = RulesDoc.fromJson("{ broken") |> Option.getWithDefault(RulesDoc.defaults());
        Assert.assertEq(expected = RulesDoc.defaults()#firstTurn, doc#firstTurn)

    @Test
    def testRulesReadsFirstTurn(): Unit \ Assert =
        let doc = RulesDoc.fromJson("{\"version\":1, \"firstTurn\": \"x\"}")
            |> Option.getWithDefault(RulesDoc.defaults());
        Assert.assertEq(expected = Board.Mark.X, doc#firstTurn)

    @Test
    def testRulesUnknownFirstTurnFallsBack(): Unit \ Assert =
        let doc = RulesDoc.fromJson("{\"firstTurn\": \"triangle\"}")
            |> Option.getWithDefault(RulesDoc.defaults());
        Assert.assertEq(expected = RulesDoc.defaults()#firstTurn, doc#firstTurn)

    @Test
    def testTextsOverridesOneFieldKeepsOthers(): Unit \ Assert =
        let doc = TextsDoc.fromJson("{\"draw\": \"TIE\"}")
            |> Option.getWithDefault(TextsDoc.defaults());
        Assert.assertEq(expected = ("TIE", TextsDoc.defaults()#winO), (doc#draw, doc#winO))

    @Test
    def testKeysBrokenFallsBack(): Unit \ Assert =
        Assert.assertEq(expected = true, Option.isEmpty(KeysDoc.fromJson("{oops")))

    @Test
    def testKeysDropsUnknownNameAndEmptyActionFallsBack(): Unit \ Assert =
        // 書き間違い("Sinistra")はその 1 個だけ落ちる。全部知らない名前で空になった
        // 操作(place)だけ既定へ落ち、触っていない操作(down)は既定のまま。
        let d = KeysDoc.fromJson("{\"left\": [\"Left\", \"Sinistra\"], \"place\": [\"Hop\"]}")
            |> Option.getWithDefault(KeysDoc.defaults());
        Assert.assertEq(
            expected = (GameEngine.Key.Left :: Nil, KeysDoc.defaults()#place, KeysDoc.defaults()#down),
            (d#left, d#place, d#down))
}
