// Backdrop — 盤の下に敷く卓のフェルト。色は bgDark / bgMid / bgLight の 3 段だけで、
// 間は Bayer のディザ（4×4 の敷居と比べて、明るい色の点を置く割合を変える）でつなぐ。
// 明るさは左上のランプからの距離で決める（盤の光も左上から当たっているので、それにそろえる）。
//
// 画面ぶんの点を 1 枚のドット絵（"felt" スプライト）として組み、他のドット絵と同じ
// アトラスに入れる。こうすると画面に出すときは 1 クアッドで済む — 点ごとに四角を組む
// PxTerrain.fill だと 3 万個を超える四角になり、描き出しが数分かかった。
// 組むのは色か絵が変わったときの 1 回だけ（World.withLook）。
// 敷居の作り方は engine の PxTerrain.bayer4（解説は engine の docs/module-index.md）。
mod Backdrop {

    /// アトラスの中での名前。
    pub def spriteName(): String = "felt"

    /// ランプの位置（画面の左上の外寄り）と、明かりが届く距離（px）。
    def lamp(): Vec2.Vec2 = { x = 90.0, y = 20.0 }
    def reach(): Float64 = 470.0

    /// 暗 → 中 → 明 の 3 段に割り当てる文字と、その意味色キー（テーマの欄の名前）。
    def shades(): Vector[(Char, String)] =
        Vector#{ ('0', "bgDark"), ('1', "bgMid"), ('2', "bgLight") }

    /// sprites にフェルトの絵を足した Doc。legend にも 3 段の文字を足す。
    pub def withFelt(sprites: PxSpriteDoc.Doc): PxSpriteDoc.Doc =
        let legend = shades() |> Vector.foldLeft((m, entry) -> {
            let (ch, key) = entry;
            Map.insert(ch, key, m)
        }, sprites#legend);
        let felt = { frames = Map#{ "idle" => rows() } | PxSpriteDoc.emptySprite() };
        { legend = legend, sprites = Map.insert(spriteName(), felt, sprites#sprites) | sprites }

    /// 画面を 2px の升目に割った格子の各マスに、3 段のどれを置くか。
    def rows(): List[String] =
        let p = Layout.pixel();
        let cols = Num.floorInt(Layout.width()) / p;
        let lines = Num.floorInt(Layout.height()) / p;
        List.range(0, lines) |> List.map(y ->
            List.range(0, cols)
                |> List.map(x -> Char.toString(shadeAt(x, y, p)))
                |> List.join(""))

    /// 升目 (x, y) の文字。明るさ 0〜1 を 3 段の間の位置に直し、端数が敷居を超えたら
    /// 1 段明るい色にする — 色を増やさずに、段と段の間を点の割合で見せる。
    def shadeAt(x: Int32, y: Int32, p: Int32): Char =
        let center = { x = Int32.toFloat64(x * p + p / 2), y = Int32.toFloat64(y * p + p / 2) };
        let steps = Vector.length(shades()) - 1;
        let level = brightnessAt(center) * Int32.toFloat64(steps);
        let base = Num.floorInt(level);
        let up = if (level - Int32.toFloat64(base) > PxTerrain.bayer4(x, y)) 1 else 0;
        let index = Num.clampInt(0, steps, base + up);
        let (ch, _) = Vector.get(index, shades());
        ch

    /// 0（暗い）〜 1（明るい）。ランプに近いほど明るい。
    def brightnessAt(p: Vec2.Vec2): Float64 =
        Num.clamp01(1.0 - Vec2.distanceTo(p, lamp()) / reach())
}
