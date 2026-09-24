// Controls — キーを World.Input へ写し、World.step で 1 歩進める（純粋）。
// どのキーがどの操作かは KeysDoc（player.keys.json）が決める — 既定は
// ←→↑↓（矢印キー）と WASD で 1 マス動く、Space / Enter で置く。
// Doc の保存即反映（watchFile）と F1 一括リロードの読み直しもここに置く。
mod Controls {

    /// このフレームのキーを World.Input へ。1 回押すと 1 マス動く（押しっぱなしでは進まない）
    /// ので、「このフレームで新しく押されたか」（App.justPressed）で見る。
    /// 逆向きが同時なら打ち消して 0。
    pub def inputOf(frame: App.Frame, keys: KeysDoc.Doc): World.Input =
        let pressed = ks -> List.exists(k -> App.justPressed(k, frame), ks);
        let axis = (neg, pos) -> (if (pressed(pos)) 1 else 0) - (if (pressed(neg)) 1 else 0);
        { dx = axis(keys#left, keys#right),
          dy = axis(keys#up, keys#down),
          place = pressed(keys#place) }

    /// 毎フレームのシステム。
    pub def step(frame: App.Frame, w: World.World): World.World =
        World.step(inputOf(frame, w#keys), frame#dt, w)

    // ── Doc の読み直し（watchFile / F1） ──

    pub def reloadRules(w: World.World): World.World \ Fs.FileRead =
        World.withRules(RulesDoc.load(RulesDoc.path()), w)

    pub def reloadKeys(w: World.World): World.World \ Fs.FileRead =
        World.withKeys(KeysDoc.load(KeysDoc.path()), w)

    pub def reloadTexts(w: World.World): World.World \ Fs.FileRead =
        World.withTexts(TextsDoc.load(TextsDoc.path()), w)

    pub def reloadTheme(w: World.World): World.World \ Fs.FileRead =
        World.withTheme(ThemeDoc.load(ThemeDoc.path()), w)

    pub def reloadSprites(w: World.World): World.World \ Fs.FileRead =
        World.withSprites(PxSpriteDoc.load(World.spritePath()), w)

    /// Doc の一覧表(DocTable)。watchFile(保存即反映)・F1 の一括リロード・Studio へ名乗る
    /// 「表示中」の 3 つは、どれもこの 1 枚から導出する — 足し忘れで
    /// 「保存しても効かない」「印が付かない」を作らないため。
    /// docId は project.json の editor.resources[] の id と同じ物。
    /// 場面は盤 1 枚だけで、5 行とも常に画面に効いている。表紙などの場面が増えたら、
    /// 出ていない行に activeWhen を被せること（全部を常時 active にするとバッジの意味が死ぬ）。
    pub def docTable(): List[DocTable.Entry[World.World]] =
        DocTable.row("rules",  RulesDoc.path(),     reloadRules)
            :: DocTable.row("keys",   KeysDoc.path(),       reloadKeys)
            :: DocTable.row("texts",  TextsDoc.path(),      reloadTexts)
            :: DocTable.row("theme",  ThemeDoc.path(),      reloadTheme)
            :: DocTable.row("sprite", World.spritePath(),   reloadSprites)
            :: Nil

    /// App.game の reloads(保存即反映の watchFile)へ渡す形。
    pub def reloads(): List[(String, World.World -> World.World \ Fs.FileRead)] =
        DocTable.reloads(docTable())

    /// F1: 一覧表の順に Doc を全部読み直す。
    pub def reloadAll(w: World.World): World.World \ Fs.FileRead =
        DocTable.reloadAll(docTable(), w)

    /// いま画面に出ている Doc（Studio の「表示中」バッジの材料）。
    pub def activeDocs(w: World.World): List[(String, List[String])] =
        DocTable.activeDocs(docTable(), w)
}
