# RC1 Human Playtest

ゲームバランスはRC1 `8654c5112a3b524ed4ec1d01e3cbcad8eaf9f5d7`から変更しない。B01は実測後に判断する。自動テストの記録をHuman実測やFeel評価として使わない。

## 新規Saveで開始

Godot **4.6.3 Debug**でRepository直下から実行する。

```sh
godot --path . -- --rc1-playtest --rc1-fresh
```

明示的な`--rc1-playtest`がない通常起動、またはRelease Buildでは計測・Marker・Test Save切替は無効。`--rc1-fresh`だけでは何も削除しない。正式UIに計測値やDebugボタンは出さない。

Test Save: **`user://rc1-playtest/save.json`**。
計測: **`user://rc1-playtest/playtest-session.json`**。
Freshはこの2ファイルと対応する`.tmp`だけを初期化する。通常の`user://biwako-shindo/save.json`を変更・削除しない。Freshを指定した起動は前回のQA結果を消すので、次の参加者の前に結果をコピーする。

休憩後・再起動後はFreshを外す。

```sh
godot --path . -- --rc1-playtest
```

`user://`の実フォルダはGodot Editorの **Project → Open User Data Folder**で確認する。Debug Mobileでも同じ引数で起動するQA環境を用意する必要がある。今回はAPK／iOSアプリや実機計測を作成していない。

## 時計とMarker

`elapsed_seconds`は単調時計によるActive Play Time。SHOP、図鑑、Ending、文章を読む時間は含む。Focus喪失・Background・SceneTree Pause・F9手動計測Pauseは除く。5秒を超える処理空白は停止／Suspend相当として全区間を除外する。キーボード無操作を自動休憩扱いにしない。30 Active秒ごと、Milestone・Marker・Pause・終了時にAtomic JSON保存する。毎フレームFile I/Oは行わない。

`wall_clock_seconds`は初回開始からの実時間。再起動間の時間も含み、OS時計の変更の影響を受ける。Active側には再起動間を加算しない。強制終了では最後のCheckpointから最大約30 Active秒を失う場合がある。

| Debugキー | 記録 |
| --- | --- |
| F6 | BORED |
| F7 | GOOD MOMENT |
| F8 | CONFUSED |
| F9 | 計測Pause／Resume |

F9は**計測時計だけ**を止め、ゲームをPauseしない。長い休憩は操作待機状態で行うかBackgroundへ移す。再開時は必ずF9を戻す。Mobile QAではRemote Inspector／Debuggerから`HumanPlaytest.record("BORED", {}, false)`等と`set_manual_pause(bool)`を呼べる。正式Release UIからアクセスできない。

## Milestones / Telemetry

SESSION START、FIRST CATCH、LINE LV2、SONAR LV2、FIRST SONAR ANOMALY、NO06 DISCOVERED、NO10 DISCOVERED、NO10 CHOICE、LINE LV4、NO11 DISCOVERED、NIGHT、HULL KNOCK 1〜3、NO14 DISCOVERED、NO14 CHOICE、LINE LV5、NO15 ENCOUNTER、NO15 DEFEATED、MAIN ENDING、POST GAME CONTINUE、ANONYMOUS LURE、NO00 CONTACT、NO00 FINAL CHOICE、HIDDEN ENDINGを記録。

通常Milestoneは最初の到達だけ。Choice・Continue・Encounter／Contact・Markerは繰り返しを記録する。発見は捕獲記録確定時、Anomaly・Knock・Endingは完了時、NIGHTは環境が夜へ到達した時。No.15 attemptsはBOSS BITE到達、No.00 attemptsはHidden encounter開始で加算する。Hook前に逃してもEncounter回数に含む。failed_fightsは通常／BossのFAILEDとHidden FAILUREだけで、Hook MISSは含めない。

各記録にActive／Wall時間、所持金、通常15種の累計捕獲数、4装備Lv、ルアー深度、failed_fights、boss15_attempts、no00_attemptsを保存する。返却魚も捕獲数に含む。No.00の固定count=2は通常捕獲数へ水増ししない。SESSION STARTの値は初期値。

## Human Feel — 自動判定しない

`ratings`は初期値null。プレイヤー自身がFishing Feel、Upgrade Tempo、Midgame Boredom、Horror Pacing、No.15 Feel、No.00 Feel、Overallを**1〜5**で採点する。1=悪い、3=普通、5=非常に良い（Boredomも「退屈せず遊べたか」の良さで評価）。未到達項目はnullのまま残す。

Debug中に`HumanPlaytest.rate("Overall", 4)`等で保存できる。実行終了後は別紙／下記表で提出し、JSON原本と一緒に保管してもよい。自動コードが採点したりPASSへ変えたりすることはない。

| 評価 | 1〜5／未評価 |
| --- | --- |
| Fishing Feel | |
| Upgrade Tempo | |
| Midgame Boredom | |
| Horror Pacing | |
| No.15 Feel | |
| No.00 Feel | |
| Overall | |

## 実測提出・ペーシング判断

参加者ID（個人情報不要）、端末／解像度、初見か、操作説明の有無、Main／HiddenのActive時間とWall時間、休憩、各評価、BORED／CONFUSEDの理由を添えてJSONを提出する。Hidden条件を自然に満たせなかったケースも記録し、攻略を教えた再試行は別セッションにする。

Main 60〜80分・Hidden 80〜100分は比較対象であり、自動で合否を決めない。まず複数人の到達時間・退屈箇所・再挑戦を確認する。短くても満足度が高い結果を待機や値上げで引き延ばさない。B01とRC1 NOT READYは、今回のInstrumentation追加だけでは解除しない。

## QA

`tests/human_playtest_acceptance.gd`は専用Save初期化、通常Save保護、25Milestone、Telemetry、時計除外、Marker、未評価、再起動継続をFixtureで検証する。Fixtureの時間・評価・記録は人間の実測ではない。Acceptanceを走らせる場合は専用のXDG_DATA_HOME等を用い、参加者の計測ファイルを上書きしない。

```sh
godot --headless --path . --script tests/human_playtest_acceptance.gd
```

`tests/human_playtest_journey.gd -- --rc1-playtest --rc1-fresh`は実CASTから両Boss・Endingまで既存の全編テストを通し、全Milestoneを照合する。自動進行の時間を人間の時間として扱わず、ログにも`AUTOMATED INSTRUMENTATION CHECK`を付ける。Release UIや通常ゲームにはテストの観測処理を追加しない。
