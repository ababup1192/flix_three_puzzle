// ThemeDoc — three_puzzle.theme.json（画面の 16 色）の宣言ドキュメント層と、スプライトの
// 意味色キーを実色に解決する resolver。
// 素材ごとに 暗 / 中 / 明 の 3 段 + 墨 1 色。画面に出る色はこの 16 色で全部で、
// コードで色を混ぜて新しい色を作らない（画風の「やらないこと」。AGENTS.local.md）。
// fail-open: 読めない・壊れているときは defaults() へ落とす。欄ごとに落ちる。
mod ThemeDoc {
    use Util.Json.Json

    pub type alias Doc = {
        version = Int32,
        ink = Color,
        bgDark = Color, bgMid = Color, bgLight = Color,
        barDark = Color, barMid = Color, barLight = Color,
        oDark = Color, oMid = Color, oLight = Color,
        xDark = Color, xMid = Color, xLight = Color,
        heroDark = Color, heroMid = Color, heroLight = Color
    }

    pub def path(): String = "assets/three_puzzle.theme.json"

    /// コード側の既定値（assets/three_puzzle.theme.json と同じ値から出発する）。
    pub def defaults(): Doc =
        let c = s -> Color.hex(s) |> Option.getWithDefault({ r = 1.0, g = 0.0, b = 1.0 });
        { version = 1,
          ink = c("#1b1537"),
          bgDark = c("#1f2a78"), bgMid = c("#2c43b0"), bgLight = c("#3d63d6"),
          barDark = c("#c79a52"), barMid = c("#f3dca2"), barLight = c("#fff8e6"),
          oDark = c("#a3172f"), oMid = c("#f23a3a"), oLight = c("#ff9e7a"),
          xDark = c("#b87800"), xMid = c("#ffc21a"), xLight = c("#fff08a"),
          heroDark = c("#137a4f"), heroMid = c("#2fc46e"), heroLight = c("#a6f5a0") }

    /// テキストから Doc へ（fail-open）。色の表記（#rrggbb）は UiDoc.colorOf に委ねる。
    pub def fromJson(text: String): Option[Doc] =
        DocJson.decodeObject(fromRoot, text)

    def fromRoot(root: Map[String, Json]): Doc =
        let d = defaults();
        let c = (key, fallback) -> colorOr(fallback, key, root);
        { version = JsonCodec.intOr("version", d#version, root),
          ink = c("ink", d#ink),
          bgDark = c("bgDark", d#bgDark), bgMid = c("bgMid", d#bgMid), bgLight = c("bgLight", d#bgLight),
          barDark = c("barDark", d#barDark), barMid = c("barMid", d#barMid), barLight = c("barLight", d#barLight),
          oDark = c("oDark", d#oDark), oMid = c("oMid", d#oMid), oLight = c("oLight", d#oLight),
          xDark = c("xDark", d#xDark), xMid = c("xMid", d#xMid), xLight = c("xLight", d#xLight),
          heroDark = c("heroDark", d#heroDark), heroMid = c("heroMid", d#heroMid),
          heroLight = c("heroLight", d#heroLight) }

    def colorOr(fallbackColor: Color, key: String, obj: Map[String, Json]): Color =
        Map.get(key, obj)
            |> Option.flatMap(json -> UiDoc.colorOf(Map.empty(), key, json) |> Result.toOption)
            |> Option.getWithDefault(fallbackColor)

    /// path の Doc を読む。読めない・壊れているときは defaults（fail-open）。
    pub def load(p: String): Doc \ Fs.FileRead =
        DocJson.loadOr(fromJson, defaults(), p)

    /// 1 つの素材の 暗 / 中 / 明。マーカーの色のように「どの素材か」が場面で変わる物に使う。
    pub type alias Ramp = { dark = Color, mid = Color, light = Color }

    pub def oRamp(d: Doc): Ramp = { dark = d#oDark, mid = d#oMid, light = d#oLight }
    pub def xRamp(d: Doc): Ramp = { dark = d#xDark, mid = d#xMid, light = d#xLight }
    pub def barRamp(d: Doc): Ramp = { dark = d#barDark, mid = d#barMid, light = d#barLight }

    /// スプライトの意味色キー → 実色。キーはテーマの欄の名前そのもの。
    /// 未知のキーはマゼンタ（描き忘れが目に見える）。
    pub def resolver(doc: Doc, key: String): Color =
        match key {
            case "ink"       => doc#ink
            case "bgDark"    => doc#bgDark
            case "bgMid"     => doc#bgMid
            case "bgLight"   => doc#bgLight
            case "barDark"   => doc#barDark
            case "barMid"    => doc#barMid
            case "barLight"  => doc#barLight
            case "oDark"     => doc#oDark
            case "oMid"      => doc#oMid
            case "oLight"    => doc#oLight
            case "xDark"     => doc#xDark
            case "xMid"      => doc#xMid
            case "xLight"    => doc#xLight
            case "heroDark"  => doc#heroDark
            case "heroMid"   => doc#heroMid
            case "heroLight" => doc#heroLight
            case _           => { r = 1.0, g = 0.0, b = 1.0 }
        }
}
