# Content Expansion Phase 1 — 0〜50m

基点は `3b7ba3060377c924dcc00c9ec08bfb04e896059d`。作業ブランチは `feature/midgame-depth-v1`。main・MVP・Visual Refinementの3ブランチを保持します。

## 深度と操作

CAST上のDEPTHで解放済みの深度帯を切り替えます。0〜15mは従来の浅場、15〜30mは暗めの青、30〜50mは彩度を抑えた濃青です。空・山・ボート・水面は上部38%に固定します。ラインLv2では15〜25m、Lv3では50mまで。深場のCASTは20/25/28mまたは35/40/50mを順に狙います。実深度は水面の0mから沈下し、対象深度で待機して近くの魚を検知します。描画座標は表示帯の原点と幅で変換し、ゲーム上のメートル値を維持します。

`DepthBands`がResourceの生息深度とrarityから帯ごとの出現候補・重みを作り、7つの既存Fishノードを再利用します。魚は生息深度とライン上限の交差範囲に配置されます。新しいCASTごとに候補を循環し、一部の魚だけが近くのルアーへ接近します。浅場の初期配置・釣り数値は従来通りです。

| No. | 魚 | 深度 | サイズ | 売値 | rarity |
|---|---|---|---|---|---|
| 06 | 巨大ナマズ | 15–25m | 100–160cm | ¥6,000–18,000 | 3 |
| 07 | 白化ビワマス | 20–30m | 35–60cm | ¥8,000–20,000 | 4 |
| 08 | 長体ウナギ | 20–35m | 120–220cm | ¥10,000–28,000 | 4 |
| 09 | 盲目イサザ | 30–40m | 18–28cm | ¥12,000–24,000 | 5 |
| 10 | 名称不明種A | 35–50m | 80–140cm | ¥28,000–60,000 | 5 |

魚データとFight設定は既存`FishFightProfile`にまとめています。No.06は大きくゆっくりしたRUN、No.07は短いRUNを多めに、No.08は長い抵抗、No.09は短いFight、No.10はやや強い抵抗です。画像は自作の3フレームをキャッシュ。大型・長体フレームの境界と口位置をFish側で扱い、`fish_art`による素材交換も保持します。

## 名称不明種A

ソナーでは既知でもLv3・4の魚種欄は`???`。反応は8px、通常5px、一度限りの既存異常40pxとは明確に区別します。発生条件や0.6秒の既存異常は変更していません。

No.10は初回を含め毎回、通常の1.5秒CATCH表示後に「売る／戻す」を表示します。自動売却・時間切れはありません。CHOOSING中のCAST、REEL、HOOK、SHOP、図鑑、深度切替を防ぎます。選択は1回の取引として確定し、その後0.2秒で釣りへ復帰します。

- 売る: 売値加算、発見・捕獲数・BEST更新、Save。
- 戻す: 所持金不変、魚を湖へ戻す、同じ捕獲記録を更新、`returned_unknown_a=true`、Save。

戻したフラグはその後の売却で消しません。図鑑は10種。No.10の説明は「分類: 不明。既知の記録との一致が確認できない。」のみです。任意の追加ソナー消失演出は省略しました。新イベント・BGM・ボス・No.11以降は追加していません。

## Lv4とSave

No.10の発見記録でLv4を解放します。条件成立前はSHOPにも購入APIにもLv4を出しません。購入後は即装備・残高控除・Saveです。

| 装備 | 名称 | 価格 | 効果 |
|---|---|---|---|
| ROD Lv4 | HEAVY ROD | ¥90,000 | 250cm |
| REEL Lv4 | リール Lv4 | ¥75,000 | ×1.50 |
| LINE Lv4 | ライン Lv4 | ¥65,000 | 85m |
| SONAR Lv4 | ANOMALY SCAN | ¥120,000 | 90m・ANOMALY表示能力 |

LINE4は既存の短いDEPTH UNLOCKEDで50m→85mを表示します。性能データ85mと今回の実プレイ上限50mを分離しています。50mより深い帯や魚はありません。

SaveはJSON version 1を追加項目で拡張します。旧Saveの所持金・Lv1〜3・No.01〜05記録・anomaly_seenを保存したまま、新5種は未発見、returned_unknown_aはfalse、Lv4は未解放になります。読込だけでは書き換えません。No.10未発見の不整合なLv4値はLv3へ戻します。捕獲・選択・購入などの取引時に原子的保存を行い、毎フレームのFile IOはありません。

## Acceptance

Godot 4.6.3 stable、Linux Compatibility/Mesaソフトウェア描画で確認。自動検証の詳細は [結果JSON](midgame-acceptance-results.json)。既存の図鑑件数チェックは5→データ件数へ更新し、浅場5種の絵・データ・挙動チェックは残しました。

- Midgame Acceptance: PASS。24回の自然な深場CAST→BITE→HOOK→Fight→CATCH、No.06〜10全部、実深度50m、選択の多重入力・待機、経済、Lv4、旧Save互換を確認。
- 平均サイクル約18.2秒、通常の深場魚は約10〜20秒。選択を考える人間の時間は含みません。
- Phase 1/2/3/4/5、MVP Phase 6、Visual Acceptance: 全PASS。
- 別々のGodotプロセスでSave→終了→起動Loadを実行し、所持金・Lv4・No.02/No.10のBEST/捕獲数・両フラグを復元。
- 16:9、19.5:9、20:9、640×360の実描画で、タッチ／マウス選択、図鑑スクロール、Lv4ショップと44px以上の選択ボタンを確認。待機120フレームにノード増加・Save書込なし。
- Import/Headless Launch: PASS。重大Error: 0。仮想ディスプレイのVSync非対応Warningのみ。

実機iPhone/Android、端末別Safe Area・ハプティクス、初見ユーザーの60〜80%成功率と主観的なテンポは未測定です。自動テストは安全域で押す／RUNと危険域で離す操作を再現します。

## 画面例と再現

[15〜30m](../midgame/screenshots/16x9-15_30m.png) / [30〜50m・UNKNOWN](../midgame/screenshots/16x9-30_50m.png) / [Fight](../midgame/screenshots/16x9-fight.png) / [売る・戻す](../midgame/screenshots/16x9-choice.png) / [Lv4 Shop](../midgame/screenshots/20x9-lv4-shop.png) / [No.10図鑑](../midgame/screenshots/640px-book-no10.png) / [19.5:9選択](../midgame/screenshots/19_5x9-choice.png) / [20:9選択](../midgame/screenshots/20x9-choice.png) / [640px選択](../midgame/screenshots/640px-choice.png)。

```sh
godot --headless --path . --script tests/midgame_depth_acceptance.gd
godot --headless --path . --script tests/midgame_save_restart.gd -- --write
godot --headless --path . --script tests/midgame_save_restart.gd -- --read
godot --path . --script tests/midgame_capture.gd -- --output-dir=/tmp/biwako-midgame-captures
```

テストはプレイヤーのSaveと異なる`user://tests/`のファイルを使います。実描画のギアLv3は画面取得専用のfixtureです。通常ゲームは旧Saveを読み込み、Saveなしでは¥0・全Lv1から始まります。
