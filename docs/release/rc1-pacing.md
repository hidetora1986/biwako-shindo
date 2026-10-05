# RC1 pacing simulation

Status: **TARGET NOT MET**。結果を90分へ合わせる係数や待機ゲートは使用しない。

固定SeedのNew Saveから、所持金・装備・発見・返却Flagを付与せず実CAST／Hook／Fight／Choice／購入／イベントを通した。読みやすさのためボットは購入順と深度帯を知っており、これ自体は人間の初見プレイではない。操作時間と仮説の初見オーバーヘッドを別に算出する。

| 指標 | 値 |
| --- | --- |
| Main実ゲーム時間 | 18.50 min |
| Hidden実ゲーム時間 | 20.15 min |
| Estimated Main Ending | 44.99 min（目標60〜80） |
| Estimated Hidden Ending | 55.46 min（目標80〜100） |
| Catch count Main / Hidden | 28 / 30 |
| 通常の最長購入待ち | 3 catches |
| 最低額モデルの最長待ち | 9 catches |

## 推定の仮定

学習6分、ショップ・図鑑を読む6分、捕獲1回あたり探索20秒、通常／中盤／終盤成功率85%／70%／65%、Boss再挑戦2回×60秒、Postgame探索8分、No.00再挑戦50秒。失敗時間は各実測Fight＋6秒から算出。人間の成功率や探索時間を測ったものではない。仮定を変えれば推定が変わるので、確定の90分体験を主張しない。

## LINE購入Checkpoints

| 購入 | 累積Catch | 購入前所持金 | 購入後 | 実ゲーム分 |
| --- | --- | --- | --- | --- |
| LINE Lv2 | 3 | ¥3,174 | ¥1,374 | 0.90 |
| LINE Lv3 | 7 | ¥16,073 | ¥4,073 | 2.51 |
| LINE Lv4 | 13 | ¥98,359 | ¥33,359 | 5.57 |
| LINE Lv5 | 19 | ¥328,755 | ¥28,755 | 10.14 |

## Economy adjustment

LINE Lv2だけ¥2,500→**¥1,800**。最低額ブルーギル¥200だけの場合13匹→9匹で深度15m以深へ進める。効果値・他装備価格・魚売値・Fight値は変えない。通常ルートの全16購入Ledgerと、低額魚から深度を進める全16購入LedgerをJSONへ記録。旧Saveの所持金・装備Lvはそのまま。

最低額ケースは各進行段階で利用可能な魚の売値下限を使い、初回No.10／14返却は収入を与えずUnlockだけを満たす経済モデル。Spawn RNGを全組み合わせ探索した保証ではない。実際のSpawn・返却・全15種・夜・Knock・Endingは別の全編Integration Testで確認する。

現在のCatch時間・購入間隔を保ちながら90分を保証する根拠は得られていない。価格を大幅に上げる金策や自動待機を足して目標を満たした扱いにはせず、RC Blocker B01として残す。

```sh
godot --headless --path . --script tests/full_game_acceptance.gd
godot --headless --path . --script tests/pacing_simulation.gd
```

シミュレーター入力は直前のFull Gameが出力する`/tmp/rc1-full-contact.json`。Cut／Sell版は同じSourceで`-- --cut`／`-- --sell`。JSONの生データは[rc1-pacing-results.json](rc1-pacing-results.json)。
