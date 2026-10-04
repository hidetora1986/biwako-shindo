# MVP Phase 5 Acceptance

確認日: 2026-10-04。Repository: `hidetora1986/biwako-shindo`。Branch: `feature/mvp-fishing`。Godot: **4.6.3.stable.official.7d41c59c4**。

開始HEADは`401986a6f6be5cf6d7d64813f82020a2fd8b4974`。Phase 5コードがない状態から新規実装した。mainは`4626fa329f1aa488ed90f707ac2757f2d771c090`を維持し、Merge・PR Merge・MVP全体のAcceptanceを行わない。

## 実在する成果物

- `scenes/ui/fish_book.tscn`、`scripts/ui/fish_book.gd`: 5種の図鑑・未発見表示・捕獲記録。
- `scripts/save/save_manager.gd`: JSON version 1の保存・復元・耐性。
- `scripts/ui/sonar.gd`: 実魚の深度・探知範囲・Lv別情報。
- `scripts/fishing/sonar_anomaly.gd`: 0.6秒のソナー内反応。
- `scripts/economy/game_progress.gd`: 記録・`anomaly_seen`・待ち回数。
- `tests/phase5_acceptance.gd`: **105項目すべてPASS**。

## 確認結果

| Acceptance | 結果 | 確認内容 |
| --- | --- | --- |
| Fish Book Open | PASS | 実タッチ／マウスで開き、CAST・REEL・SHOP・新規BITEを停止 |
| Fish Book Close | PASS | ×で復帰、停止したキャストからCATCHまで継続 |
| Undiscovered Fish | PASS | 5種の番号・???・未発見。名前・説明・BESTを隠す |
| New Fish Discovery | PASS | 実釣の初回CATCHにNEW!、次回は非表示 |
| Caught Count | PASS | 捕獲ごとに増加、二重CATCHでは増えない |
| Best Size | PASS | 42.6→30.0→55.0cmの捕獲で42.6→42.6→55.0cmを保持 |
| Save Create | PASS | 捕獲・財布・記録を1回の原子的保存にまとめる |
| Save Load | PASS | 別Sceneと別GodotプロセスでJSONを読み直す |
| Money Restore | PASS | 所持金とHUDを復元 |
| Equipment Restore | PASS | 4カテゴリLv3のround-trip、実シーンのライン性能とソナーLvを即適用 |
| Fish Records Restore | PASS | 発見・捕獲数・BESTを復元。再捕獲でNEW!を再表示しない |
| Missing Field Fallback | PASS | 正常な値は保持し、欠落項目ごとにdefault |
| Invalid / Broken / Old Save | PASS | 壊れたJSON、配列、不正型・負数・Lv・サイズ、未対応versionから安全に復帰。ロード時に上書きなし |
| Save Version | PASS | version 1と指定スキーマを保持 |
| Auto Save | PASS | 購入・記録・異常完了・待ち回数で保存。待機フレームと図鑑開閉は保存しない |
| Sonar Fish Sync | PASS | 実在7匹だけのinstance ID・深度を参照。非表示魚は除外 |
| Sonar Depth Sync | PASS | 深度増加で魚影が下へ移動 |
| Sonar Lv1 | PASS | 15m、魚影のみ。サイズ・魚種名なし |
| Sonar Lv2 | PASS | 30m、SMALL／MEDIUM／LARGE。名前なし |
| Sonar Lv3 | PASS | 50m、既知の魚種名。未発見の名前なし |
| Sonar Depth Limit | PASS | 15／30／50mちょうどを含み、各上限を0.1m超えた魚を除外 |
| Anomaly Trigger | PASS | 実ソナーLv2購入後の3回の通常釣りから発生。購入直後・待ち時間だけでは発生しない |
| Anomaly State Gates | PASS | SHOP・図鑑・CATCH・FIGHT中には起動しない |
| Anomaly Display | PASS | 通常影の8〜9倍を0.6秒だけソナーに表示。通常魚は泳ぎ続け、巨大湖上ノードを生成しない |
| Anomaly One-Time | PASS | 完了後は再入力・再キャストで再発しない |
| Anomaly Save Restore | PASS | 別プロセス起動でもseen=trueで再発しない |
| Debug Anomaly Trigger | PASS | debug callable、Lv2・状態・一度限りを守り、待ち回数だけ省略。正式UIに追加なし |
| PC Modal / Purchase | PASS | 図鑑を閉じ、ショップの4段目をスクロールして実マウスでソナー購入 |
| 16:9 | PASS | 実描画、図鑑・ソナー・NEW!・購入・異常反応 |
| 19.5:9 | PASS | 横長実描画、同じ動作とSafe Area |
| 320px | PASS | 図鑑の文字拡大・44px閉じる領域・全5種へスクロール・同じキャスト再開 |
| Phase 1 Regression | PASS | 湖・水面・ボート・7匹・素材交換・比率を維持 |
| Phase 2 Regression | PASS | 57項目、36キャスト、平均／最大5.27秒でHIT |
| Phase 3 Regression | PASS | 109項目、5種のファイト・ランディング・失敗・反復 |
| Phase 4 Regression | PASS | 196項目、10匹の経済ループ、最初の2匹で強化、購入と深度制限 |
| Godot Import | PASS | Godot 4.6.3でインポート |
| Headless Launch | PASS | 120フレーム起動 |
| Critical Errors | 0 | 最終インポート・起動・全Acceptance・実描画・別プロセス復元 |

既存のAcceptanceでは、各Sceneへ新しい`user://tests/…`のSaveパスを渡す変更だけを追加した。以前の釣り・ファイト・経済の判定を弱めず、テスト順序や本番の財布・装備・図鑑に依存しない。

## 実描画と別プロセス復元

Xvfb＋GodotのCompatibility／Mesa llvmpipeで16:9・19.5:9を起動し、実際のマウス操作で図鑑の開閉、初回捕獲、ソナーLv2／3購入を確認した。購入後に3回実釣して巨大反応を確認し、Lv3では捕獲済みのブラックバス名を表示した。UIの性能確認用資金は独立したテストSaveだけに与えた。Phase 4の経済回帰は資金注入なし。

両比率で4匹捕獲、BEST 47.0cm、ソナーLv3、`anomaly_seen = true`を保存。別Godotプロセスから読み込み、所持金¥5,599・装備・記録・一度限りフラグが一致した。320pxの図鑑上部・下部も描画確認した。

実描画で発見した図鑑ボタンとショップの重なりは、モーダルを通常HUDより上へ配置して修正した。ソフトウェアGPUのV-Sync非対応警告はあるが、最終実行にGodotのErrorはない。

## 再実行と検証範囲

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
godot --headless --path . --script res://tests/phase3_acceptance.gd
godot --headless --path . --script res://tests/phase4_acceptance.gd
godot --headless --path . --script res://tests/phase5_acceptance.gd
```

iPhone／Android実機、書き出し・署名は未検証。比率・タッチはViewport入力とSafe Areaシミュレーション、描画・マウス・別プロセスSave復元はLinuxで確認した。No.06以降・ボス・No.00・水中巨大魚・追加のホラー・BGM変更は実装していない。
