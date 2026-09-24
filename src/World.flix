// World — ゲームの状態そのものと、次の状態を作る規則（すべて純粋）。
// 三目並べ: 主人公を ←→↑↓ で 1 マスずつ動かし、Space で立っているマスに
// いまの手番のマーカーを置く。勝ち負けの判定は Board、置き場所は Layout、
// 先手と手触りの数値は RulesDoc、色は ThemeDoc、文字は TextsDoc、絵は PxSpriteDoc。
//
// ── 1 フレームの流れ（step）──
//   入力（Controls.inputOf が作る Input）
//     → 動く（moveHero: カーソルのマスを変え、主人公の移動 tween を始める）
//     → 置く（pressPlace: マーカーを置き、勝負の状態と手番を更新する）
//     → 時間を進める（advance: tween を進めて主人公の位置を書き込む）
//
// ── 場面の遷移 ──
//   Playing（O と X が交互に置く） → Won(O / X) か Draw → Space で Playing に戻る
mod World {

    /// このフレームの入力。dx / dy は -1 / 0 / +1（このフレームで押されたキーだけ）。
    pub type alias Input = { dx = Int32, dy = Int32, place = Bool }

    pub type alias World = {
        rules = RulesDoc.Doc,
        keys = KeysDoc.Doc,
        texts = TextsDoc.Doc,
        theme = ThemeDoc.Doc,
        sprites = PxSpriteDoc.Doc,
        // ドット絵を 1 枚にまとめたアトラスと、その画素から導いた鍵（下の bakedOf を参照）。
        atlas = PxSpriteAtlas.Baked,
        atlasKey = String,
        board = Vector[Board.Mark],      // 9 マスの中身（Board の番号の並び）
        turn = Board.Mark,               // いまの手番
        result = Board.Result,           // 勝負の状態
        cursor = Int32,                  // 主人公が立っているマスの番号（0〜8）
        heroPos = Vec2.Vec2,             // 主人公の足もと（画面座標。tween が動かす）
        tweens = EcsTween.Tweens[String, String],
        placedAt = Vector[Float64],      // マスごとの「置いた時刻」（まだなら -1。落ちてくる演出用）
        endedAt = Float64,               // 勝負がついた時刻（まだなら -1。帯の演出用）
        t = Float64,                     // 始まってからの秒数
        activeDocsWritten = String
    }

    pub def spritePath(): String = "assets/three_puzzle.sprite.json"

    /// ドット絵の拡大率（1 画素 = 何 px か）。Layout の格子と同じ値。
    pub def spriteScale(): Int32 = Layout.pixel()

    /// GPU に登録するアトラスの論理名（View の drawQuad と Main の withSpriteAtlases が
    /// この名前で待ち合わせる）。
    pub def atlasName(): String = "px"

    /// 主人公の移動 tween の鍵（EcsTween は「誰の・何を」の 2 つの組で tween を区別する）。
    def heroTween(): (String, String) = ("hero", "position")

    /// ドット絵を 1 枚のアトラスにまとめ、GPU キャッシュ用の鍵と対で返す。
    ///
    /// **なぜまとめるか**: 画面に出すとき 1 コマ = 1 クアッドで貼れる（PxSprite.drawQuad）。
    /// まとめずに描く PxSprite.draw は 1 コマを画素ぶんの四角に開くので、マーカーが 9 個
    /// 並ぶと組む数の桁が変わる（予算と検査は engine の docs/performance.md §9）。
    ///
    /// **なぜ鍵に画素のハッシュを混ぜるか**: Doc や色を保存し直して絵が変わったとき、
    /// 鍵が同じままだと GPU に古いテクスチャが残って画面が更新されない。
    def bakedOf(theme: ThemeDoc.Doc, sprites: PxSpriteDoc.Doc): (PxSpriteAtlas.Baked, String) =
        let baked = PxSpriteAtlas.bake(sprites, key -> ThemeDoc.resolver(theme, key));
        let h = baked#pixels |> Vector.foldLeft((acc, px) -> acc * 31 + px, 17);
        (baked, "${atlasName()}:${Int32.toString(baked#side)}:${Int32.toString(h)}")

    /// 色か絵が変わったときに、アトラスを作り直す（卓のフェルトの絵もここで足す）。
    /// 位置・時刻だけの更新はここを通らない。
    def withLook(theme: ThemeDoc.Doc, sprites: PxSpriteDoc.Doc, w: World): World =
        let withFelt = Backdrop.withFelt(sprites);
        let (baked, key) = bakedOf(theme, withFelt);
        { theme = theme, sprites = withFelt, atlas = baked, atlasKey = key | w }

    /// ゲーム開始時の状態。主人公は盤の真ん中のマスに立つ。
    pub def initial(rules: RulesDoc.Doc, keys: KeysDoc.Doc, texts: TextsDoc.Doc,
                    theme: ThemeDoc.Doc, sprites: PxSpriteDoc.Doc): World =
        let withFelt = Backdrop.withFelt(sprites);
        let (baked, key) = bakedOf(theme, withFelt);
        let center = Board.cellCount() / 2;
        newGame({
            rules = rules, keys = keys, texts = texts, theme = theme, sprites = withFelt,
            atlas = baked, atlasKey = key,
            board = Board.empty(), turn = rules#firstTurn, result = Board.Result.Playing,
            cursor = center, heroPos = Layout.heroSpot(center), tweens = Map.empty(),
            placedAt = Vector.empty(), endedAt = -1.0, t = 0.0, activeDocsWritten = "" })

    /// 盤を空にして、先手（RulesDoc）から始め直す。主人公はその場に残る。
    pub def newGame(w: World): World =
        { board = Board.empty(), turn = w#rules#firstTurn, result = Board.Result.Playing,
          placedAt = noTimes(), endedAt = -1.0 | w }

    /// 入力と経過時間から次の状態を作る（冒頭の「1 フレームの流れ」）。
    pub def step(input: Input, dt: Float64, w: World): World =
        let moved = if (input#dx != 0 or input#dy != 0) moveHero(input#dx, input#dy, w) else w;
        let placed = if (input#place) pressPlace(moved) else moved;
        advance(dt, placed)

    /// 主人公を隣のマスへ。盤の端では動かない（Board.moveCursor）。
    /// 画面上の位置はすぐには飛ばさず、moveSeconds かけて tween で滑らせる。
    pub def moveHero(dx: Int32, dy: Int32, w: World): World =
        let next = Board.moveCursor(w#cursor, dx, dy);
        if (next == w#cursor)
            w
        else {
            let track = EcsTween.Track.Vec({ start = w#heroPos, target = Layout.heroSpot(next) });
            let tweens = EcsTween.start(heroTween(), track, w#rules#moveSeconds,
                EcsTween.Easing.EaseOut, false, w#tweens);
            { cursor = next, tweens = tweens | w }
        }

    /// 置くキーが押されたとき。遊んでいる最中なら立っているマスにマーカーを置く
    /// （埋まっているマスには置けない）。勝負がついた後なら、もう一度始める。
    pub def pressPlace(w: World): World =
        match w#result {
            case Board.Result.Playing =>
                if (not Board.canPlace(w#cursor, w#board))
                    w
                else {
                    let board = Board.place(w#cursor, w#turn, w#board);
                    let result = Board.resultOf(board);
                    let isOver = result != Board.Result.Playing;
                    { board = board,
                      result = result,
                      turn = if (isOver) w#turn else Board.nextTurn(w#turn),
                      placedAt = setTime(w#cursor, w#t, w#placedAt),
                      endedAt = if (isOver) w#t else w#endedAt | w }
                }
            case _ => newGame(w)
        }

    /// 時間を dt 秒進める。主人公の tween を進め、出てきた位置を heroPos へ書き込む。
    def advance(dt: Float64, w: World): World =
        let (tweens, outs, _done) = EcsTween.step(dt, w#tweens);
        let heroPos = outs |> List.foldLeft((pos, entry) -> match entry {
            case (_, EcsTween.Out.VecOut(p)) => p
            case _ => pos
        }, w#heroPos);
        { tweens = tweens, heroPos = heroPos, t = w#t + dt | w }

    /// 主人公が移動の途中か（歩きのコマを出すかどうか）。
    pub def isHeroMoving(w: World): Bool =
        EcsTween.isActive(heroTween(), w#tweens)

    /// 主人公をマス index に置き直す（tween なし）。描き出しで場面を組むときに使う。
    pub def withCursor(index: Int32, w: World): World =
        { cursor = index, heroPos = Layout.heroSpot(index), tweens = Map.empty() | w }

    // ── 置いた時刻の表（9 マスぶん） ──

    def noTimes(): Vector[Float64] =
        region rc {
            let times = Array.repeat(rc, Board.cellCount(), -1.0);
            Array.toVector(times)
        }

    def setTime(index: Int32, time: Float64, times: Vector[Float64]): Vector[Float64] =
        region rc {
            let a = Vector.toArray(rc, times);
            Array.put(time, index, a);
            Array.toVector(a)
        }

    // ── Doc の差し替え（保存即反映） ──

    pub def withRules(rules: RulesDoc.Doc, w: World): World = { rules = rules | w }

    pub def withKeys(keys: KeysDoc.Doc, w: World): World = { keys = keys | w }

    pub def withTexts(texts: TextsDoc.Doc, w: World): World = { texts = texts | w }

    pub def withTheme(theme: ThemeDoc.Doc, w: World): World = withLook(theme, w#sprites, w)

    pub def withSprites(sprites: PxSpriteDoc.Doc, w: World): World = withLook(w#theme, sprites, w)
}
