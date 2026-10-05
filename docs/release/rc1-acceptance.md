# Full Game Release Candidate 1

Repository: `hidetora1986/biwako-shindo`。Branch: `release/rc1`。
Base: `7eeafafa912a6abbe1039e0e3aaa5fc79f338553`。
Engine: Godot **4.6.3.stable.official.7d41c59c4**。
Version: **0.9.0-rc1** / 琵琶湖深度 / BIWAKO SHINDO。

RC1 Status: **NOT READY**。Release Blocker **1**、Known Non-blockers **4**。
機能のAcceptanceは合格だが、Main 60〜80分・Hidden 80〜100分の体験を示す根拠が不足し、モデルは約45／55分。目標へ合わせた待機や長い金策を追加しない。詳細は[Pacing](rc1-pacing.md)と[Known issues](known-issues.md)。

## 最小変更

- LINE Lv2価格を¥2,500→¥1,800。初期の最低額ブルーギルのみで13→9匹、通常は3匹以内で購入。
- Main Ending後、夜解放済みなら無名ルアー入手前にも既存NIGHT切替を利用可能。深層魚・ノック・0m接触の取り逃しを後から回収できる。新規イベントは追加しない。
- No.10／14を返す前に売却した選択を`unknown_a_sold_first`／`unknown_b_sold_first`へ保存しHidden条件から除外。通常Endingはクリア可能。先に返した後の売却はHidden条件を失わない。旧Saveに追加Flagがなければfalseで移行し、過去の選択を推測で不可にしない。
- 将来VersionのSaveを読み込めない旧バイナリでは、Fallback後の保存も保護して元のFileを上書きしない。Version 1・既存Atomic `.tmp→rename`は維持。
- シーン終了時にノック／ライン音を停止・解放。音声デバイスのないHeadlessでは音声Voiceを開始せず、同じ論理イベント・Beatを進める。Native描画実行は音声呼出しを含む。
- Version・English description・秘密情報ignoreを準備。魚・Boss・Ending・Story・新しいHorror・新エリアを増やさない。

## Full path

`tests/full_game_acceptance.gd`は所持金・魚記録・装備・解放FlagをDebugで付与しない。新規Save、実CAST、Hook、通常Fight、売却／返却、実購入、夜・3段階ノック・0m接触、No.15、Main Ending、Continue、全条件、通常捕獲2回で無名ルアー、No.00の50秒耐久、Final Choice、Hidden Ending、Continue、Loadまで通す。

返却→Contact、返却→Cut、売却→Main Endingの**3独立New Save**を実行。Main 28匹、Hidden 30匹。通常15種を発見し4カテゴリ16購入でLv1〜5へ。No.15とNo.00の操作は既存のREEL長押し／離すだけ。No.00は数値サイズ・売値・全身素材を持たず、Contact後のcount=2を保持する。売却ルートでHidden不可は仕様上の選択でありSoftlockに数えない。

各捕獲・返却直後に再Loadして所持金・捕獲記録・返却Flagを比較する。ボットは攻略手順を知っており、人間の初見成功率や90分の遊びを測ったものではない。

## Save / Input / Stress

- `full_game_stress.gd`: **100 cycles、90 CATCH／10 ESCAPED、600回のSHOP／BOOK Open**。所持金¥106,875、成功数90だけが記録され、Node182で一定。二重処理・残高破損・モーダル停止残りなし。20／50／100回のResetを確認。
- CAST、Hook、REEL、Shop、Book、売る／返す、Hidden Choiceの連打・重複は既存11Acceptanceと新規テストで確認。
- Hiddenの高速Touch、別指、領域外Drag、HOME／Focus lossでREEL解除。Tension／Boat Pullは有限値。
- `rc1_save_stress.gd`: 捕獲・返却・全ノック段階・Ending Flagの保存／再Load、Contact count=2を100回復元。Atomic途中の不完全`.tmp`が元のSaveを変えないこと、first-sale Flagの再起動耐性を確認。
- Empty／Partial／Unknown／Missing／Wrong type／Future VersionはクラッシュせずFallback。Future Versionは保存を拒否し元Fileを保護。
- No.15報酬直後→Ending途中終了→再起動完了→Postgameと、Cut／Contact→別プロセスのLoad／Continueを計8プロセスで再実行。
- `rc1_postgame_recovery.gd`: Main Endingを先に迎えNo.11／13・ノックが未回収のSaveを作り、Continue→無名ルアーなしNIGHT→実CASTでNo.11／13再捕獲→ノック3／0m接触→再Loadを確認。検出した朝固定のSoftlockを修正。

これらのケース内で意図しないSoftlockは0。あらゆるプレイヤー操作の形式検証を行ったという意味ではない。

## Regression / UI / Performance

Phase 1〜5、MVP、Visual、Midgame、Lategame、Boss、Hiddenの**既存11テストすべてPASS**。Phase4のLINE Lv2期待価格だけをRCの正式価格へ更新し、効果・他価格・取引検証を維持する。

新規全編3ルート、Pacing、100回Stress、Save Stress、Postgame回収、8回Restart、Import／Headlessを合わせて**28実行すべてPASS**。Pacingスクリプトの計算・経済条件のPASSは、90分目標のPASSを意味しない。JSONに`pacing_target_met=false`を残す。

最終Headless実行のGodot Error／Script Error／Warningは0。NativeはCompatibility／Mesa llvmpipe／Xvfb、VSync非対応の環境Warningのみ。16:9、19.5:9、20:9、640×360、44px以上・疑似Safe Area、Final Choice／Sell Return／CAST／REEL、長い日本語名、ShopとFish Bookのスクロールを確認。NearestとピクセルSnapを維持。全編の色・深度差は既存描画テストとNative画面で確認し、No.00級の暗部はHidden専用で維持。

Native 5スクリプトから**142枚**を再取得し14枚を選定。各テストのIdle120フレームでNode182固定・Save書込0。毎フレームのFile I/O、大量Particle、新しい重いShaderなし。100回Stressは100捕獲でなく「90捕獲＋10失敗」。端末FPS・発熱・ハプティクス・人間の指操作は実測していない。

**Android Export: BLOCKED**（SDK・Templatesなし）。**iOS Export: BLOCKED**（Linux、Xcode・署名環境なし）。[Export準備](export-preparation.md)、[Asset／Secret監査](asset-audit.md)。秘密情報パターン該当0、外部著作物や鍵・証明書を追加しない。

Fishing Feel / Horror Pacing / No.15 Feel / No.00 Feel: **MANUAL TEST REQUIRED**。

## Evidence and rerun

[生結果](rc1-results.json)、[Pacing JSON](rc1-pacing-results.json)。実行方法はRepository README。Captureは実Godot framebuffer、合成なし。進行の証明はDebug付与なしの全編テスト、深層Captureの装備・進捗Fixtureは描画確認のみ。

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/full_game_acceptance.gd
godot --headless --path . --script tests/full_game_acceptance.gd -- --cut
godot --headless --path . --script tests/full_game_acceptance.gd -- --sell
godot --headless --path . --script tests/pacing_simulation.gd
godot --headless --path . --script tests/full_game_stress.gd
godot --headless --path . --script tests/rc1_save_stress.gd
godot --headless --path . --script tests/rc1_postgame_recovery.gd
```

## Representative screens

| 状態 | Native画像 |
| --- | --- |
| 01 Early Lake | [画像](screenshots/non-spoiler/01-early-lake.png) |
| 02 Normal Catch | [画像](screenshots/non-spoiler/02-normal-catch.png) |
| 03 Shop | [画像](screenshots/non-spoiler/03-shop.png) |
| 04 Fish Book | [画像](screenshots/non-spoiler/04-fish-book.png) |
| 05 Sonar Anomaly | [画像](screenshots/spoiler/05-sonar-anomaly.png) |
| 06 Mid Depth | [画像](screenshots/spoiler/06-mid-depth.png) |
| 07 No.10 | [画像](screenshots/spoiler/07-no10.png) |
| 08 Night | [画像](screenshots/spoiler/08-night.png) |
| 09 No.14 | [画像](screenshots/spoiler/09-no14.png) |
| 10 No.15 Boss | [画像](screenshots/spoiler/10-no15-boss.png) |
| 11 Main Ending | [画像](screenshots/spoiler/11-main-ending.png) |
| 12 Hidden Depth | [画像](screenshots/spoiler/12-hidden-depth.png) |
| 13 No.00 Contact | [画像](screenshots/spoiler/13-no00-contact.png) |
| 14 Hidden Final Choice | [画像](screenshots/spoiler/14-hidden-final-choice.png) |
