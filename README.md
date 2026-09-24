# 3目並べ

flix_game_engine で作った三目並べ。主人公（ドット絵）を ←→↑↓ で 1 マスずつ動かし、
Space で立っているマスにマーカーを置く。O と X が交互に置き、先に 1 直線（縦・横・斜め）に
3 つ並べたほうの勝ち。9 マス埋まっても並ばなければ引き分け。ここから自分のゲームを育てる
ための骨組みでもある。

## 始め方

| コマンド | 何をするか |
|---|---|
| `make run`    | ゲームを起動する（ウィンドウが開く） |
| `make debug`  | 保存即反映(watchFile)と F8 を有効にして起動 |
| `make check`  | 型検査だけ走らせる（一番速い確認） |
| `make test`   | テストを実行する（ルールと Doc の読み込み） |
| `make palette` | Studio 用の色の写し(`assets/three_puzzle.palette.json`)を作り直す |
| `make render-all`   | ギャラリー PNG（main / win / draw）を全部描き出す（決定的） |
| `make render SHOT=win` | その場面だけ `debug/win.png` へ描き出す |
| `make reference-check`  | 描き出した絵をリファレンス画像とバイト比較する |
| `make reference-update` | いまの gallery をリファレンス画像として更新する |

## 読む順（全体像のつかみ方）

**遊ぶ → 読む → JSON をいじる** の順で仕組みが見えます。

1. まず `make run` で遊ぶ。←→↑↓（WASD でも可）で主人公が 1 マス動き、Space / Enter で置く。
   勝負がついたら Space でもう一度。
2. コードは **エントリ→状態→描画** の順で読む:
   1. `src/Main.flix` … 起動の目次。冒頭 doc に**毎フレームの流れ（入力→状態更新→描画 がどの行か）**。
   2. `src/Board.flix` … **ルールの芯**。盤は C の `int board[9]` と同じ並びの 9 マス。置く・3 つ並んだか・
      全部埋まったかを、配列・foreach のループ・書き換えられる変数（Ref）で書いてある。
   3. `src/World.flix` … ゲームの状態（盤・手番・主人公の位置）と、1 フレームで状態を進める `step`。
      冒頭に場面の遷移（遊ぶ → 勝ち / 引き分け → もう一度）。
   4. `src/Controls.flix` … キーを読んで World へ渡す。Doc の読み直しもここ。
   5. `src/Layout.flix` … 盤の置き場所（ラフ `draft/sketch/screen/v1.json` から写した座標）。
   6. `src/View.flix` … 状態を絵に写す。冒頭 doc に**画面の層**（奥から手前へ）。
   7. `src/Backdrop.flix` … 卓のフェルト（3 色をディザでつなぐ 1 枚絵）。
   8. `src/render/SceneRender.flix` … 決定的な場面を PNG に描き出す（リファレンス画像とアトリエ）。
3. 数値・色・文字・絵は `assets/` の Doc を保存即反映でいじる（`make debug` 中）。

`assets/` の Doc:

- `three_puzzle.rules.json` … 先手（o / x）・主人公が移る速さ・マーカーが落ちてくる高さ。`src/RulesDoc.flix` が読む。
- `three_puzzle.texts.json` … 画面に出る文字の全部（手番のラベル・勝ち負けの帯）。`src/TextsDoc.flix` が読む。
- `player.keys.json` … キー割り当て。`src/KeysDoc.flix` が読む。
- `three_puzzle.theme.json` … 画面の 16 色（素材ごとに暗・中・明 + 墨）。`src/ThemeDoc.flix` が読む。
- `three_puzzle.sprite.json` … ドット絵（マーカー・主人公・影）。文字 1 つが 1 画素で、scale 2 で置く。
- `three_puzzle.palette.json` … Studio のドット絵エディタに「意味色キー → 実色」を教える写し（生成物。`make palette`）。
- `three_puzzle.scenes.json` … ギャラリーに出る場面の題と一言。

それぞれに Studio 用の schema が並んでいて、`project.json` の `editor.resources` が宣言しています
（material = 見た目、tuning = 手触り・ルールの数値）。

## 絵の開発ループ

- 画風は `AGENTS.local.md` の「この画面の画風」に書いてある（見下ろし・粗いドット絵・16 色・墨の輪郭・半透明なし）。
- `make render-all` で `gallery/` に決定的な PNG を描き出し、`make reference-update` で更新、`make reference-check` で防護。
- 候補のスプライト・テーマは `atelier/` に置き、`make atelier-preview` で `debug/atelier/` に描き出して目視。

## AI エージェント向け指針の配布（sync-agents）

エンジン側で `make sync-agents GAME=/path/to/このゲーム` を実行すると、エンジン共通の
エージェント指針（agents-pack/AGENTS.core.md）とこのゲームの `AGENTS.local.md` を連結した
`AGENTS.md` が生成されます。`AGENTS.md` は生成物なので直接編集せず、ゲーム固有の原則は
`AGENTS.local.md` に書いて再 sync してください。
