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

## ディレクトリ構成

```text
project.godot            Godot プロジェクト設定
scenes/                 シーン（main.tscn は起動確認用）
scripts/                GDScript
data/                   魚・装備・経済などのゲームデータ
assets/                 ピクセルアート・フォントなど
audio/                  BGM・効果音
ui/                     UI シーン・テーマ
docs/
  game-design/          ゲーム設計・MVP 仕様書
  fish/                 魚の仕様
  equipment/            装備の仕様
  ui/                   画面・操作の仕様
  horror/               ホラー演出・イベントの仕様
```

## 初期設定

Compatibility レンダラーと Nearest テクスチャフィルターを使用します。起動確認用の画面は仮の縦向き `360 × 640` です。ゲーム画面の向き、解像度、操作方法は詳細仕様の確定時に見直します。

`.godot/`、キャッシュ、ローカル設定、ビルド・書き出し成果物は `.gitignore` で除外します。Godot の `*.import` と `*.uid` は参照維持のため追跡対象です。共有用の `export_presets.cfg` も追跡対象ですが、書き出し設定はまだありません。

初期プロジェクトの確認:

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 5
```

仕様と開発ルールは [ドキュメント案内](docs/README.md)、[MVP 仕様書](docs/game-design/mvp-spec.md)、[開発手順](docs/development.md) を参照してください。
