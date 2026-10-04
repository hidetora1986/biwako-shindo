# 琵琶湖深度 — MVP 仕様書

## ステータス

MVP 開発ブランチは `feature/mvp-fishing`。現在は Phase 5 — 図鑑・永続保存・実ソナー・最初の巨大ソナー反応を実装しています。

Phase 1の範囲・Acceptance基準はユーザーの指示に基づいて確定しました。[Phase 1仕様](phase1-lake-scene.md)と[確認結果](phase1-acceptance.md)を参照してください。Phase 2の仕様は[Phase 2仕様](phase2-casting.md)、検証結果は[Phase 2 Acceptance](phase2-acceptance.md)を参照してください。Phase 3の仕様は[Phase 3仕様](phase3-fight.md)、検証結果は[Phase 3 Acceptance](phase3-acceptance.md)を参照してください。Phase 4の仕様は[Phase 4仕様](phase4-economy.md)、検証結果は[Phase 4 Acceptance](phase4-acceptance.md)を参照してください。Phase 5の仕様は[Phase 5仕様](phase5-save-sonar.md)、検証結果は[Phase 5 Acceptance](phase5-acceptance.md)を参照してください。今後の工程とMVP全体の受け入れは未完了です。この文書は初期構築の記録とフェーズ別仕様の入口です。

## ゲーム概要

- タイトル: 『琵琶湖深度』。
- ジャンル: 2D ピクセルホラー釣りゲーム。
- 目標プラットフォーム: スマートフォン（Android / iOS）。
- エンジン: Godot 4.x。初期構築では 4.6.3 stable を使用。

## 今回の初期構築範囲

1. GitHub リポジトリ `biwako-shindo` を新規作成する。
2. `main` を安定版の統合先、`feature/mvp-fishing` を今回の開発先とする。
3. リポジトリ直下に `project.godot` と起動可能な最小シーンを置く。
4. README に概要、開発環境、起動方法、対応プラットフォーム、現在の開発フェーズを記載する。
5. Godot 4 の生成ファイル、キャッシュ、ローカル設定、不要なビルド成果物を Git から除外する。
6. `scenes/`、`scripts/`、`data/`、`assets/`、`audio/`、`ui/`、`docs/` を用意する。
7. `docs/game-design/`、`docs/fish/`、`docs/equipment/`、`docs/ui/`、`docs/horror/` に仕様を保存できる構造を用意する。

初期構築では起動確認用の仮画面を用意しました。Phase 1で湖上・水中・ボート・泳ぐ魚の画面に置き換えています。Phase 2でCASTからHITまでの操作を追加しました。

## MVP 機能の実装候補

以下は提示されたコミット例に含まれる機能です。MVP の必須範囲として確定したものではありません。詳細仕様を決めてから、対象機能と判定基準を追加します。

| 機能 | コミット例 | 詳細仕様 |
| --- | --- | --- |
| 湖上・水中基礎シーンと視覚的な魚の遊泳 | `feat: implement phase 1 lake and fish scene` | [Phase 1](phase1-lake-scene.md) |
| キャスト・ルアー沈下・魚接近・ヒット | `feat: implement phase 2 casting and fish bite` | [Phase 2](phase2-casting.md) |
| 釣りに反応する魚 AI | `feat: add fish AI` | SWIMに検知・接近・BITE・HOOKEDをPhase 2で追加。正式MVP魚5種をPhase 4で追加 |
| REEL・テンション・スタミナ・釣り上げ | `feat: implement phase 3 fishing fight and landing` | [Phase 3](phase3-fight.md) |
| 正式魚・経済 | `feat: implement phase 4 economy and equipment upgrades` | [Phase 4](phase4-economy.md) |
| 装備ショップ・深度解放 | 同上 | ROD / REEL / LINE / SONAR Lv1〜3 |
| 図鑑・保存・実ソナー・最初の反応 | `feat: implement phase 5 save encyclopedia sonar and anomaly` | [Phase 5](phase5-save-sonar.md) |
| 今後のホラー拡張 | 未定 | Phase 5のソナー反応以外は未実装 |

## 詳細仕様で確定する事項

- MVP に含める機能とプレイの開始・終了条件。
- スマートフォンの対象端末・OSと、Phase 5以降のタッチ操作。Phase 1の画面は横持ち640×360。
- 魚種、出現条件、魚 AI、釣り上げ・失敗条件。
- リール・テンションの挙動と調整値。
- 経済・装備・ショップの対象範囲とデータ。
- ソナーの表示・操作と異常イベントの条件。
- セーブ、音声、素材、対象端末・OS の範囲。

各分野の仕様は対応する `docs/` 配下の文書へ保存し、この文書から参照します。

## 初期構築の確認項目

- [x] Godot 4.x でプロジェクトをインポートできる。
- [x] 起動シーンをエラーなくヘッドレス実行できる。
- [x] 指定されたディレクトリと README が用意されている。
- [x] キャッシュ・ローカル設定・書き出し成果物が Git の対象外になっている。
- [x] ローカルに `main` と `feature/mvp-fishing` が存在し、プロジェクトの追加は開発ブランチにある。
- [x] GitHub にリポジトリと両ブランチが作成され、初期反映のHEAD一致を確認している。

初期確認日: 2026-10-04。Godot 4.6.3 stable のインポートとヘッドレス起動、Git の除外設定、必要なディレクトリ、文書内のローカルリンクを確認済み。スマートフォンの実機確認とゲーム機能の Acceptance は未実施です。

## MVP Acceptance と main への統合

**Phase 6正式MVP Acceptance: PASS（PC上の自動テスト・実描画・タッチ入力・Safe Areaシミュレーションの範囲）。**

- [x] Phase 1〜6のAcceptance基準と検証結果を記録。
- [x] 21捕獲＋2失敗、購入・図鑑・保存復元、Phase 1〜5全回帰を確認。
- [x] 16:9／19.5:9／20:9、640×360、タッチ領域・Safe Areaを確認。
- [ ] iPhone／Android実機の起動・操作感・性能・振動・書き出し。

結果と限界は[Phase 6 Acceptance](phase6-mvp-acceptance.md)を参照。今回の指示に従い、Acceptance後もmainへMergeしない。次はVisual Refinement Phaseで、統合は別途指示を待つ。

## 将来の開発ブランチ

- `feature/horror-phase1`
- `feature/fish-expansion`
- `feature/boss`

これらは将来の拡張に使用できる命名例です。今回は作成せず、各機能の開発開始時に安定版の `main` から作成します。
