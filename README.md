# 琵琶湖深度 — biwako-shindo

琵琶湖を舞台とする、スマートフォン向け2Dピクセルホラー釣りゲーム。

## 開発環境

- Godot 4.x / GDScript。初期構築・起動確認には Godot 4.6.3 stable を使用。
- Git / GitHub。

## 起動方法

今回のRelease Candidate 1は `release/rc1` にあります。完成したMVPとビジュアル版は、それぞれ元のブランチに維持しています。

```sh
git clone --branch release/rc1 https://github.com/hidetora1986/biwako-shindo.git
cd biwako-shindo
godot --editor --path .
```

Godot のプロジェクトマネージャーから、リポジトリ直下の `project.godot` をインポートしても起動できます。エディターで F6 は現在のシーン、F5 はプロジェクトを実行します。

## 対応プラットフォーム

- 目標: Android / iOS のスマートフォン。
- 開発時の確認: Windows / macOS / Linux の Godot エディター。
- モバイルへの書き出し設定・実機検証は今後実施します。

## 現在の開発フェーズ

Full Game RC1 — Version **0.9.0-rc1**。全編QA・保存耐久・100回Stress・ペーシングを検証。**RC1 Status: NOT READY**（90分目標が未達）。既存7ブランチを保持し、通常魚15種・No.00・120m上限・既存Endingを維持します。

**操作:** CASTをタップ／クリック。魚が寄り、**!**が出たら画面をタップ／左クリックして**HIT!**。次に右下の**REELを長押し**します。テンションが黄色・赤、またはRUNになったら離し、安全域へ戻ったらまた巻きます。魚が疲れて近づくと自動で**CATCH!・魚名・サイズ・売値**を表示し、再びCASTできます。巻き続けて危険域を維持するとLINE BREAK、長時間離したままではESCAPEDですが、すぐ再挑戦できます。No.01〜09とNo.11〜13・No.15は自動売却され、左上の所持金が増えます。名称不明種A・BはCATCH後に「売る／戻す」を選びます。戻した場合は所持金が増えず、捕獲記録は残ります。**SHOP**を開き、ロッド・リール・ライン・ソナーの次Lvを購入すると即装備されます。ラインLv1は10mまで、Lv2・3の購入で25m・50mを解放します。CASTの上の**DEPTH**をタップし、解放済みの0〜15m・15〜30m・30〜50m・50〜65m・65〜85m・85〜100m・100〜120mを切り替えます。ラインLv2では15〜25mまで、Lv3では50mまで遊べます。名称不明種Aを発見するとLv4装備がSHOPに出ます。ラインLv4では85mまで遊べ、80〜85mで名称不明種Bを発見できます。売る／戻すのどちらでもLv5が解放され、ラインLv5は120m対応になります。今回の実プレイ上限は120mです。No.14発見・ROD Lv5・LINE Lv5・夜の解放が揃うと、ABYSSで100m以上に沈めたルアーへNo.15が接近します。ゆっくりラインが引かれた後、!でタップしてHOOKし、従来のREEL長押し／離す操作で挑みます。初回捕獲後は自動売却・短い夜明け・Titleへ進み、CONTINUEで所持金・図鑑・装備を保ったまま釣りを続けられます。No.15は再出現しません。ショップ中は釣りが停止し、×で再開します。**FISH BOOK**で捕獲数・BEST SIZEを確認できます。所持金・装備・図鑑は`user://biwako-shindo/save.json`に自動保存され、次の起動時に復元されます。初回の魚にはNEW!を表示します。

## ブランチ運用

- `main`: 安定版。初期化後は直接開発せず、Acceptance 完了後の Pull Request で統合します。
- `feature/mvp-fishing`: Phase 6完了時のMVPを保持します。今回変更しません。
- `feature/visual-refinement-v1`: 完成したビジュアル版を保持。今回変更しません。
- `feature/midgame-depth-v1`: 0〜50m拡張版を保持。今回変更しません。
- `feature/lategame-depth-v1`: 0〜100m・Lv5版を保持。今回変更しません。
- `feature/boss-v1`: 完成したNo.15・Main Ending版を保持。今回変更しません。
- `feature/hidden-boss-v1`: 完成したHidden版を保持。今回変更しません。
- `release/rc1`: `7eeafafa`から分岐した今回のRC検証専用ブランチ。
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

描画はすべてGodot内の自作仮素材です。魚の`fish_art`、ボートの`boat_art`、`data/lake/morning.tres`の色・表示深度を差し替えできます。空・水面・ボートを固定し、水中は0〜120mの7つの深度帯ごとに表示します。環境色はシーン専用Resourceに適用し、魚・ボートの差し替え構造を維持します。

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
godot --headless --path . --script res://tests/lategame_depth_acceptance.gd
godot --headless --path . --script res://tests/boss_acceptance.gd
godot --headless --path . --script res://tests/hidden_boss_acceptance.gd
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

後半深度・Lv5・Save互換・画面例は [Late Game Depth v1](docs/game-design/lategame-depth-v1.md) を参照してください。`tests/lategame_capture.gd`でA〜G・夕方・残留ソナー・図鑑のPNGを取得できます。

No.15・Ending・Save復元の仕様と画面は [Boss v1 Acceptance](docs/game-design/boss-v1.md) を参照してください。`tests/boss_capture.gd`でA〜H・DIVE・TitleのPNGを取得できます。

Hidden実装・保存互換・専用テスト・画面例は [Hidden Phase検証記録](docs/game-design/hidden-boss-v1.md) を参照してください（開発向けネタバレを含みます）。

RC1ではLINE Lv2価格を¥1,800へ調整。Main Ending後は、無名ルアー入手前にもNIGHTを切り替えられ、取り逃した深層魚とノックを回収できます。No.10／14を最初に売る選択は通常Endingへ進めますがHiddenは不可です。先に返却したFlagはその後の売却でも維持します。旧Saveは売却履歴を推測して新しくロックしません。

[RC1 Acceptance](docs/release/rc1-acceptance.md)、[Pacing](docs/release/rc1-pacing.md)、[Known issues](docs/release/known-issues.md)、[Mobile Export準備](docs/release/export-preparation.md) を参照してください。Android／iOSのBuildと実機QAは未完了、Human FeelはManual Test Requiredです。

```sh
godot --headless --path . --script tests/full_game_acceptance.gd
godot --headless --path . --script tests/full_game_acceptance.gd -- --cut
godot --headless --path . --script tests/full_game_acceptance.gd -- --sell
godot --headless --path . --script tests/pacing_simulation.gd
godot --headless --path . --script tests/full_game_stress.gd
godot --headless --path . --script tests/rc1_save_stress.gd
godot --headless --path . --script tests/rc1_postgame_recovery.gd
```

## RC1 Human Playtest

ゲーム内容を変えずに計測するDebug専用の起動方法:

```sh
godot --path . -- --rc1-playtest --rc1-fresh
```

RC1専用Test Saveのみ初期化する。再開時は`--rc1-fresh`を外す。計測・評価・提出方法は[Human Playtest手順](docs/release/human-playtest.md)を参照。正式UIへ計測値は表示しない。B01／RC1 NOT READYは人間の実測が届くまで維持する。
