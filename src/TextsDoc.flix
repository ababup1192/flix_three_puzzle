// TextsDoc — three_puzzle.texts.json（画面に出る文字）の宣言ドキュメント層。
// プレイヤーの目に入る文字はここだけに置く（コードに表示文字列を直書きしない）。
// fail-open — 読めない・壊れているときは defaults() へ落とす。欄ごとに落ちる。
mod TextsDoc {
    use Util.Json.Json

    pub type alias Doc = {
        version = Int32,
        turnO = String,   // 左上のラベル: O の番
        turnX = String,   // 左上のラベル: X の番
        winO = String,    // 帯: O の勝ち
        winX = String,    // 帯: X の勝ち
        draw = String,    // 帯: 引き分け
        again = String    // 帯の下の案内: もう一度遊ぶ操作
    }

    pub def path(): String = "assets/three_puzzle.texts.json"

    /// コード側の既定値（assets/three_puzzle.texts.json と同じ値から出発する）。
    pub def defaults(): Doc =
        { version = 1, turnO = "O TURN", turnX = "X TURN", winO = "O WINS!", winX = "X WINS!",
          draw = "DRAW", again = "SPACE: PLAY AGAIN" }

    /// テキストから Doc へ（fail-open）。
    pub def fromJson(text: String): Option[Doc] =
        DocJson.decodeObject(fromRoot, text)

    def fromRoot(root: Map[String, Json]): Doc =
        let d = defaults();
        let s = (key, fallback) -> JsonCodec.stringOr(key, fallback, root);
        { version = JsonCodec.intOr("version", d#version, root),
          turnO = s("turnO", d#turnO), turnX = s("turnX", d#turnX),
          winO = s("winO", d#winO), winX = s("winX", d#winX),
          draw = s("draw", d#draw), again = s("again", d#again) }

    /// path の Doc を読む。読めない・壊れているときは defaults（fail-open）。
    pub def load(p: String): Doc \ Fs.FileRead =
        DocJson.loadOr(fromJson, defaults(), p)
}
