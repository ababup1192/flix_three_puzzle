// RulesDoc — three_puzzle.rules.json（先手と手触りの数値）の宣言ドキュメント層。
// Doc は「どちらから始めるか・何秒で動くか」まで。勝ち負けの判定はコード（Board）側。
// fail-open — 読めない・壊れているときは defaults() へ落とし、ゲームは必ず起動する。
mod RulesDoc {
    use Util.Json.Json

    pub type alias Doc = {
        version = Int32,
        firstTurn = Board.Mark,   // 先手のマーカー（JSON では "o" / "x"）
        moveSeconds = Float64,    // 主人公が隣のマスへ移る時間（秒）
        dropHeight = Float64      // 置いたマーカーが落ちてくる高さ（px）
    }

    pub def path(): String = "assets/three_puzzle.rules.json"

    /// コード側の既定値（assets/three_puzzle.rules.json と同じ値から出発する）。
    pub def defaults(): Doc =
        { version = 1, firstTurn = Board.Mark.O, moveSeconds = 0.14, dropHeight = 14.0 }

    /// テキストから Doc へ（fail-open）。JSON でない・形が違うフィールドは既定へ落とす。
    pub def fromJson(text: String): Option[Doc] =
        DocJson.decodeObject(fromRoot, text)

    def fromRoot(root: Map[String, Json]): Doc =
        let d = defaults();
        { version = JsonCodec.intOr("version", d#version, root),
          firstTurn = markOr(d#firstTurn, root),
          moveSeconds = JsonCodec.floatOr("moveSeconds", d#moveSeconds, root),
          dropHeight = JsonCodec.floatOr("dropHeight", d#dropHeight, root) }

    /// "o" / "x" を読み込みの 1 回だけ Board.Mark へ変える（内側は文字列で持たない）。
    /// それ以外の綴りは既定へ落とす。
    def markOr(fallback: Board.Mark, root: Map[String, Json]): Board.Mark =
        match JsonCodec.stringOr("firstTurn", "", root) |> String.toLowerCase {
            case "o" => Board.Mark.O
            case "x" => Board.Mark.X
            case _   => fallback
        }

    /// path の Doc を読む。読めない・壊れているときは defaults（fail-open）。
    pub def load(p: String): Doc \ Fs.FileRead =
        DocJson.loadOr(fromJson, defaults(), p)
}
