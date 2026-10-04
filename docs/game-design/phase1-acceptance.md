# MVP Phase 1 — Acceptance確認結果

確認日: 2026-10-04。Godot **4.6.3 stable**。

対象: `feature/mvp-fishing`。開始HEAD: `97e5ad679bc7545e57b4bd54fbc84ce69d8c9444`。

## 結果

| 項目 | 結果 | 確認内容 |
| --- | --- | --- |
| Lake Scene | PASS | `main.tscn`から湖上38%＋水中62%のシーンを起動。空、山、湖面、ボート、水中の魚を実描画で確認 |
| Boat | PASS | スプライト表示。振幅3論理px、周期2.5秒。1周期の位置変化を検証 |
| Water Animation | PASS | 波・水面ハイライトが横に揺れる。20Hzの描画更新と時間による変位を確認 |
| Underwater | PASS | 湖上と色・境界が区別され、上層・中層・下層で輝度が低下。実描画でも確認 |
| Fish Spawn | PASS | 7匹。水中内で分散配置、初期の魚同士・深度HUDとの重なりなし |
| Fish Movement | PASS | 左右移動、両端でTurn、移動方向とSprite反転が一致。75秒相当のシミュレーションで水中・画面内を維持 |
| 16:9 | PASS | 1280×720のウィンドウ、640×360の論理画面。HUD境界検証と実描画を確認 |
| 19.5:9 | PASS | 1560×720のウィンドウ、780×360の論理画面。左右拡張、HUD境界検証と実描画を確認 |
| 20:9 | PASS | 1600×720のウィンドウでレイアウトを検証 |
| Safe Area | PASS | 3種類の画面比率でノッチ・上下余白を模擬。金額・深度・ソナーが安全領域内で高さ44px以上 |
| Project Import | PASS | Godot 4.6.3でインポート、終了コード0、重大Error 0 |
| Headless Launch | PASS | 通常メインシーンを180フレーム起動、終了コード0、重大Error 0 |
| Critical Errors | 0 | 最終インポート、通常起動、Acceptanceテスト、実描画のログで確認 |

統合テストは**22項目PASS、失敗0**。アニメーション中にノード数が増えないこと、サイズの異なる差し替え用SpriteFramesでも魚が水中内に収まることも確認しました。

## 再現方法

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 180
godot --headless --path . --script res://tests/phase1_acceptance.gd
```

通常起動してPCウィンドウを1280×720と1560×720に変更すると、両方の画面比率の表示を確認できます。仮描画、ボート、魚、表示専用HUDが同時に見えることを確認してください。

## 検証範囲と残課題

- LinuxのGodot 4.6.3でヘッドレスとOpenGL Compatibilityの実描画を確認。実描画検証には仮想ディスプレイとソフトウェアGPUを使用。
- iPhone / Androidの実機、モバイル書き出し、実機のノッチ・ジェスチャー領域は未検証。今回のSafe Area PASSはロジックと模擬領域の配置検証。
- 正式なアート素材への差し替えは今後。仮素材はすべて自作で、外部画像や有料アセットは使用していない。
- スマートフォンの実機FPSや消費電力は未測定。7匹、共有テクスチャ、静的背景、波20Hzで負荷を抑える構造とした。

この結果はPhase 1の確認であり、MVP全体のAcceptance、mainへのMerge、Phase 2の開始を意味しません。

次の作業はMVP Phase 2 — キャスト・ルアー沈下・魚接近・ヒットの実装指示待ちです。
