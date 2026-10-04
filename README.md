# 琵琶湖深度 — biwako-shindo

琵琶湖を舞台とする、スマートフォン向け2Dピクセルホラー釣りゲーム。

## 開発環境

- Godot 4.x / GDScript。初期構築・起動確認には Godot 4.6.3 stable を使用。
- Git / GitHub。

## 起動方法

現在のプロジェクトは `feature/mvp-fishing` にあります。

```sh
git clone --branch feature/mvp-fishing https://github.com/hidetora1986/biwako-shindo.git
cd biwako-shindo
godot --editor --path .
```

Godot のプロジェクトマネージャーから、リポジトリ直下の `project.godot` をインポートしても起動できます。エディターで F6 は現在のシーン、F5 はプロジェクトを実行します。

## 対応プラットフォーム

- 目標: Android / iOS のスマートフォン。
- 開発時の確認: Windows / macOS / Linux の Godot エディター。
- モバイルへの書き出し設定・実機検証は今後実施します。

## 現在の開発フェーズ

初期構築 / MVP 開発準備。釣りのゲーム機能と MVP Acceptance は未完了です。

## ブランチ運用

- `main`: 安定版。初期化後は直接開発せず、Acceptance 完了後の Pull Request で統合します。
- `feature/mvp-fishing`: 今回の MVP 開発ブランチ。プロジェクトと仕様書はこのブランチで追加します。
- 将来の拡張: `feature/horror-phase1`、`feature/fish-expansion`、`feature/boss` など。

MVP 仕様書は開発ブランチの [`docs/game-design/mvp-spec.md`](https://github.com/hidetora1986/biwako-shindo/blob/feature/mvp-fishing/docs/game-design/mvp-spec.md) に保存します。
