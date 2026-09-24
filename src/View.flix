// View — World から「(置き場所, 見せたい物) のリスト」への投影（純粋）。
//
// 画風（AGENTS.local.md）: 藍のフェルトの卓に置いたブリキのおもちゃ盤。粗いドット絵・
// 16 色・墨のくっきりした輪郭。色はテーマの 16 色だけで、半透明で混ぜた色を作らない
// （影もディザの市松で打つ）。光は左上から。
//
// ── 画面の層（奥から手前へ）──
//    0  backdrop … 卓のフェルト（ディザで 3 段）          → 面に階調
//    2  shadow   … 仕切り・マーカー・主人公の落ち影        → 物が卓に載って見える
//    4  cursor   … 主人公が立つマスの四隅（点滅）          → 時間が流れる・いま選んでいるマス
//    6  bars     … 仕切り（ブリキの板。明・中・暗 + 墨）   → 盤の形
//    8  markers  … O / X（置くと上から落ちて弾む）          → 主役
//    9  sparks   … 勝った列のまわりのきらめき              → 時間が流れる
//   10  hero     … 主人公と、頭上の「いまの手番」の印      → 主役
//   12  hud      … 左上の手番のラベル・勝負がついた帯          → 手前（文字は TextsDoc）
mod View {

    def zBackdrop(): Int32 = 0
    def zShadow(): Int32 = 2
    def zCursor(): Int32 = 4
    def zBar(): Int32 = 6
    def zMarker(): Int32 = 8
    def zSpark(): Int32 = 9
    def zHero(): Int32 = 10
    def zHud(): Int32 = 12

    pub def frame(ctx: App.ViewCtx, w: World.World): List[Render.PlacedItem] =
        backdrop(w)
            |> List.append(bars(w))
            |> List.append(cursor(w))
            |> List.append(markers(w))
            |> List.append(sparks(w))
            |> List.append(hero(w))
            |> List.append(hud(ctx, w))

    // ── 小物 ──

    def scale(): Int32 = World.spriteScale()

    /// スプライト 1 コマを左上 at に置く（アトラスから 1 クアッド）。
    def sprite(w: World.World, name: String, frameName: String, at: Vec2.Vec2, z: Int32): List[Render.PlacedItem] =
        PxSprite.drawQuad(w#sprites, w#atlas, World.atlasName(), name, frameName,
            { x = Layout.snap(at#x), y = Layout.snap(at#y) }, false, scale(), z)

    /// スプライトの大きさ（px）。読めないときは 0（置き場所の計算だけずれる）。
    def spriteSize(w: World.World, name: String): Vec2.Vec2 =
        PxSprite.sizeOf(w#sprites, name, "idle", scale()) |> Option.getWithDefault({ x = 0.0, y = 0.0 })

    def rect(at: Vec2.Vec2, size: Vec2.Vec2, color: Color, z: Int32): Render.PlacedItem =
        { at = at, item = RawDraw.box(size, color, z) }

    def rampOf(w: World.World, mark: Board.Mark): ThemeDoc.Ramp =
        match mark {
            case Board.Mark.O => ThemeDoc.oRamp(w#theme)
            case Board.Mark.X => ThemeDoc.xRamp(w#theme)
            case Board.Mark.Empty => ThemeDoc.barRamp(w#theme)
        }

    // ── 0. 卓のフェルト ──

    /// 画面いっぱいの 1 枚絵（Backdrop が組んでアトラスに入れた物）。
    def backdrop(w: World.World): List[Render.PlacedItem] =
        sprite(w, Backdrop.spriteName(), "idle", { x = 0.0, y = 0.0 }, zBackdrop())

    // ── 6. 仕切り（と 2. その落ち影） ──

    /// 縦 2 本・横 2 本。縦の板を手前に重ねる（交わる所で横の板の上を縦の板が渡る）。
    def bars(w: World.World): List[Render.PlacedItem] =
        let half = Layout.barThickness() / 2.0;
        let (c1, c2) = Layout.columnLines();
        let (r1, r2) = Layout.rowLines();
        let (x0, x1) = Layout.rowSpan();
        let (y0, y1) = Layout.columnSpan();
        let horizontal = cy -> plate(w, { x = x0, y = cy - half },
            { x = x1 - x0, y = Layout.barThickness() }, false, zBar());
        let vertical = cx -> plate(w, { x = cx - half, y = y0 },
            { x = Layout.barThickness(), y = y1 - y0 }, true, zBar() + 1);
        horizontal(r1) ::: horizontal(r2) ::: vertical(c1) ::: vertical(c2)

    /// ブリキの板 1 枚: 墨の縁 → 中の面 → 光の側（左か上）に明るい 2px・影の側に暗い 2px。
    /// 落ち影は右下へ 4px ずらした墨の市松（半分だけ点を打って、下のフェルトを透かす）。
    def plate(w: World.World, at: Vec2.Vec2, size: Vec2.Vec2, isVertical: Bool, z: Int32): List[Render.PlacedItem] =
        let r = ThemeDoc.barRamp(w#theme);
        let p = Int32.toFloat64(Layout.pixel());
        let edge = p;
        let lightStrip = if (isVertical) { x = edge, y = size#y } else { x = size#x, y = edge };
        let darkAt = if (isVertical) { x = at#x + size#x - edge, y = at#y } else { x = at#x, y = at#y + size#y - edge };
        let shadow = { at = { x = at#x + 2.0 * p, y = at#y + 2.0 * p },
                       item = RawDraw.box({ x = size#x + p, y = size#y + p }, w#theme#ink, zShadow())
                           |> Render.checker({ color = w#theme#bgDark, alpha = 1.0, cell = p }) };
        shadow
            :: rect({ x = at#x - p, y = at#y - p }, { x = size#x + 2.0 * p, y = size#y + 2.0 * p }, w#theme#ink, z)
            :: rect(at, size, r#mid, z)
            :: rect(at, lightStrip, r#light, z)
            :: rect(darkAt, lightStrip, r#dark, z)
            :: Nil

    // ── 4. 主人公が立つマスの四隅 ──

    /// 遊んでいる最中だけ出す。色はいまの手番の素材で、明と中を交互に切り替えて点滅させる
    /// （半透明にせず、パレットの 2 色を行き来する）。
    def cursor(w: World.World): List[Render.PlacedItem] =
        if (w#result != Board.Result.Playing) Nil
        else {
            let r = rampOf(w, w#turn);
            let color = if (Curve.tri(0.9, w#t) > 0.5) r#light else r#mid;
            let c = Layout.cellCenter(w#cursor);
            let half = 30.0;
            let len = 12.0;
            let thick = 4.0;
            let corner = (sx, sy) -> {
                let cx = c#x + sx * half;
                let cy = c#y + sy * half;
                let hx = if (sx < 0.0) cx else cx - len;
                let vy = if (sy < 0.0) cy else cy - len;
                let hy = if (sy < 0.0) cy else cy - thick;
                let vx = if (sx < 0.0) cx else cx - thick;
                rect({ x = hx - 2.0, y = hy - 2.0 }, { x = len + 4.0, y = thick + 4.0 }, w#theme#ink, zCursor())
                    :: rect({ x = vx - 2.0, y = vy - 2.0 }, { x = thick + 4.0, y = len + 4.0 }, w#theme#ink, zCursor())
                    :: rect({ x = hx, y = hy }, { x = len, y = thick }, color, zCursor() + 1)
                    :: rect({ x = vx, y = vy }, { x = thick, y = len }, color, zCursor() + 1)
                    :: Nil
            };
            corner(-1.0, -1.0) ::: corner(1.0, -1.0) ::: corner(-1.0, 1.0) ::: corner(1.0, 1.0)
        }

    // ── 8. マーカー ──

    /// 置いた瞬間は dropHeight だけ上にいて、減衰するバネで弾みながら落ち着く。
    /// 勝った列の 3 つは、勝負がついた後ぴょこぴょこ跳ね続ける。
    def markers(w: World.World): List[Render.PlacedItem] =
        let winLine = Board.winLineOf(w#board) |> Option.map(Vector.toList) |> Option.getWithDefault(Nil);
        List.range(0, Board.cellCount()) |> List.flatMap(i -> {
            let mark = Vector.get(i, w#board);
            let (name, shadowName) = match mark {
                case Board.Mark.O => ("markO", "shadowO")
                case Board.Mark.X => ("markX", "shadowX")
                case Board.Mark.Empty => ("", "")
            };
            if (mark == Board.Mark.Empty) Nil
            else {
                let size = spriteSize(w, name);
                let c = Layout.cellCenter(i);
                let age = w#t - Vector.get(i, w#placedAt);
                let drop = if (age < 0.0) 0.0 else Curve.dampedSpring(w#rules#dropHeight, 7.0, 16.0, age);
                let hop = if (List.memberOf(i, winLine))
                    6.0 * Float64.max(0.0, Sway.wave(w#t, Int32.toFloat64(i) * 0.12, 7.0))
                    else 0.0;
                let topLeft = { x = c#x - size#x / 2.0, y = c#y - size#y / 2.0 - drop - hop };
                let ground = { x = c#x - size#x / 2.0 + 4.0, y = c#y - size#y / 2.0 + 4.0 };
                sprite(w, shadowName, "idle", ground, zShadow())
                    ::: sprite(w, name, "idle", topLeft, zMarker())
            }
        })

    // ── 9. 勝った列のまわりのきらめき ──

    /// 粒はどこにも保存せず、番号と時刻だけから計算する（何度描き出しても同じ絵）。
    /// 1 粒は十字の 2 枚の板で、瞬く間だけ出す（半透明にしない）。
    def sparks(w: World.World): List[Render.PlacedItem] =
        match (Board.winLineOf(w#board), w#result) {
            case (Some(line), Board.Result.Won(mark)) =>
                let r = rampOf(w, mark);
                Fx.derive(24, w#t, (i, rand, t) -> {
                    let c = Layout.cellCenter(Vector.get(i `Int32.remainder` 3, line));
                    let x = Layout.snap(c#x + (rand(0) - 0.5) * 100.0);
                    let y = Layout.snap(c#y + (rand(1) - 0.5) * 80.0);
                    let phase = Num.wrapTo(1.0, t * (0.8 + rand(2)) + rand(3));
                    let big = rand(4) > 0.6;
                    let arm = if (big) 6.0 else 4.0;
                    let color = if (phase < 0.25) r#light else r#mid;
                    if (phase > 0.45) Nil
                    else
                        rect({ x = x - arm, y = y - 1.0 }, { x = arm * 2.0, y = 2.0 }, color, zSpark())
                            :: rect({ x = x - 1.0, y = y - arm }, { x = 2.0, y = arm * 2.0 }, color, zSpark())
                            :: Nil
                }) |> List.flatten
            case _ => Nil
        }

    // ── 10. 主人公 ──

    /// 足もと heroPos に立たせる。待っている間は idle / step を 0.5 秒ごとに入れ替えて
    /// 呼吸させ、移動中は速く入れ替えて歩かせる。頭の上には「いまの手番」の小さい印。
    def hero(w: World.World): List[Render.PlacedItem] =
        let size = spriteSize(w, "hero");
        let rate = if (World.isHeroMoving(w)) 10.0 else 2.0;
        let frameName = if (Num.floorInt(w#t * rate) `Int32.remainder` 2 == 0) "idle" else "step";
        let topLeft = { x = w#heroPos#x - size#x / 2.0, y = w#heroPos#y - size#y };
        let shadowSize = spriteSize(w, "shadowHero");
        let shadow = sprite(w, "shadowHero", "idle",
            { x = w#heroPos#x - shadowSize#x / 2.0 + 2.0, y = w#heroPos#y - shadowSize#y / 2.0 }, zShadow());
        let body = sprite(w, "hero", frameName, topLeft, zHero());
        let badge = if (w#result != Board.Result.Playing) Nil
            else {
                let name = if (w#turn == Board.Mark.O) "miniO" else "miniX";
                let bs = spriteSize(w, name);
                let bob = 2.0 * Float64.round(Sway.wave(w#t, 0.0, 3.0));
                sprite(w, name, "idle",
                    { x = w#heroPos#x - bs#x / 2.0, y = topLeft#y - bs#y - 4.0 + bob }, zHero())
            };
        shadow ::: body ::: badge

    // ── 12. 手前のラベルと帯（文字はすべて TextsDoc から） ──

    def hud(ctx: App.ViewCtx, w: World.World): List[Render.PlacedItem] =
        match w#result {
            case Board.Result.Playing =>
                let label = if (w#turn == Board.Mark.O) w#texts#turnO else w#texts#turnX;
                let size = 10.0;
                let width = Layout.snap(TextDraw.width(label, ctx#atlas, size) + 20.0);
                let at = { x = 8.0, y = 6.0 };
                let box = { x = width, y = 20.0 };
                panel(w, at, box, rampOf(w, w#turn))
                    ::: centeredText(ctx, w, label, size, { x = at#x + box#x / 2.0, y = at#y + box#y / 2.0 })
            case result =>
                let (headline, ramp) = match result {
                    case Board.Result.Won(Board.Mark.X) => (w#texts#winX, rampOf(w, Board.Mark.X))
                    case Board.Result.Won(_)            => (w#texts#winO, rampOf(w, Board.Mark.O))
                    case _                              => (w#texts#draw, rampOf(w, Board.Mark.Empty))
                };
                // 帯は横の仕切り（下側）の上にかぶせる — マーカーの並ぶ所を隠さない。
                let (_, r2) = Layout.rowLines();
                let age = w#t - w#endedAt;
                let pop = if (age < 0.0) 0.0 else Curve.dampedSpring(10.0, 6.0, 14.0, age);
                let box = { x = 240.0, y = 40.0 };
                let at = { x = Layout.width() / 2.0 - box#x / 2.0, y = Layout.snap(r2 - box#y / 2.0 - pop) };
                panel(w, at, box, ramp)
                    ::: centeredText(ctx, w, headline, 16.0, { x = at#x + box#x / 2.0, y = at#y + 14.0 })
                    ::: centeredText(ctx, w, w#texts#again, 7.0, { x = at#x + box#x / 2.0, y = at#y + 31.0 })
        }

    /// ラベルの板: 墨の縁 2px・中の面・上に明るい 2px・下に暗い 2px（内側のベベル）。
    def panel(w: World.World, at: Vec2.Vec2, size: Vec2.Vec2, r: ThemeDoc.Ramp): List[Render.PlacedItem] =
        rect({ x = at#x + 4.0, y = at#y + 4.0 }, size, w#theme#ink, zHud())
            :: rect({ x = at#x - 2.0, y = at#y - 2.0 }, { x = size#x + 4.0, y = size#y + 4.0 }, w#theme#ink, zHud())
            :: rect(at, size, r#mid, zHud())
            :: rect(at, { x = size#x, y = 2.0 }, r#light, zHud())
            :: rect({ x = at#x, y = at#y + size#y - 2.0 }, { x = size#x, y = 2.0 }, r#dark, zHud())
            :: Nil

    def centeredText(ctx: App.ViewCtx, w: World.World, text: String, size: Float64, center: Vec2.Vec2): List[Render.PlacedItem] =
        TextDraw.centeredAt({ text = text, atlas = ctx#atlas, size = size, color = w#theme#ink,
                              z = zHud() + 1, center = center }) :: Nil
}
