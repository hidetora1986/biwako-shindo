# RC1 known issues

RC1 Status: **NOT READY**。機能テストの合格と90分の体験の成立は別の判定。

## Release Blocker（1件）

**B01 — ペーシング目標未達。** 固定Seedの全編通しはMain 28匹／実ゲーム18.50分、Hidden 30匹／20.15分。学習・読書・探索・失敗・再挑戦を分離して加算したモデルでもMain **44.99分**、Hidden **55.46分**。要求60〜80分／80〜100分へ届かない。1匹の操作時間と1〜3匹で強化する既存テンポを壊す待機・価格インフレは加えていない。新規大型機能なしで90分を保証できる根拠がなく、READYにしない。人間の通しプレイで探索時間と飽きの有無を測り、目標時間／既存進行の調整を判断する必要がある。

## Known Non-blockers（4件）

- **N01 AudioはPlaceholder。** BGM未導入。ノックとHidden巻き上げの自作WAVのみ。ゲーム上は低音量固定で重複ノード生成がなく、巻き上げ終了時に停止する。実機での耳触り・クリックノイズ・音量は未検証。
- **N02 Mobile Export環境不足。** Android SDK／Godot Export Templateなし。iOSはLinuxでXcode・署名環境なし。Android／iOS ExportともBLOCKED。公開用アイコン、ストア素材、署名をまだ設定していない。
- **N03 Physical Mobile QA未実施。** ノッチ／Dynamic Island／ホームインジケータはSafe Areaと疑似領域で検証。実端末の指操作、ハプティクス、熱・バッテリー・GPU性能、OSフォントの日本語Fallbackは未確認。PCのCompatibility描画とイベント投入を実機PASSに読み替えない。
- **N04 保存障害のユーザー通知が未実装。** Atomic writeと`last_error`で失敗を識別できるが、ストレージ満杯・権限拒否・将来Save Versionによる保存保護時の正式UI通知はない。将来Versionの元ファイルは上書きせず保護する。今回の耐久結果は書込可能な`user://tests/`環境での検証。

## Manual test required

Fishing Feel、Horror Pacing、No.15 Feel、No.00 Feel、90分の人間の通しプレイ。成功率85%／70%／65%はペーシングモデルの仮定であり、初見プレイヤーの実測値ではない。

クラッシュ・破損・意図しないSoftlock・Ending不能・重大な画面比率崩れは、実施した自動／PC描画テストの範囲では0件。
