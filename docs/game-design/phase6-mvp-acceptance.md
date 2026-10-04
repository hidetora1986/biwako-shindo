# Phase 6 — 正式MVP Acceptance

確認日: 2026-10-04。Godot **4.6.3.stable.official.7d41c59c4**。
Repository: `hidetora1986/biwako-shindo`。Branch: `feature/mvp-fishing`。
開始HEAD: `870d7607bfa5a0cf38c42f02994dc938d8e85eec`。
main: `4626fa329f1aa488ed90f707ac2757f2d771c090`を維持。Mergeしない。

## 調整内容

- CAST 0.55秒、Hook 1.5秒、HIT 0.3秒、CATCH 1.5秒＋Reset 0.2秒を維持。入力直後にルアー・ラインが表示され、CAST連打を防ぐ。
- 最初の10mは2.3m/s、約4.35秒。将来15m以深を表示した場合は`deep_sink_acceleration`で加速し、50mでも約8.42秒。現在の画面は従来の0–15m、ライン上限10／25／50mを維持する。
- ソナーパネルを184×120にし、見出し14px、Lv・探知深度12px、深度目盛11px、サイズ・既知魚名14px。Lv2以降は選択魚の深度も小数1桁で表示。実魚のサンプリング周期0.15秒は維持。
- SHOPのヘッダー余白・行間を調整し、640×360とノッチ想定のSafe Areaでも4カテゴリを同時表示。極小プレビューでは従来どおりスクロールできる。
- LINEのDEPTH UNLOCKEDは1.2秒。他カテゴリにも0.8秒のUPGRADE!を追加し、即装備が分かる。購入連打と表示中の再購入を防ぎ、再オープン時に古い購入クールダウンを残さない。
- NEXT表示を短くして14pxへ、ファイトの重要文字を12pxへ拡大。CAST／REELの位置と44px以上のタッチ領域を維持。
- READY中の静的HUDを毎フレーム更新せず、異常反応による操作可否の変化時に更新する。Saveは従来の進行変更時のみ。
- 魚価格・装備価格・ファイト設定は既存の実測が目標範囲のため維持。新魚・新エリア・新ホラー・全面アート変更は追加しない。

## 正式MVP Acceptance

| Acceptance | 結果 | 証拠 |
| --- | --- | --- |
| Launch / Lake / Fish Movement | PASS | Import・120フレームHeadless・Phase 1の湖、水面、ボート、7匹 |
| CAST / Lure / BITE / HOOK | PASS | Phase 2 57項目、36キャスト。平均・最大5.27秒でHIT、飛行・しぶき・深度・MISS・入力ガード |
| REEL / Tension / Fight UX | PASS | Phase 3 109項目。実タッチの長押し・離す・複数指・フォーカス喪失、SAFE・回復・RUN予兆 |
| Line Break / Escape / Catch | PASS | 100付近0.65秒の猶予、LOW 5.5秒、失敗復帰後の実捕獲。ランディングと結果1.5秒 |
| Fish Size / Price / Auto Sell / Money | PASS | Phase 4 196項目。5種Resource、サイズ範囲、単調売値、二重売却防止、HUD |
| Shop / Equipment Upgrade / Depth Unlock | PASS | 4カテゴリの購入・即装備・不足/MAXガード、深度制限10／25／50m、短い購入演出 |
| Upgrade Tempo | PASS | 資金注入なしの最初の2匹でLINE Lv2。連続捕獲の資金だけでLINE・REEL・SONAR・RODを強化 |
| Fish Book / Save / Load | PASS | Phase 5 105項目。未発見・NEW・捕獲数・BEST、JSON version 1、欠落・不正・旧版fallback、別Sceneと別プロセスで復元 |
| Sonar Lv1 / Lv2 / Lv3 | PASS | 実魚深度同期、探知範囲外除外、魚影／サイズ／既知魚名。PC実描画で文字を確認 |
| Anomaly / One-Time | PASS | Lv2購入後3セッション、0.6秒のソナー内反応。モーダル・Fight・Catch中の開始を防止し、saved flagで再発しない |
| Fishing / Economy / Equipment Loop | PASS | `tests/mvp_acceptance.gd` 316項目。21捕獲＋LINE BREAK・ESCAPEDの2失敗、モーダル混在、再読込と再捕獲 |
| 20 Fish Stress | PASS | 同一Sceneで20匹連続、Node数安定、1ルアー再利用、指・対象魚を解放、財布・図鑑・装備・フラグ一致 |
| Touch UI / Safe Area | PASS | ViewportのScreenTouch／Mouse、ノッチ・ホーム領域シミュレーション、主要ボタン44px以上、モーダル競合防止 |
| 16:9 / 19.5:9 / 20:9 | PASS | 実描画・自動レイアウト、画面外・Book/Sonar重なり・ボタン切れなし |
| 640×360 | PASS | 実描画で主要文字・操作を確認。4カテゴリ全表示、図鑑スクロール、ソナーLv3 |
| Phase 1 / 2 / 3 / 4 / 5 Regression | PASS | 各既存スイートを再実行。以前のテストを変更・弱化しない |
| Godot Import / Headless Launch | PASS | 4.6.3、120フレーム起動 |
| Critical Errors / Godot Errors | 0 | 最終Import・起動・全スイート・実描画・別プロセス復元 |

## 実測と性能

統合テストでは実CAST・魚検知・Hook・タッチREEL・ランディング・自動売却を通る。20匹＋失敗後の追加1匹のサイクルは**10.05〜15.28秒、平均12.00秒**。ファイトは**2.33〜7.57秒**。小魚やREEL Lv2により短縮する。

初期装備で5種を個別検証した既存Phase 3は、ブルーギル2.68秒、フナ4.13秒、ブラックバス4.82秒、ビワマス5.75秒、ナマズ8.17秒。操作の遅延を変えた既存20ケースは18成功、最長9.93秒。自動入力の結果であり、実際の初心者の成功率や操作感を測った値ではない。

READY 1,800フレーム、図鑑表示中、描画120フレームでSave書き込み増分0。ソナーは7匹を0.15秒ごとに走査し、魚AIは既存ノードを使う。大量Particle・重いShader・毎フレームのNode生成・File IOはない。

Linux Xvfb＋Mesa llvmpipeのCompatibilityで、640×360と20:9の各120描画フレームは約2秒（60fps上限）、テストSceneは99ノード。これはソフトウェアGPUでの動作確認であり、iPhone／AndroidのGPU・電池・温度の測定ではない。V-Sync非対応の環境警告を除き、最終Godot Errorは0。

16:9／19.5:9では実マウスで図鑑・初回捕獲・ソナー購入・3回釣り後の反応・Lv3を再確認。UI購入確認用の資金は独立Save内にのみ使用する。別Godotプロセスで所持金¥5,599、ソナーLv3、4捕獲、BEST 47.0cm、anomaly_seen=trueを復元。統合経済テストは資金注入なし。

## 素材差し替えと残課題

魚の`fish_art`、ボートの`boat_art`、ルアーの`lure_art`は表示素材を差し替え可能。湖・水面は独立レイヤーと`data/lake/morning.tres`、HUD・ソナー・ボタンはControl／scene／themeで表示を管理し、FishingController・Fish AI・Saveの責務と分離している。Phase 1の魚SpriteFrames交換テストもPASS。

iPhone／Android実機の親指操作、振動、実Safe Area、長時間性能・書き出し・署名は未検証。今回の正式MVP AcceptanceはPC自動試験・描画・入力シミュレーションで検証できた範囲の結果。次はVisual Refinement Phase。mainへMergeしない。

## 再実行

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
godot --headless --path . --script res://tests/phase3_acceptance.gd
godot --headless --path . --script res://tests/phase4_acceptance.gd
godot --headless --path . --script res://tests/phase5_acceptance.gd
godot --headless --path . --script res://tests/mvp_acceptance.gd
```

全AcceptanceのSaveは`user://tests/…`の独立ファイルを使用し、プレイヤーのSaveを変更しない。
