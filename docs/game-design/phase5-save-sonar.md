# MVP Phase 5 — 魚図鑑・永続Save・実ソナー・最初の異常反応

Phase 4の`401986a6f6be5cf6d7d64813f82020a2fd8b4974`から`feature/mvp-fishing`に追加する。Godot 4.6.3。Phase 1〜4の景色、操作、ファイト、自動売却、購入、価格を維持する。

## 図鑑と捕獲記録

湖上のFISH BOOKで開き、×で閉じる。対象は既存ResourceのNo.01ブルーギル、No.02ブラックバス、No.03フナ、No.04ナマズ、No.05ビワマスだけ。`scenes/ui/fish_book.tscn`と`scripts/ui/fish_book.gd`にUIを分離する。

未捕獲は番号・`???`・`未発見`だけを表示し、魚名・説明・捕獲数・BEST SIZEを隠す。捕獲後は魚名、捕獲数、最大サイズ（小数1桁）、説明文を表示する。初回CATCHには追加でNEW!を表示する。

GameProgressの`fish_records`はIDごとに`discovered`、`caught_count`、`best_size_cm`を保持する。自動売却と捕獲記録を同じトランザクションで更新し、一度だけ通知・保存する。同じCATCH／CAST通番の再入力は金額だけでなく記録も増やさない。小さい魚を捕まえても最大サイズは下がらない。

図鑑はREADY・沈下・待機中に開ける。飛行・アタリ・HIT・ファイト・釣り上げ・結果・RESET中は無効。図鑑中はSceneTreeを停止し、CAST・REEL・SHOP・魚AI・新規BITEを停止する。閉じると停止前のキャスト・深度から復帰する。ショップと図鑑を同時に開かない。

## 保存と復元

`scripts/save/save_manager.gd`のSaveManagerが`user://biwako-shindo/save.json`を管理する。起動時、HUD・装備効果・図鑑・ソナーを接続する前に読み込む。新規ゲームは所持金¥0、全装備Lv1、全魚未発見、`anomaly_seen = false`。

保存対象:

| キー | 内容 |
| --- | --- |
| save_version | 1 |
| money | 所持金 |
| rod_level / reel_level / line_level / sonar_level | 各装備の現在Lv |
| fish_discovered | 魚ID → 発見済みbool |
| fish_caught_count | 魚ID → 捕獲数 |
| fish_best_size | 魚ID → 最大サイズcm |
| anomaly_seen | 異常反応が完了したか |
| sonar_sessions | ソナーLv2以降の完了した通常釣り回数（0〜3） |

捕獲・装備購入・図鑑記録更新・異常終了と、その発生待ち回数更新で自動保存する。毎フレームや図鑑開閉では保存しない。JSONを同じディレクトリの`.tmp`へ書き、flush・close後にrenameして前のファイルを置換する。保存処理はboolと`last_error`で成否を返し、書き込み失敗でもゲームをクラッシュさせない。

項目欠落は項目ごとのdefault、不正な型・負数・不正Lv・不正サイズはdefaultへ戻す。捕獲数がある旧形式の記録は発見済みとして扱える。未知の魚IDは無視する。壊れたJSON・配列・未対応の古い／将来バージョン・1MiBを超えるファイルはdefaultへfallbackし、読み込み自体では元ファイルを上書きしない。将来のMigrationはload内のversion判定へ追加できる。

Saveはリポジトリに含めない。AcceptanceはControllerの`save_path`へ独立した`user://tests/…`を指定し、プレイヤーのSaveを読まない・書かない。

## 実ソナー

`scripts/ui/sonar.gd`のSonarDisplayへ置換した。過去テストとの互換のため、シーンのノード名`SonarPlaceholder`は保持するが、静的な魚影は描かない。水中の実Fishノードを約0.15秒間隔で読み、魚の深度を探知深度に対する縦位置へ、横位置をパネル内へ変換する。捕獲済みで非表示の魚とランディング中の魚、探知外の魚は除く。ファイト中の魚も実際の深度を更新する。

| Lv | 探知深度 | 表示 |
| --- | --- | --- |
| 1 | 15m | 実魚の魚影のみ。サイズ・名前なし |
| 2 | 30m | 魚影とSMALL／MEDIUM／LARGEのサイズ推定 |
| 3 | 50m | サイズ推定に加え、捕獲済みの魚種名を表示。未発見の名前は隠す |

サイズが確定済みならその値、まだ確定していなければ種のサイズ範囲の中央値から粗いサイズを推定する。25cm未満はSMALL、50cm未満はMEDIUM、それ以上はLARGE。2秒ごとに注目魚を切り替え、枠で示した魚の推定をパネル下部へ表示し、狭い画面で全魚の名前を重ねない。

## 最初の巨大反応

`scripts/fishing/sonar_anomaly.gd`のSonarAnomalyが担当する。ソナーLv2を購入すると待ち回数を0に戻す。購入直後や単なる待ち時間では発生しない。その後、通常の捕獲または失敗からRESETする釣りを**3回完了**し、次のREADY状態で発生する。

条件は`sonar_level >= 2`、未完了、READY、SHOP・図鑑外。アタリ、HIT、FIGHT、CATCH中には発生しない。短い反応中はモーダルを開けず、CASTと魚の遊泳は継続できる。

ソナープロットの最下部を、通常の5px魚影の約8〜9倍の反応が**0.6秒**で横切る。反応はソナー内にクリップし、水中の巨大魚・新しい魚種・説明テキスト・警告・暗転・赤い目・音楽変更・ジャンプスケア・ノックを追加しない。

完了時に即通常ソナーへ戻り、`anomaly_seen = true`を保存する。再起動・追加キャスト・再購入で再発しない。反応途中で終了した場合は未完了なので、保存済みの待ち回数から次回READYで完了を再試行できる。

Acceptance用`FishingController.debug_trigger_anomaly()`はdebug buildで待ち回数だけを省略する。Lv2以上・READY・モーダル外・未完了の条件を残し、正式ゲームUIにはボタンや警告を出さない。

## 検証と対象外

[Phase 5 Acceptance](phase5-acceptance.md)と`tests/phase5_acceptance.gd`を参照。魚種追加、No.06以降、ボス、No.00、水中の巨大魚、追加のホラー演出は実装しない。mainへの変更・Merge・PR Mergeは行わない。
