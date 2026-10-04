# 魚の仕様

魚種、出現条件、魚 AI、釣り上げ条件、パラメーターの仕様をこのディレクトリに保存します。

Phase 1では[独立した魚シーンと視覚的な遊泳](../game-design/phase1-lake-scene.md)を実装しています。3種類の見た目・速度は仮の設定であり、正式な魚データは後工程です。

Phase 2では検知・接近・BITE・HOOKEDを追加しました。検知半径・確率・接近速度は魚ごとに変更できます。同時に反応する魚は1匹です。[Phase 2仕様](../game-design/phase2-casting.md)を参照してください。

Phase 3では5種の仮の名前・サイズ・スタミナ・抵抗設定を`data/fish/*-fight.tres`へ保存します。魚の`size_cm`と`stamina`を保持し、釣果へ名前・サイズをコピーします。既存3種類の画像を流用し、売値・図鑑・セーブは含みません。[Phase 3仕様](../game-design/phase3-fight.md)を参照してください。

Phase 4でNo.01〜05の正式データへ更新しました。生息深度・サイズ・売値・スタミナは指定値を`data/fish/*-fight.tres`に統合し、CATCH成立時にサイズ比例の売値を自動加算します。[Phase 4仕様](../game-design/phase4-economy.md)と[検証結果](../game-design/phase4-acceptance.md)を参照してください。

Phase 5では捕獲数・BEST SIZE・発見済みを図鑑に保存します。[Phase 5仕様](../game-design/phase5-save-sonar.md)を参照してください。
