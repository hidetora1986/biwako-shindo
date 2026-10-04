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

MVP Phase 3 — REEL・ラインテンション・魚スタミナ・釣り上げ。Phase 1の湖と7匹の魚、Phase 2のCASTからHITを維持し、短いファイトと釣果表示を追加しています。MVP全体のAcceptanceは未完了です。

**操作:** CASTをタップ／クリック。魚が寄り、**!**が出たら画面をタップ／左クリックして**HIT!**。次に右下の**REELを長押し**します。テンションが黄色・赤、またはRUNになったら離し、安全域へ戻ったらまた巻きます。魚が疲れて近づくと自動で**CATCH!・魚名・サイズ**を表示し、再びCASTできます。巻き続けて危険域を維持するとLINE BREAK、長時間離したままではESCAPEDですが、すぐ再挑戦できます。売却・金額加算は未実装です。

## ブランチ運用

- `main`: 安定版。初期化後は直接開発せず、Acceptance 完了後の Pull Request で統合します。
- `feature/mvp-fishing`: 今回の MVP 開発ブランチ。プロジェクトと仕様書はこのブランチで追加します。
- 将来の拡張: `feature/horror-phase1`、`feature/fish-expansion`、`feature/boss` など。

## ディレクトリ構成

```text
project.godot            Godot プロジェクト設定
scenes/                 メイン・湖・魚・釣り・独立したルアーのシーン
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

Compatibility レンダラーと Nearest テクスチャフィルターを使用します。横持ちの基準画面は `640 × 360`（16:9）、PCの初期ウィンドウは `1280 × 720` です。19.5:9などの横長画面では左右の景色を広げ、HUDは中央の16:9相当の範囲に収めます。iPhone / Androidでは端末のSafe Areaも考慮します。

描画はすべてGodot内の自作仮素材です。魚の`fish_art`、ボートの`boat_art`、`data/lake/morning.tres`の色・表示深度を差し替えできます。現在は朝の0–15mの浅い水中を表示します。

`.godot/`、キャッシュ、ローカル設定、ビルド・書き出し成果物は `.gitignore` で除外します。Godot の `*.import` と `*.uid` は参照維持のため追跡対象です。共有用の `export_presets.cfg` も追跡対象ですが、書き出し設定はまだありません。

初期プロジェクトの確認:

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 5
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
godot --headless --path . --script res://tests/phase3_acceptance.gd
```

仕様と開発ルールは [ドキュメント案内](docs/README.md)、[MVP 仕様書](docs/game-design/mvp-spec.md)、[開発手順](docs/development.md) を参照してください。

Phase 1の範囲と素材の交換方法は [Phase 1仕様](docs/game-design/phase1-lake-scene.md)、検証結果は [Phase 1 Acceptance](docs/game-design/phase1-acceptance.md) に記録します。

Phase 2のキャスト・フッキング仕様は [Phase 2仕様](docs/game-design/phase2-casting.md)、検証結果は [Phase 2 Acceptance](docs/game-design/phase2-acceptance.md) を参照してください。

Phase 3の操作・テンション・魚の仮設定は [Phase 3仕様](docs/game-design/phase3-fight.md)、検証結果と実機の残課題は [Phase 3 Acceptance](docs/game-design/phase3-acceptance.md) を参照してください。
