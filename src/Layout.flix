// Layout — 盤の置き場所（画面 480×300 の中の座標）。
// 値はラフ draft/sketch/screen/v1.json（16×11 セル・1 セル = 30×27.3px）の仕切り W の
// 列と行から写した物。縦の仕切りは 6・11 列目、横の仕切りは 4・8 行目の中心。
// 描く物（View）も主人公の立つ場所（World）もここから引く — 置き場所の定義を 1 か所にする。
// 座標はどれも偶数にそろえる。ドット絵を 2 倍で置くので、奇数に置くと画素の格子から外れる。
mod Layout {

    pub def width(): Float64 = 480.0
    pub def height(): Float64 = 300.0

    /// ドット絵の 1 画素 = 画面の何 px か。盤も背景もこの格子に乗せる。
    pub def pixel(): Int32 = 2

    /// 仕切りの太さ（px）。
    pub def barThickness(): Float64 = 12.0

    /// 縦の仕切り 2 本の中心 x と、横の仕切り 2 本の中心 y。
    pub def columnLines(): (Float64, Float64) = (166.0, 316.0)
    pub def rowLines(): (Float64, Float64) = (96.0, 206.0)

    /// 縦の仕切りの上端・下端（ラフでは画面の上から下まで通っている）。
    pub def columnSpan(): (Float64, Float64) = (8.0, 292.0)

    /// 横の仕切りの左端・右端（ラフでは両端 1 セルずつ空いている）。
    pub def rowSpan(): (Float64, Float64) = (30.0, 450.0)

    /// マス index（0〜8）の真ん中。3 列の中心 x と 3 行の中心 y は、隣り合う仕切りの間の中点。
    pub def cellCenter(index: Int32): Vec2.Vec2 =
        let (c1, c2) = columnLines();
        let (r1, r2) = rowLines();
        let (x0, x1) = rowSpan();
        let (y0, y1) = columnSpan();
        let xs = Vector#{ (x0 + c1) / 2.0, (c1 + c2) / 2.0, (c2 + x1) / 2.0 };
        let ys = Vector#{ (y0 + r1) / 2.0, (r1 + r2) / 2.0, (r2 + y1) / 2.0 };
        { x = snap(Vector.get(index `Int32.remainder` Board.size(), xs)),
          y = snap(Vector.get(index / Board.size(), ys)) }

    /// 主人公がマス index に立つときの足もと中央。マーカー（マスの真ん中）の右隣に立つ。
    pub def heroSpot(index: Int32): Vec2.Vec2 =
        let c = cellCenter(index);
        { x = c#x + 44.0, y = c#y + 22.0 }

    /// 画素の格子（2px）へ丸める。
    pub def snap(v: Float64): Float64 =
        let p = Int32.toFloat64(pixel());
        Float64.floor(v / p) * p
}
