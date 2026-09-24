// エントリーポイント。Doc は App を組む前に読み、その値から初期 World を作る
// （壊れていても defaults で必ず起動する）。App の中でファイルを読むのは F1 の reloadOn と
// 保存検知（watchFile）だけ。外の世界に触れる処理（effect）は隠さず with で並べる。
//
// ── ゲームループの全体像（App.game の 1 レコード）──
// ここを読めば「何から始まり・毎フレームどう進み・どう絵になり・保存で何を読み直すか」が掴める。
//   init    = 出発点の World（初期状態: 空の盤・先手の番・主人公は真ん中のマス）。
//   update  = 毎フレームの更新（入力 → 次の状態）。キーを読むのは Controls.step、
//             動く・置く・勝ち負けを決めるのは World.step（ルールの芯は Board）。1 本の合成関数で渡す決まり —
//             複数のシステムは `w |> step(f) |> …` と中で繋いでから渡す（繋ぎが Main に見える）。
//   view    = World → 「何をどこに描くか」（View.frame）。World は読むだけで変えない。
//   reloads = 保存で読み直す Doc（各 1 本の watchFile に展開される）。
// 場面の遷移: 遊ぶ（Playing） → 勝ち / 引き分け（Won / Draw） → Space で遊ぶへ戻る。
// どこで切り替わるかは World.pressPlace。
// 音（withAudio）や複数システムの明示的な列挙が要る高度なゲームは、make から始める従来の
// ビルダー（addSystem / withView / …）へ降りる。App.game の外側で足す設定（reloadOn・onRenderRequest・
// withDebug）は戻り値の App に後ろから pipe で足す。

def main(): Unit \ IO =
    if (GameEngine.ensureMainThread()) ()
    else {
        run {
            let rules = RulesDoc.load(RulesDoc.path());
            let keys = KeysDoc.load(KeysDoc.path());
            let texts = TextsDoc.load(TextsDoc.path());
            let theme = ThemeDoc.load(ThemeDoc.path());
            let sprites = PxSpriteDoc.load(World.spritePath());
            App.game({
                init = World.initial(rules, keys, texts, theme, sprites),
                // 入力を読み World.step で次の状態へ → 表示中の Doc を名乗る。
                // ActiveDocs.step だけ Fs.FileWrite を使うので、純粋な部品は checked_ecast で
                // 同じ効果行へそろえる（部品側の ef は {} のまま保つ）。ActiveDocs は Studio の
                // 「表示中」バッジ用の補助で、ゲーム進行には関与しない（一覧が変わった瞬間だけ書く）。
                update = (f, w) ->
                    checked_ecast(Controls.step(f, w))
                        |> (w1 -> ActiveDocs.step(Controls.activeDocs(w1), w1)),
                view = (ctx, w) -> checked_ecast(View.frame(ctx, w)),
                reloads = Controls.reloads()
            })
                // 以下は App.game の外側の高度な口（戻り値の App に後ろから pipe で足す）。
                // ドット絵を作った 1 枚を GPU へ上げる（View はこの名前で 1 コマ 1 クアッドを貼る）。
                // 鍵が同じ間は上げ直さないので、毎フレームの費用はゼロ。
                |> App.withSpriteAtlases(w ->
                    { texture = World.atlasName(), key = w#atlasKey, baked = w#atlas } :: Nil)
                |> App.reloadOn(GameEngine.Key.F1, Controls.reloadAll)
                // 走行中の POST /render（Studio の「生成して」）は SceneRender.all と同じ実体を呼ぶ。
                |> App.onRenderRequest(SceneRender.allShots)
                |> App.withDebug(App.debugFromEnv())
                |> App.launch
        } with LwjglLayer.withProject(".")
          with Fs.FileRead.runWithIO
          with Fs.FileWrite.runWithIO
    }
