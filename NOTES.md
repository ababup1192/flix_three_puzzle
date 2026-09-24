# NOTES
- 2026-09-24: GitHub (private) に push: https://github.com/ababup1192/flix_three_puzzle。visual-dict SKILL.md 22 行目の独自語をゲーム側だけ直した（engine の原本は未修正）。

- 2026-09-24: test/TestBoard.flix（Board の部品ごとのテスト 24 本）を追加。make test 42 本緑。
- 2026-09-24: 学生向け解説ページ（図 + C 併記・PART 0〜5。5 = 部品のテスト）を公開: https://claude.ai/artifact/32wyU1DvjGh4z78wQ8bQ51 （元ファイルはセッションの scratchpad なので、直すときはこの URL を read して作り直す）
- 2026-09-24: 三目並べの骨組み完成（Board のルール・主人公の 1 マス移動・勝ち/引き分けの帯・16 色ドット絵）。check / test(18) / render-all / reference-check 緑。
- 次: 依頼主に絵（gallery/main・win・draw）の感想を聞き、直す所を 1 つずつ（絵の周回は r2 で止めて聞く）。
- 注意: engine 同梱 bin/flix は Studio の JRE しか見ない。このマシンは `devbox install` の java を local.mk（override FLIX / CHECKD := 0）で使っている。別マシンでは devbox install 後に同じ 2 行を local.mk へ。
