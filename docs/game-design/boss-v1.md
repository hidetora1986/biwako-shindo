# Boss Phase — No.15・Main Ending

基点は `4c9c3783c0b0150ac0b9674e693ba7effe69cf84`、作業ブランチは`feature/boss-v1`。main・MVP・Visual・Midgame・Late Gameの5ブランチは保持します。

## 湖底域と遭遇

DEPTHにABYSS / 100〜120mを追加しました。LINE5の性能120mを実プレイでも使用します。暗い濃紺・青緑を保ち、少量の静的な浮遊物、泥・岩盤と曖昧な古い輪郭だけを描きます。水面光はありません。空・水面・ボートは既存の上部38%、水中断面は下部62%を維持しています。

| 項目 | No.15 |
|---|---|
| 名称 | 湖底の主 |
| 生息深度 | 100〜120m |
| サイズ | 300〜500cm |
| 売値 | ¥800,000〜2,800,000・サイズに比例 |
| rarity / is_boss | 7 / true |
| 説明 | 湖底域で確認された最大級の個体。 |

`data/fish/lake-master-fight.tres`を既存FishFightProfileに追加。288×96の自作3フレームをキャッシュし、厚い頭と胴、大きな尾、古い淡い模様を表現します。人面・大量の目・触手・赤・血はありません。通常の`fish_art`差し替え口を維持します。

遭遇条件はNo.14発見・ROD5・LINE5・night_unlocked・未撃破・ABYSSのルアー実深度100m以上です。深度を選ぶだけでは出現しません。REEL5とSONAR5は必須ではありません。条件が揃った最初のCASTで既存の魚ノードを1つ再利用して出現し、距離・接近を経てBITEします。追加の捕獲ノルマや所持金消費はありません。通常魚は100m境界に少量表示し、ボス接近中には離れます。

SONAR5では120mまで追跡でき、反応幅30pxでNo.14の16pxより大きく、既存の一過性異常40pxと区別できます。捕獲前は???、捕獲後の魚種表示は湖底の主です。低Lvソナーの範囲外判定は従来通りです。

## REEL中心のBoss Fight

ボスBITEでは1.5秒かけてラインを約3px下へ引き、竿を少し下げます。その後、従来の!と1.8秒のタップ／左クリック猶予を出します。HIT後も右下REELの長押し／離す操作だけです。新しい操作、連打QTE、Virtual Stickはありません。

`BossFishingFight`は通常魚の`FishingFight`を継承した専用モデルです。通常魚の式・設定を変更せず、以下を追加します。

| 段階 | スタミナ | 抵抗 |
|---|---|---|
| 1 | 100〜70% | 重く遅いPULL、4.3秒の間 |
| 2 | 70〜30% | SURGEとDIVEを交互に、3.2秒の間 |
| 3 | 30〜0% | 短い0.7秒SURGE、2.2秒の間 |

各抵抗には0.8秒の予兆、魚の動き、HUDのPULL SOON / DIVE SOON、対応端末の小さな振動があります。SURGEで巻き続けると危険になり、離すと回復します。DIVEは距離を増やし、表示深度を数m下へ動かします。深度は120m以内です。ラインは巨大な魚の口へ追従します。

98以上のテンションが1秒続いた時にLINE BREAK。赤へ触れただけでは切れません。長いLOWではESCAPED。失敗時に所持金・装備を減らさず、次CASTから再挑戦できます。

推奨REEL5・安全域で押し／RUNと危険域で離す再現操作では約43.75秒。REEL4は約53.25秒です。必須の深淵ロッドによるボス専用の補助として、旧リールの実効値下限を1.30にし、REEL1〜3でも約55.67秒で成立するようにしています。Lv4・5の効果はそのままで、通常魚のリール計算は変えていません。各Lvで30〜60秒の範囲を自動確認しました。

スタミナ0かつ距離0で自動ランディングし、2.2秒のCATCHに全身・魚名・サイズ・売値を表示します。売る／戻す選択はありません。通常通り自動売却し、所持金上限2,147,483,647で安全に丸めます。桁数が増えたHUDは文字幅に合わせて調整します。

## Ending・Title・Continue

初回捕獲の取引で、売値・図鑑・`boss15_defeated=true`をまとめて保存します。その後、短いFadeで浅場へ戻り、6秒の夜明けを含む8秒の演出からTitleへ進みます。HUDと旧ラインを隠し、静かな朝の湖を見せます。長い説明・ホラー音楽・ジャンプスケアはありません。

Ending完了時に`main_ending_seen=true`を保存し、「琵琶湖深度 / MAIN CLEAR / CONTINUE」を表示します。CONTINUEはタッチ／クリック1回で釣りへ戻ります。所持金・図鑑・装備・既存の全フラグを保持し、通常の捕獲・自動売却・SHOP・図鑑を継続できます。撃破後のNo.15再出現と再売却を両方防ぎます。

夜明け後の見た目は朝ですが、`night_unlocked`を含む進行フラグは消しません。将来判定に必要なNo.01〜15発見・A/B返却・ノック数・0.0m接触・ソナーLv・撃破／Ending状態はGameProgressから読み出せます。隠しルートの発動・No.00・Hidden Ending・無名ルアー・121m以上は実装していません。

## Save互換と中断

JSON version 1に2つのboolを追加する互換拡張です。旧Saveでは撃破／Ending未完了、No.15未発見が既定値です。既存の所持金・Lv・No.01〜14・A/B返却・夜・ノック・ソナー異常は保持します。不正型は安全な既定値へ戻し、読込だけでは書き換えません。

- CATCH後に終了: 報酬と撃破記録が残り、次回はEndingのみ再開します。
- 夜明け途中に終了: 同じEndingを短く再開し、報酬を再加算しません。
- Ending完了後に起動: 朝のTitleとCONTINUEを表示します。ボスを再生成しません。

Saveは捕獲・購入・イベント／Ending完了などの取引時のみ。毎フレームFile IOはありません。

## Acceptance

Godot 4.6.3 stable、Linux Compatibility/Mesa llvmpipeで確認。詳細は[結果JSON](boss-acceptance-results.json)です。

- Boss Acceptance: PASS（74項目）。実CASTによる遭遇、LINE BREAK、ESCAPED、次CAST再挑戦、タッチ長押し／離す、3段階・SURGE・DIVE・予兆時間、捕獲・自動売却・Ending・CONTINUE・クリア後の通常釣り／購入・再出現防止を確認。
- Phase 1〜5・MVP・Visual・Midgame・Late Gameの回帰: 全PASS。No.10／14の選択、船底ノック、0.0mソナー、Saveの既存検証を保持しています。
- 4つの別GodotプロセスでCATCH保存→夜明け中断→再起動完了→Title／CONTINUEを確認。報酬の二重加算なし、旧フラグと15種記録を復元。Midgame／Late Gameの再起動テストもPASS。
- 16:9・19.5:9・20:9・640×360で実描画、タッチ／マウスCONTINUE、図鑑スクロールを確認。待機120フレームにノード増加なし、Save書込0。
- Import・Headless Launch: PASS。Godot Error・重大Error: 0。仮想ディスプレイのVSync非対応Warningのみ。

iPhone／Android実機の音量・振動・端末Safe Area、初見プレイヤーの成功率と主観的なFightの重さは未測定です。時間計測は再現可能な安全域操作によります。

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/boss_acceptance.gd
godot --headless --path . --script tests/boss_save_restart.gd -- --write
godot --headless --path . --script tests/boss_save_restart.gd -- --interrupt
godot --headless --path . --script tests/boss_save_restart.gd -- --finish
godot --headless --path . --script tests/boss_save_restart.gd -- --postgame
godot --path . --script tests/boss_capture.gd -- --output-dir=/tmp/biwako-boss-captures
```

テストはプレイヤーSaveと別の`user://tests/`を使います。画面取得は後半進行・指定装備のfixtureから実際の検知・接近・Fight・売却・Endingを通します。

## 画面例

| 状態 | 16:9 | 19.5:9 |
|---|---|---|
| A ABYSS | [画面](../boss/screenshots/16x9-A-abyss.png) | [画面](../boss/screenshots/19_5x9-A-abyss.png) |
| B No.15 Sonar | [画面](../boss/screenshots/16x9-B-boss-sonar.png) | [画面](../boss/screenshots/19_5x9-B-boss-sonar.png) |
| C Phase 1 | [画面](../boss/screenshots/16x9-C-phase1.png) | [画面](../boss/screenshots/19_5x9-C-phase1.png) |
| D SURGE | [画面](../boss/screenshots/16x9-D-surge.png) | [画面](../boss/screenshots/19_5x9-D-surge.png) |
| E Phase 3 | [画面](../boss/screenshots/16x9-E-phase3.png) | [画面](../boss/screenshots/19_5x9-E-phase3.png) |
| F CATCH | [画面](../boss/screenshots/16x9-F-catch.png) | [画面](../boss/screenshots/19_5x9-F-catch.png) |
| G Dawn | [画面](../boss/screenshots/16x9-G-dawn.png) | [画面](../boss/screenshots/19_5x9-G-dawn.png) |
| H Book No.15 | [画面](../boss/screenshots/16x9-H-book15.png) | [画面](../boss/screenshots/19_5x9-H-book15.png) |

[DIVE](../boss/screenshots/16x9-dive.png) / [Title](../boss/screenshots/16x9-title.png) / [20:9 Title](../boss/screenshots/20x9-title.png) / [640px CATCH](../boss/screenshots/640px-F-catch.png)。
