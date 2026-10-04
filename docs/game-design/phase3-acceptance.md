# MVP Phase 3 — Acceptance確認結果

確認日: 2026-10-04。Godot **4.6.3 stable**。対象ブランチ: `feature/mvp-fishing`。
開始HEAD: `3fbd419f86f62c39865dd667a1c0c4f295225e1b`。

## 結果

| 項目 | 結果 | 確認内容 |
| --- | --- | --- |
| REEL | PASS | HITの0.3秒後にFIGHTING。ファイト中のみ右下のREEL・テンション・スタミナHUDを表示 |
| Long Press | PASS | Viewportへの実Touch/Mouseイベントで長押し。ボタンの押下表示が維持される |
| Release | PASS | ボタン外での指の解除、ドラッグ離脱、PC解除、フォーカス喪失で巻きを停止 |
| Tension Increase | PASS | REEL中に上昇。RUNで追加上昇 |
| Tension Recovery | PASS | 離すと低下。RUN中も回復 |
| SAFE Zone | PASS | SAFEのスタミナ消費がLOWの5倍以上。20/70/90の境界と色・表示を確認 |
| Fish Stamina | PASS | 魚の値とモデルが一致。REEL以外は減少せず、0より小さくならない |
| Fish Run | PASS | 0.5秒のWARNING、RUN、魚の方向反転・後退、距離増加、RELEASE表示を確認 |
| Line Break | PASS | 100到達で即失敗しない。解除で救済。98以上の連続維持でLINE BREAK、その後再CAST |
| Fish Escape | PASS | 短い解除は許容。低テンションが長く続くとESCAPED、その後再CAST |
| Landing | PASS | スタミナ0と近距離の両方を要求。水面へ引き上げ、釣果パネル前のしぶきを確認 |
| Catch Result | PASS | CATCH!、該当魚のTexture、日本語名、範囲内のcmサイズ。保持値と表示が一致 |
| Reset | PASS | 成功・失敗後、RESET入力ロックを経てCASTを再有効化 |
| Repeated Fishing Loop | PASS | 同一シーンで5種を5回連続CAST/HIT/FIGHT/CATCH/CAST。ノード数と7匹を維持 |
| 16:9 | PASS | 1280×720、640×360論理画面。入力・HUD・実描画・釣果を確認 |
| 19.5:9 | PASS | 1560×720、780×360論理画面。同じファイトと釣果を確認 |
| 20:9 / 320px幅 | PASS | 模擬Safe Area、ボタン44物理px以上、HUDとボタン非重複を検証 |
| Resize | PASS | ファイト中リサイズでもスタミナ・状態・ライン接続を維持。変更後も指を離せる |
| Input Conflicts | PASS | 他の指・タッチ由来マウスで所有者を変更しない。ファイトCAST、再フック、結果REEL、RESET CASTを拒否 |
| Project Import | PASS | Godot 4.6.3、終了コード0、重大Error 0 |
| Headless Launch | PASS | 通常メインシーン180フレーム、終了コード0、重大Error 0 |
| Critical Errors | 0 | 最終インポート・通常起動・3つのAcceptance・実描画のログで確認 |

Phase 3の統合テストは**109項目PASS、失敗0**。Phase 1の**22項目**、Phase 2の**57項目**も回帰PASS。Phase 2テストでは撤去した暫定リセットの期待値をファイト引き継ぎ・釣果後リセットへ更新し、キャスト・沈下・検知・BITE・HIT・MISSの検証は維持しました。テスト起動時も明示的に横画面を指定します。

## ファイト時間

以下はRUNまたはテンション76以上で離し、RUN終了かつ45以下で再び巻く自動入力の値です。ファイト開始からランディング条件成立までを計測し、釣果演出時間を含めません。

| 魚 | 実測 | 目標 |
| --- | --- | --- |
| ブルーギル | 約2.68秒 | 2–4秒 |
| フナ | 約4.13秒 | 3–5秒 |
| ブラックバス | 約4.82秒 | 4–7秒 |
| ビワマス | 約5.75秒 | 5–8秒 |
| ナマズ | 約8.17秒 | 6–10秒 |

追加の20試行では、RUNまたはテンション78以上への反応を0.3/0.6/1.0/1.4秒遅らせた操作を5種で検証。**18/20試行で釣り上げ**、最長約9.93秒でした。これは定義した入力ポリシーのシミュレーションであり、実際の初見プレイヤー成功率や操作の気持ちよさを測った値ではありません。

## 再現方法

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 180
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
godot --headless --path . --script res://tests/phase3_acceptance.gd
```

PCでF5実行。CAST → !で左クリック → HIT! → REELを左クリック長押し。黄色・赤またはRUNで離し、SAFEへ戻ってから再び巻き、CATCH!を確認します。離さず危険テンションを維持するとLINE BREAK、ずっと離しているとESCAPED。その後どちらもCASTを受け付けます。

## 実描画と残課題

Linuxの仮想ディスプレイ・ソフトウェアGPU、OpenGL Compatibilityでゲームを動かし、16:9・19.5:9でREADY、REEL押下、WARNING、RUN、CATCHを確認。16:9でLINE BREAKとESCAPEDも確認しました。演出を確実に確認する描画テストでは既存のバスを検知対象に絞っています。正式な魚データは追加せず、実際のシーンの魚・入力・ファイトを使用しました。

- iPhone / Android実機での長押し、ドラッグ、多点タッチ、フォーカス復帰、Safe Area、振動、FPSは未検証。モバイル書き出しも未実施。
- ファイトの「気持ちよさ」と初見80–90%の成功率は、実機で人が遊んで確認・調整する必要があります。
- 現在の5種は仮の名前・サイズ・ファイト設定と既存3種類の仮画像。正式素材・生態・データ体系は後工程。
- 追加の有料／外部画像、重量Shader、Particle大量生成はなし。継続中にノード生成せず、魚・ルアー・HUDを再利用します。
- 所持金¥0、ソナーの静的表示を維持。経済、売却、ショップ、装備、図鑑、セーブ、ホラーを実装していません。

MVP全体のAcceptanceとmainへのMergeは未実施です。次の作業はMVP Phase 4 — 魚データ・売値・自動売却・所持金・装備強化の実装指示待ち。
