# Playtest Feedback v1

Base: Web `2363e05fa87d02433474189868d0b583b8d70154`. Dedicated branch: `feature/playtest-feedback-v1`.
RC1 Human Playtest commit `a296c41e9835d1778a576b67c59a3e79e6a3aff9` is cherry-picked; README keeps both instructions, Web font/render/layout compatibility stays intact. `main` and `release/rc1` stay unchanged.

## 操作

右下の主操作が **CAST → HOOK! → REEL** に切り替わる。HOOKは専用ボタンのみ（PCクリックも対応）。通常1.5秒、No.15のSlow Bite後は既存1.8秒。No.00は接触のままでHOOKは出ない。

アタリ前・接近魚がいない状態では同じボタンに **回収** が出る。魚のいない水域でもラインを回収してREADYへ戻り、AREAで移動できる。BITE/FIGHT/Choice/Ending中の回収は不可。

**AREA** はライン回収済みのREADYだけ。SHOP/BOOK/異常イベントとは同時に開けない。マップ中はゲームを一時停止。解放済みの行をタップすると1.4秒の船移動。価格、Fight設定、既存Ending条件は変更していない。

| エリア | 解放 | 深度帯 | 魚 |
|---|---|---|---|
| 南湖沿岸 | 初期 | 0–30m | No.01–07 |
| 北湖沿岸 | LINE Lv3 | 15–85m | No.06–13 |
| 北湖中央 | No.10発見 + LINE Lv4 | 50–120m | No.11–15 |

エリア上限とLINE上限の小さい方が有効。No.06–07、No.11–13は隣接エリアで重なる。No.15とNo.00は北湖中央だけで、従来の装備／夜／進行条件も必要。魚は既存7ノードを再利用する。到着時に深度帯・魚・ソナー・岸の見え方・HUDを更新する。

## セーブポイント

湖HUDの常設SAVEボタンとSAVE POINT表記は非表示。手動保存はREADY時にAREAを開き、「セーブ」をタップする。保存完了は端に小さく0.7秒だけ表示し、湖・魚を覆わない。到着時の自動保存に加え、捕獲・購入・Choice・Ending等の既存Auto Saveを維持する。

`save_version=1`へ`current_area`を追加。古いSaveは南湖沿岸で再開し、既存所持金・装備・図鑑・Boss／Hiddenフラグを維持。エリア解放を進行状態から再計算するため、深い進行の旧Saveでも北へ移動して続行できる。不正なエリア／未解放エリアは南湖へフォールバック。Loadだけではファイルを書き換えない。

ネイティブは既存のatomic write/rename成功後にSAVED。WebはSAVING…を表示し、実際のIndexedDBの`FILE_DATA`に同一スナップショットが保存されたことを確認してからSAVED。確認中は釣り・購入・移動を競合させない。8秒以内に確認できない場合やファイル書き込み失敗はSAVE FAILED。プライベートブラウズ／保存領域削除での永久保持は保証しない。SAVEDを確認してからReload／終了する。

## 計測

RC1のDebug限定・明示opt-in計測を維持。通常のWeb ReleaseにはDebug操作を追加しない。

追加イベント: `FIRST_HOOK_BUTTON_SUCCESS`, `FIRST_AREA_MOVE`, `FIRST_MANUAL_SAVE`, `NORTH_SHORE_ENTERED`, `NORTH_CENTER_ENTERED`。各イベントの既存テレメトリーに`current_area`も記録する。人間の評価と実測プレイ時間は自動PASSにしない。

## 検証

```sh
godot --headless --path . --script tests/playtest_feedback_acceptance.gd
godot --headless --path . --script tests/playtest_feedback_telemetry.gd
```

旧Regressionの任意画面HOOKとエリアをまたいだ直接深度切替は、専用ボタン入力と実際の船移動へ変更している。価格・装備性能・Fight時間・深度データ・Boss/Hidden条件の既存assertionsは維持。

結果は `playtest-feedback-results.json`。ネイティブのFull Game Contact/Cut/Sell、既存Phase 1–5/MVP/Visual/Midgame/Lategame/Boss/Hidden/RC1/TelemetryのRegressionを含む。WebはChromiumの疑似タッチ＋本物のIndexedDBによる捕獲／保存／エリア復元の検証。エリア解放テストには別のブラウザ内保存Fixtureも使用し、Webで全編を人間が遊んだという意味ではない。実機iPhone Safari / Android Chromeは再プレイ確認が必要。

公開先: https://hidetora1986.github.io/biwako-shindo/ 。Feature検証後のみ`release/web-test`をfast-forwardして既存Pages workflowで更新する。Merge commit／force push／main Mergeは行わない。
