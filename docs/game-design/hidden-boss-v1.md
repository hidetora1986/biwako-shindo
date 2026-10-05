# Hidden Phase — No.00 / 開発用検証記録

通常のNo.01〜15、No.15 Fight、Main Ending、所持金・装備・売却・図鑑を保持したうえで、通常分類の外へ専用遭遇を追加する。基点は`dd80cf37aed83a6eb0d1dfa12758f72ebd433fde`、作業は`feature/hidden-boss-v1`のみ。以下は開発用ネタバレであり、ゲームUIには条件一覧を表示しない。

## 条件と無名ルアー

`boss15_defeated`、`main_ending_seen`、通常15種すべてのdiscovered、`returned_unknown_a`、`returned_unknown_b`、ノック3段階、0.0m接触済み、Sonar Lv5、夜の利用可能、すべてが必須。1つでも欠ければ遭遇できない。No.00は`FISH_PROFILES`にも通常の`fish_records`にも追加しない。

条件達成後、図鑑のNo.15より下へ薄いNo.00行を表示。選択時は「No.00／この項目は存在しない。」だけを表示し、`hidden_entry_seen`を保存する。通常15種の発見数や捕獲数は変わらない。

Main Ending後の通常捕獲2回で無名ルアーが所持品へ現れる。入手通知・購入・入手経路の説明はない。「所持品に入っていた。」だけを添える。タップで装備／通常ルアーへ切替でき、夜／朝も右側のボタンで切替できる。Lure表示はCAST・深度選択を避けた44px以上の領域。無名ルアー所持・装備、夜への遷移完了、ABYSSの選択、全条件、未Hidden Endingが揃ったCASTだけが専用遭遇となる。通常の沈下・売却や水深システムは変更しない。

## 専用遭遇

`FishingController.State.HIDDEN`中だけ、`HiddenRoute`が専用状態を進める。約0.6秒の小さなキャスト軌道に続き、104→108→114→121→`---`をそれぞれ間を置いて表示する。実際のルアー計算値・LINE Lv5・通常深度帯は120m以内のまま。通常魚を隠しAIを停止、ソナー上の既存反応は薄く消え、不定形の暗赤の帯がソナー全体へ広がる。通常のBITE/HIT/魚名は出さず「接触」を1秒だけ表示する。

No.00の内部IDは`00`。魚ノード・全身Sprite・閉じた輪郭を持たない。画面外へ続く暗い曲線と水中の明度差だけを描く。巻き上げEndingでも本体や捕獲Spriteは表示しない。顔、歯、血、内臓、警告文、長文Lore、ジャンプスケアはない。通常BGM自体が現プロジェクトでは未導入なので曲の切替は追加せず、巻き上げ時だけ自作の小さなライン音を鳴らす。

## 船を守るFight

`HiddenFishingFight`はNo.15の`BossFishingFight`とは独立した純粋な耐久モデル。魚スタミナ・距離・売却・捕獲を使わない。

- 50秒耐える。0〜20秒は弱いPull、20〜35秒は短いPullの反復、35〜50秒は強いPull。
- 強いPullの前に必ず0.8秒の予兆区間を設け、ソナーの反応移動を止める。即死乱数はない。
- REEL長押しで船を戻し、テンションが上がる。離すとテンションが下がるが船のPULL DEPTHが増える。
- LINE TENSIONは0〜100、黄色70以上・暗赤90以上。98以上を1秒維持するとLINE BREAK。
- BOAT PULLは0〜5m。5m到達で失敗。見た目は上下最大15px程度・中盤以降左右2px程度で、長い沈没演出はない。
- タッチの指番号を所有し、離す・領域外へドラッグ・アプリフォーカス喪失でREELを解除。PCはボタンのマウス長押しで同じ操作。
- CAST、HOOK、SHOP、図鑑は専用遭遇中に受け付けない。

失敗は暗転して3秒で朝の通常湖上へ戻る。所持金・装備・図鑑・無名ルアーを失わず、夜とABYSSを選び直して再挑戦可能。成功時は水中の動き・Pull・テンションを止め、2秒静止後に「巻き上げる／切る」だけを表示する。各ボタンは180×60論理px。

## 2つのEnding

**切る:** ラインと反応を消し、朝へ移行してTitle。`hidden_cut_ending_seen=true`を保存。Titleの湖面下に極めて薄い、画面外へ続く暗部だけを残す。No.00は捕獲・発見扱いにしない。

**巻き上げる:** ライン音だけで水面方向へ戻り、船の直下を一瞬暗部が通る。本体を出さず暗転し、図鑑風表示を3秒提示する。

```text
No.00
帰ってきたもの
深度: 記録不能
サイズ: ---   売値: ---
捕獲数: 2
記録が一致しない。
```

その後`hidden_contact_ending_seen=true`、`no00_contacted=true`を保存してTitle。`no00_record()`の捕獲数はこのFlagから常に2として構成し、サイズ・深度・売値の数値は保持しない。No.00は売却APIでも拒否する。理由の説明はしない。

どちらのEnding後もCONTINUEで通常釣りが再開できる。以後、通常プレイでHidden Encounterが再発せずFarmできない。No.15の再発も従来どおり禁止。将来の2周目向けに`second_playthrough_hooks`（最初の記録2・再訪台詞・Sonar 120m flash）を保持するだけで、New Game+やNPCは実装しない。

## 保存と互換

既存JSON Version 1への加算方式。旧Saveを読むだけで書き換えない。所持金・装備Lv・15種の図鑑・返却Flag・ノック・0m接触・通常Endingなど既存項目を維持する。

追加項目は`anonymous_lure_obtained`、`anonymous_lure_equipped`、`hidden_entry_seen`、`no00_contacted`、`hidden_cut_ending_seen`、`hidden_contact_ending_seen`、`hidden_postgame_sessions`、`second_playthrough_hooks`。欠落・不正値はfalse／0／空へfallback。所持なしの装備Flagは解除し、No.00接触記録は完了したContact Endingにのみ整合させる。捕獲後・ルアー入手／装備後・図鑑項目参照後・Ending完了後に保存し、毎フレームのFile I/Oはない。

テストは`user://tests/`の専用Saveを使い、プレイヤーSaveを変更しない。

## 構造・Debug

- `scripts/fishing/hidden_route.gd`: 遭遇・入力・最終選択・帰還、ルアーの表示。
- `scripts/fishing/hidden_fight.gd`: 50秒耐久モデル。
- `scripts/ui/hidden_visual.gd`: 開いた水中曲線・ソナー専用反応・暗転のみ。
- 既存GameProgress・SaveManager・FishBookには必要な追加だけを実施。

`flow.hidden_route.debug_setup()`はdebug build限定のAcceptance用条件／ルアーセットアップ。`debug_stage(HiddenRoute.Stage.DEPTH / CONTACT / FIGHT / CHOICE / CUT / REEL_UP / REVEAL)`で各状態を個別再現できる。Ending済みの視覚再現でも既存Ending Flagを消して保存しない。正式UIにDebugボタンはない。Debug setupは選択されたSaveへテスト進捗を保存するので、隔離SaveのAcceptanceスクリプトから実行する。

## 検証

Godot **4.6.3.stable.official.7d41c59c4**、Compatibility / Nearest。

- Hidden Acceptance: **99項目 PASS**。全条件の欠落、無名ルアーまで実際の通常釣り2回、深度順序、魚抑制、実Touch長押し／離す、2種類の失敗・再挑戦、3段階50秒生存、両Ending、No.00 count=2・売却禁止・保存・旧Save・再出現禁止を確認。
- Phase 1〜5・MVP・Visual・Midgame・Lategame・No.15 Boss: **全PASS**。MVPは21匹、Midgame24匹、Lategame20匹、Bossは失敗2回と成功の3遭遇を再実行。No.10／14返却、ノック6打、0m接触、Main Ending／Continueも含む。
- CutとContactの書込／再起動Load・Continue: 独立プロセス4回 PASS。No.15のEnding中断／再起動完了／Postgameも4回 PASS。
- Project Import・180フレームHeadless Launch: PASS。最終検証のGodot ERROR / SCRIPT ERROR: **0**。
- Safe Area・44px以上・16:9／19.5:9／20:9／640×360、CAST／深度選択との重なりなし: PASS。
- 実レンダラーで3比率×11状態の**33枚**。各比率120フレームの通常Idleでノード数182固定、追加Save書込0。

実端末のノッチ・ハプティクス・音量・人間が感じる50秒の難易度は未検証。自動テストはPCの実タッチイベント投入とCompatibility描画で確認したもの。

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/hidden_boss_acceptance.gd
godot --headless --path . --script tests/hidden_save_restart.gd -- --write --cut
godot --headless --path . --script tests/hidden_save_restart.gd -- --read --cut
godot --headless --path . --script tests/hidden_save_restart.gd -- --write --contact
godot --headless --path . --script tests/hidden_save_restart.gd -- --read --contact
godot --path . --script tests/hidden_capture.gd
```

全実行結果は[hidden-acceptance-results.json](hidden-acceptance-results.json)。画面は実Godot出力で合成しない。通常ゲームデータをDebugで準備した後、実CAST・Touch Fight・選択を通過する。

| 状態 | 16:9 | 19.5:9 | 20:9 |
| --- | --- | --- | --- |
| A No.00項目 | [画像](../hidden/screenshots/16x9-A-no00-entry.png) | [画像](../hidden/screenshots/19_5x9-A-no00-entry.png) | [画像](../hidden/screenshots/20x9-A-no00-entry.png) |
| B 無名ルアー | [画像](../hidden/screenshots/16x9-B-anonymous-lure.png) | [画像](../hidden/screenshots/19_5x9-B-anonymous-lure.png) | [画像](../hidden/screenshots/20x9-B-anonymous-lure.png) |
| C 114m | [画像](../hidden/screenshots/16x9-C-114m.png) | [画像](../hidden/screenshots/19_5x9-C-114m.png) | [画像](../hidden/screenshots/20x9-C-114m.png) |
| D 121m | [画像](../hidden/screenshots/16x9-D-121m.png) | [画像](../hidden/screenshots/19_5x9-D-121m.png) | [画像](../hidden/screenshots/20x9-D-121m.png) |
| E ソナー計測不能 | [画像](../hidden/screenshots/16x9-E-sonar-invalid.png) | [画像](../hidden/screenshots/19_5x9-E-sonar-invalid.png) | [画像](../hidden/screenshots/20x9-E-sonar-invalid.png) |
| F 接触 | [画像](../hidden/screenshots/16x9-F-contact.png) | [画像](../hidden/screenshots/19_5x9-F-contact.png) | [画像](../hidden/screenshots/20x9-F-contact.png) |
| G Hidden Fight | [画像](../hidden/screenshots/16x9-G-hidden-fight.png) | [画像](../hidden/screenshots/19_5x9-G-hidden-fight.png) | [画像](../hidden/screenshots/20x9-G-hidden-fight.png) |
| H 最終選択 | [画像](../hidden/screenshots/16x9-H-final-choice.png) | [画像](../hidden/screenshots/19_5x9-H-final-choice.png) | [画像](../hidden/screenshots/20x9-H-final-choice.png) |
| I Cut Ending | [画像](../hidden/screenshots/16x9-I-cut-ending.png) | [画像](../hidden/screenshots/19_5x9-I-cut-ending.png) | [画像](../hidden/screenshots/20x9-I-cut-ending.png) |
| J 捕獲数2の表示 | [画像](../hidden/screenshots/16x9-J-no00-count2.png) | [画像](../hidden/screenshots/19_5x9-J-no00-count2.png) | [画像](../hidden/screenshots/20x9-J-no00-count2.png) |
| K Continue後の図鑑 | [画像](../hidden/screenshots/16x9-K-persistent-book.png) | [画像](../hidden/screenshots/19_5x9-K-persistent-book.png) | [画像](../hidden/screenshots/20x9-K-persistent-book.png) |
