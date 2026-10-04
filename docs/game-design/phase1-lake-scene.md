# MVP Phase 1 — 湖上・水中基礎シーン

## 対象と範囲

- Repository: `hidetora1986/biwako-shindo`。
- 開発ブランチ: `feature/mvp-fishing`。
- 開始HEAD: `97e5ad679bc7545e57b4bd54fbc84ce69d8c9444`。
- エンジン: Godot 4.6.3。
- 主対象: iPhone / Androidの横持ち。PCでも同じシーンをデバッグ可能。
- 成功基準: 湖上と水中が同時に見え、ボートの下で魚が泳ぎ、琵琶湖の釣りゲームの画面として成立する。

今回は背景・湖・水中・ボート・視覚的な魚の遊泳・表示専用HUDまでです。MVP全体のAcceptanceやmainへの統合は行いません。

## 画面とSafe Area

基準画面は640×360の16:9。PC初期ウィンドウは1280×720です。`viewport` stretchと`expand`を使い、19.5:9 / 20:9では左右の景色を拡張します。Nearestと2D変換のピクセルスナップで仮ピクセル素材を表示します。

湖上は上部38%、水中は下部62%。重要HUDは中央の最大640px幅と16px余白の内側に置きます。iOS / Androidの`DisplayServer.get_display_safe_area()`をウィンドウ座標から論理画面に換算します。金額・深度・ソナーの領域は高さ44px以上です。

## シーン構造

```text
scenes/main.tscn
  LakeScene (scenes/lake/lake_scene.tscn)
    Background
      BackgroundSky
      BackgroundMountains
    Underwater
      WaterBackground
      FishContainer
        Fish × 7 (scenes/fish/fish.tscn)
    Lake
      LakeSurface
      Boat
        Sprite
    HUD
      Root
        Money
        Title / Subtitle
        SonarPlaceholder
        Depth
```

既存のメインシーンを入口として維持し、湖と魚を独立させています。追加のゲーム管理基盤や汎用AIフレームワークは導入しません。

## 湖上と水中

- 朝の空、雲、遠景の山、静かな湖面を別レイヤーで表示。
- 山の反射、水面ハイライトと小さな波をGodot内の軽い描画で表現。
- 水面の波は最大20Hzで横方向に揺れる。高度なシェーダー・パーティクルは使わない。
- ボートは横幅の52%付近。3pxの上下揺れ、周期2.5秒。
- 簡易的な乗員のシルエットと静止したロッドの絵を含む。ルアー・釣り糸・釣り操作はない。
- 水中は青緑から暗い青へ段階的に変化。弱い光の筋、浅い砂利底と水草は静的な仮描画。

`data/lake/morning.tres`の`LakeProfile`に配色、湖上比率、`displayed_depth_m`を保存します。現在の表示は0–15m。メートルで持つ表示深度と魚の`depth_position`は100m以上にも設定可能ですが、深度操作・フェーズ進行・時刻・天候のロジックは実装しません。

## 魚

7匹の仮の魚を水中だけに配置。ブルーギル風、バス風、小魚の見た目は正式な魚種データではありません。

`FishController`の設定:

| 項目 | 内容 |
| --- | --- |
| `swim_speed` | 基本速度。小魚28–34、丸い魚17–22、大きい魚11–15論理px/秒の仮値 |
| `swim_direction` | 右`1` / 左`-1` |
| `depth_position` | メートルで指定する水中位置 |
| `variation_seed` | 魚ごとの小さな速度変化の種 |
| `fish_art` | 差し替え用のSpriteFrames。`swim`アニメーションを用意する |

Swim、端でのTurn、0.82–1.18倍の滑らかな速度変化を持ちます。左に進むときは`AnimatedSprite2D.flip_h`で反転します。魚の全体が画面内・水中に収まるように境界を設定し、サイズ変更時も配置を換算します。初期位置は横に分散し、深度も少しばらつかせます。3フレームの尾びれの仮アニメーションを再生します。

初期配置は再現可能な乱数種を使用します。毎フレームの魚ノード生成は行いません。

## HUDと未実装の操作

- 左上: `¥0`。金額処理はない。
- 右上: `SONAR / STBY`、深度線と固定の魚影点。魚の位置やAIを参照しない。
- 水面下中央: `0–15m`のエリア表示。
- CAST / REELボタンは非表示。入力や釣り機能を接続しない。

## 仮素材の差し替え

すべての絵はGodotの描画と`PlaceholderArt`で自作しています。外部画像・有料素材・権利不明な素材は使用しません。

1. 魚: `scenes/fish/fish.tscn`の`fish_art`に、右向きの`swim`アニメーションを持つSpriteFramesを設定。境界幅はフレームの幅から取得します。
2. ボート: Boatの`boat_art`にTexture2Dを設定。スプライトの位置・オフセットを素材に合わせて調整。
3. 背景: 各レイヤーの描画スクリプトをSprite2D等へ置き換え可能。`configure(size, profile)`の画面サイズ更新との関係を維持。
4. 配色・表示深度: `LakeProfile`リソースを差し替え。朝以外の見た目へ拡張するための設定であり、時刻・天候の切り替え機能は今回含めない。

仮テクスチャは起動時に生成し、魚の見た目ごとに共有します。静的な背景は初期化・リサイズ時に描画命令を更新し、波とボート、魚だけを継続更新します。

## Phase 1で実装しない内容

キャスト、ルアー、魚の食いつき、HIT、フッキング、REEL、テンション、魚スタミナ、捕獲、売却、ショップ、装備の機能、セーブ、図鑑、ホラー、巨大魚、ボス、No.00、ストーリー、NPC、課金、広告。

ソナーと魚の同期はPhase 6予定です。次の作業はMVP Phase 2の指示待ちであり、今回先行実装しません。

## 検証

[Phase 1 Acceptance](phase1-acceptance.md)に結果を記録します。再現用の統合テストは`tests/phase1_acceptance.gd`です。
