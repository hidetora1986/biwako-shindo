# MVP Phase 2 — Acceptance確認結果

確認日: 2026-10-04。Godot **4.6.3 stable**。対象ブランチ: `feature/mvp-fishing`。
開始HEAD: `88a04f1105e8d446d08393d6164c68c624089265`。

## 結果

| 項目 | 結果 | 確認内容 |
| --- | --- | --- |
| CAST | PASS | 実際のViewportへマウス／タッチイベントを送り開始。連打・多点入力でもルアーは1つ、CAST無効化 |
| Lure Flight | PASS | 竿先から0.55秒の弧を描く。実描画確認 |
| Lure Splash | PASS | landedシグナルの位置が水面。短い波紋・しぶきの描画と寿命を確認 |
| Lure Sinking | PASS | 着水後に深度増加、15mでWAITING。15mまで約6.52秒 |
| Depth Display | PASS | メートル表示がルアーに追従。120mへの表示スケール変更と途中リサイズでも内部深度を維持 |
| Fishing Line | PASS | 竿先とルアーをLine2Dで接続。沈下とリサイズで端点を照合。実描画確認 |
| Fish Detection | PASS | 半径内の魚を検知。半径を1pxにすると検知せずSWIM維持。同時予約は1匹 |
| Fish Approach | PASS | SWIMからAPPROACH_LUREへ移り、ルアーとの距離が減少。他の魚は遊泳継続 |
| Bite | PASS | 魚BITE・ルアーBITTENと!表示が一致。0.7秒のルアー予兆運動、1.5秒の入力猶予 |
| Hook Success | PASS | 猶予の終わり近くの広域タッチでHIT!。PC左クリックでも成功。重複フックは拒否 |
| Hook Miss | PASS | 1.5秒を過ぎるとMISS、遅い入力を拒否。魚が離れ、別の魚が再CASTなしで再び食いつく |
| Temporary Reset | PASS | HITを約1秒保持、RESET中の入力拒否、その後再CAST可能。ノード数増加なし |
| 16:9 | PASS | 1280×720、640×360論理画面で入力・描画・HUDを確認 |
| 19.5:9 | PASS | 1560×720、780×360論理画面で入力・描画・HUDを確認 |
| 20:9 / 320px幅 | PASS | 各画面で模擬Safe Area、!、CAST領域44物理px以上、広域タッチを検証 |
| Project Import | PASS | Godot 4.6.3、終了コード0、重大Error 0 |
| Headless Launch | PASS | 通常メインシーン180フレーム、終了コード0、重大Error 0 |
| Critical Errors | 0 | 最終インポート・起動・両Acceptance・実描画のログで確認 |

Phase 2の統合テストは**57項目PASS、失敗0**。Phase 1の**22項目も回帰PASS**。Phase 1の背景、ボート揺れ、水面、7匹の遊泳、既存HUDと素材差し替えを維持しています。

12seed × 3連続CASTの36試行では、キャスト→アタリ→0.25秒後のフッキングまで平均約**5.27秒**、最長約**5.27秒**でした。初回CAST前に異なる待機時間を入れ、魚の位置と乱数を変えています。これは再現可能な自動入力による値で、実際のプレイヤーの反応時間は含みません。未入力の場合はHITにせずMISSとなります。

## 再現方法

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 180
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
```

PCでF5実行し、CASTをクリック → ルアーの飛行・着水・沈下 → 魚の接近 → !で画面を左クリック → HIT! → 再びCASTの順に確認できます。!でクリックしなければMISSの後、再CASTせず次の魚が寄ります。1280×720と1560×720で同じ操作を確認しました。

## 検証範囲と残課題

- Linux、Godot 4.6.3、OpenGL Compatibility。仮想ディスプレイ・ソフトウェアGPUで実際にゲームを進め、READY、飛行、沈下、!、HIT、MISSを両画面比率で描画確認。
- タッチ入力は実際のViewportへInputEventScreenTouchを送って検証。iPhone / Android実機での入力・振動・Safe Area・FPS、モバイル書き出しは未検証。
- 現在のアートはPhase 1を維持した自作仮素材。追加ルアー・着水描画も自作で、外部画像や有料アセットは使用していません。
- 接近確率や最早アタリ時間は操作確認向けの調整です。正式な魚データ・魚種別の食いつきバランスは後工程。
- HIT後のリセットはPhase 2限定。Phase 3でFishingFightへ置換予定。実機ハプティクスと正式な竿アニメーションは今後確認・整備します。

これはPhase 2の確認結果です。MVP全体のAcceptance、mainへのMergeは行いません。
次の作業はMVP Phase 3 — REEL・ラインテンション・魚スタミナ・釣り上げの実装指示待ちです。
