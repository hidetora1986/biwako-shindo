# 琵琶湖深度 — biwako-shindo

琵琶湖を舞台とする、スマートフォン向け2Dピクセルホラー釣りゲーム。

## 開発環境

- Godot 4.x / GDScript。初期構築・起動確認には Godot 4.6.3 stable を使用。
- Git / GitHub。

## 起動方法

今回の深度拡張は `feature/midgame-depth-v1` にあります。完成したMVPとビジュアル版は、それぞれ元のブランチに維持しています。

```sh
git clone --branch feature/midgame-depth-v1 https://github.com/hidetora1986/biwako-shindo.git
cd biwako-shindo
godot --editor --path .
```

Godot のプロジェクトマネージャーから、リポジトリ直下の `project.godot` をインポートしても起動できます。エディターで F6 は現在のシーン、F5 はプロジェクトを実行します。

## 対応プラットフォーム

- 目標: Android / iOS のスマートフォン。
- 開発時の確認: Windows / macOS / Linux の Godot エディター。
- モバイルへの書き出し設定・実機検証は今後実施します。

## 現在の開発フェーズ

Content Expansion Phase 1 — 実プレイを0〜50mへ拡張し、No.06〜10、名称不明種Aの「売る／戻す」、10種図鑑、Lv4装備と旧Save互換を追加。main・MVP・ビジュアル版のブランチは変更しません。

**操作:** CASTをタップ／クリック。魚が寄り、**!**が出たら画面をタップ／左クリックして**HIT!**。次に右下の**REELを長押し**します。テンションが黄色・赤、またはRUNになったら離し、安全域へ戻ったらまた巻きます。魚が疲れて近づくと自動で**CATCH!・魚名・サイズ・売値**を表示し、再びCASTできます。巻き続けて危険域を維持するとLINE BREAK、長時間離したままではESCAPEDですが、すぐ再挑戦できます。No.01〜09は自動売却され、左上の所持金が増えます。名称不明種AはCATCH後に「売る／戻す」を選びます。戻した場合は所持金が増えず、捕獲記録は残ります。**SHOP**を開き、ロッド・リール・ライン・ソナーの次Lvを購入すると即装備されます。ラインLv1は10mまで、Lv2・3の購入で25m・50mを解放します。CASTの上の**DEPTH**をタップし、解放済みの0〜15m・15〜30m・30〜50mを切り替えます。ラインLv2では15〜25mまで、Lv3では50mまで遊べます。名称不明種Aを発見するとLv4装備がSHOPに出ます。ラインLv4の85mは次Phaseへの準備で、今回の実プレイ上限は50mです。ショップ中は釣りが停止し、×で再開します。**FISH BOOK**で捕獲数・BEST SIZEを確認できます。所持金・装備・図鑑は`user://biwako-shindo/save.json`に自動保存され、次の起動時に復元されます。初回の魚にはNEW!を表示します。

## ブランチ運用

- `main`: 安定版。初期化後は直接開発せず、Acceptance 完了後の Pull Request で統合します。
- `feature/mvp-fishing`: Phase 6完了時のMVPを保持します。今回変更しません。
- `feature/visual-refinement-v1`: 完成したビジュアル版を保持。今回変更しません。
- `feature/midgame-depth-v1`: `3b7ba306`から分岐した今回の深度拡張専用ブランチ。
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

描画はすべてGodot内の自作仮素材です。魚の`fish_art`、ボートの`boat_art`、`data/lake/morning.tres`の色・表示深度を差し替えできます。空・水面・ボートを固定し、水中は0〜15m・15〜30m・30〜50mの深度帯ごとに表示します。

`.godot/`、キャッシュ、ローカル設定、ビルド・書き出し成果物は `.gitignore` で除外します。Godot の `*.import` と `*.uid` は参照維持のため追跡対象です。共有用の `export_presets.cfg` も追跡対象ですが、書き出し設定はまだありません。

初期プロジェクトの確認:

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 5
godot --headless --path . --script res://tests/phase1_acceptance.gd
godot --headless --path . --script res://tests/phase2_acceptance.gd
godot --headless --path . --script res://tests/phase3_acceptance.gd
godot --headless --path . --script res://tests/phase4_acceptance.gd
godot --headless --path . --script res://tests/phase5_acceptance.gd
godot --headless --path . --script res://tests/mvp_acceptance.gd
godot --headless --path . --script res://tests/visual_acceptance.gd
godot --headless --path . --script res://tests/midgame_depth_acceptance.gd
```

仕様と開発ルールは [ドキュメント案内](docs/README.md)、[MVP 仕様書](docs/game-design/mvp-spec.md)、[開発手順](docs/development.md) を参照してください。

Phase 1の範囲と素材の交換方法は [Phase 1仕様](docs/game-design/phase1-lake-scene.md)、検証結果は [Phase 1 Acceptance](docs/game-design/phase1-acceptance.md) に記録します。

Phase 2のキャスト・フッキング仕様は [Phase 2仕様](docs/game-design/phase2-casting.md)、検証結果は [Phase 2 Acceptance](docs/game-design/phase2-acceptance.md) を参照してください。

Phase 3の操作・テンション・魚の仮設定は [Phase 3仕様](docs/game-design/phase3-fight.md)、検証結果と実機の残課題は [Phase 3 Acceptance](docs/game-design/phase3-acceptance.md) を参照してください。

Phase 4の正式魚データ・経済・装備仕様は [Phase 4仕様](docs/game-design/phase4-economy.md)、10匹の連続経済ループ・回帰確認は [Phase 4 Acceptance](docs/game-design/phase4-acceptance.md) を参照してください。

Phase 5の図鑑・保存・実ソナー・一度限りの反応は [Phase 5仕様](docs/game-design/phase5-save-sonar.md)、検証結果は [Phase 5 Acceptance](docs/game-design/phase5-acceptance.md) を参照してください。テストのSaveはプレイヤーのSaveから分離しています。

Phase 6の調整内容と正式MVP Acceptanceは [Phase 6 Acceptance](docs/game-design/phase6-mvp-acceptance.md) に記録しています。

ビジュアルの範囲・検証・画面例は [Visual Refinement v1](docs/visual/visual-v1-acceptance.md) を参照してください。`tests/visual_capture.gd`で通常・Fight・ショップ・図鑑・CATCHのPNGを再取得できます。

深度拡張の仕様・検証・画面例は [Midgame Depth v1](docs/game-design/midgame-depth-v1.md) を参照してください。`tests/midgame_capture.gd`で深場・Fight・選択・Lv4ショップ・No.10図鑑のPNGを取得できます。
