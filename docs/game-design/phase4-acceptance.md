# MVP Phase 4 Acceptance

確認日: 2026-10-04。Repository: `hidetora1986/biwako-shindo`。Branch: `feature/mvp-fishing`。Godot: **4.6.3.stable.official.7d41c59c4**。

開始HEAD: `60d89e818a42d653f6d469115d5fa56dd9a17ddf`。mainは`4626fa329f1aa488ed90f707ac2757f2d771c090`のまま。mainへの実装・Merge・PR Merge・MVP全体のAcceptanceは行わない。

## 結果

| Acceptance | 結果 | 確認内容 |
| --- | --- | --- |
| Fish Data | PASS | 既存Fight ResourceにID・生息深度・サイズ・価格・rarity・スタミナ・pull_power・説明を統合 |
| 5 Fish Species | PASS | 正式5種が同時に存在し、それぞれの深度範囲に初期配置 |
| Fish Size | PASS | 各種101サンプルで指定範囲・小数1桁、HITから釣果までサイズ保持 |
| Price Calculation | PASS | 上下限・範囲外clamp・101段階の単調増加を種ごとに確認 |
| Catch Result | PASS | CATCH・魚・日本語名・サイズ・加算額を約1.5秒表示 |
| Auto Sell | PASS | CATCH時のみ売却、同じ通番・二重CATCHで再加算なし |
| Money Add | PASS | 売値だけ加算。開始¥0、失敗では加算なし |
| Money HUD | PASS | 財布と釣果価格が即一致、桁区切りで表示 |
| Rod Lv1–3 | PASS | 60／100／180cm、価格0／4,000／18,000。大型通常魚もLv1で捕獲可能 |
| Reel Lv1–3 | PASS | ×1.00／1.15／1.30、価格0／3,000／15,000。進行・疲労へ適用 |
| Line Lv1–3 | PASS | 10／25／50m、価格0／2,500／12,000。ルアーへ即適用 |
| Sonar Lv1–3 | PASS | 15／30／50m、価格0／5,000／25,000。性能と機能段階を管理 |
| Shop Open | PASS | タッチ・マウス1回で開き、魚・ルアー・釣り入力・新規BITEを停止 |
| Shop Close | PASS | ×で復帰、沈下中に開閉しても同じキャストからCATCHまで継続 |
| Purchase | PASS | 実際の購入タッチで価格を引き、Lv更新。連打・古いLvの購入を拒否 |
| Insufficient Money | PASS | Disabled表示、残高・Lvが変化せず負数にならない |
| Auto Equip | PASS | 別の装備操作なしでライン・リール・ロッド効果を適用 |
| Max Level | PASS | 全カテゴリLv3超過不可、実ショップのMAX表示・Disabled確認 |
| Depth Limit | PASS | 100m表示用テスト湖でも10／25／50mで沈下停止 |
| Depth Unlock | PASS | 10m→25m、25m→50mの通知と性能更新。ショップ停止中にも表示 |
| Repeated Fishing Economy Loop | PASS | 強制捕獲・資金注入なしで10匹連続、途中3購入と再釣り。ノード数が安定 |
| 16:9 | PASS | 実描画・マウス購入とSafe Area・タッチテスト |
| 19.5:9 | PASS | 横長実描画、同じ成長ループとUI配置 |
| 320px表示 | PASS | 44pxの購入・閉じる領域、文字拡大、ショップスクロールで全カテゴリへ到達 |
| Project Import | PASS | Godot 4.6.3でインポート |
| Headless Launch | PASS | 120フレーム起動、重大Errorなし |
| Critical Errors | 0 | 最終インポート・起動・Acceptance・ネイティブ描画ログ |
| Phase 1 Regression | PASS | 湖・水面・ボート・7匹の遊泳・反転・比率・素材交換 |
| Phase 2 Regression | PASS | 57項目、36キャスト、HITまで平均5.27秒・最大5.27秒 |
| Phase 3 Regression | PASS | 109項目、5種連続のファイト・CATCH・失敗・入力所有権・復帰 |

`tests/phase4_acceptance.gd`の**196項目すべてPASS**。10匹の売却総額は¥11,590。1匹目¥1,402、2匹目¥1,203で累計¥2,605となり、**2匹でラインLv2（¥2,500）を購入し、残高¥105**。続いてリールLv2・ロッドLv2も購入しながら釣りを継続できた。

テストのLv3／MAX境界だけは資金を与えた独立fixtureで確認する。10匹連続の経済ループは通常のCAST・検知・接近・HOOK・ファイト・CATCHを使い、魚種の強制変更や捕獲・資金注入を行わない。

Phase 2の接近検査は、ルアーが魚の予約時に待機するため、すでに接近完了済みのケースも許容する。Phase 3の「所持金¥0のまま」という旧スコープ検査は、Phase 4の自動売却後の財布維持検査へ置換した。その他の従来の成功・失敗・状態・入力・UIの検査は維持する。

## 再実行

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
godot --headless --path . --script res://tests/phase3_acceptance.gd
godot --headless --path . --script res://tests/phase4_acceptance.gd
```

Linuxネイティブ起動ではXvfb＋Compatibility／Mesa llvmpipeを使用。16:9・19.5:9双方で実際のマウスCAST→2匹捕獲→SHOP→ライン購入→通知→再開を確認し、湖、釣果価格、残高不足、購入可能、深度解放、購入後の画面を撮影した。320px表示のショップ上部・下部も描画確認した。ソフトウェアGPUのV-Sync非対応警告が1件あるが、GodotのErrorはない。

## 残課題と範囲

iPhone／Android実機、端末のハプティクス、書き出し・署名は未検証。比率・タッチ・Safe AreaはGodotのViewport入力とシミュレーション、およびLinux描画で確認した。

現在の景色は0–15m。25m・50mの性能値・上限・解放は実装済みだが、それらの深い水中背景と魚は後工程。ソナーの実魚同期、サイズ・魚種推定、図鑑、永続セーブ、ホラーは実装していない。

次の作業: **MVP Phase 5 — 魚図鑑・セーブ・ソナー機能拡張・最初の異常反応の実装指示待ち**。
