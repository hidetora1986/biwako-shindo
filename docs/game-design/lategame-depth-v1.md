# Late Game Phase 1 — 50〜100m

基点は `7824109a45e4b07167a255f9f4ead6a75133c397`。作業ブランチは `feature/lategame-depth-v1`。main・MVP・Visual・Midgameの4ブランチは保持します。

## 深度・魚・進行

既存の0〜50mに50〜65m・65〜85m・85〜100mを追加しました。空・ボート・水面は画面上部38%を維持し、水中だけを深度帯の原点と幅で変換します。新しい帯では濃青、紺、暗い青へ移り、光の筋が薄れ、少量の静的な浮遊物と地形だけを残します。黒一色・画面ノイズ・赤い演出はありません。

DEPTHボタンで解放済みの帯を選び、従来のCAST→BITE→HOOK→REEL→CATCHを続けます。追加魚は既存の`FishFightProfile` Resourceで管理し、7つの魚ノードを再利用します。出現位置は魚の生息深度・表示帯・ライン上限の交差範囲です。旧10種のデータ・画像・Fight設定は保持しました。

| No. | 魚 | 深度 | サイズ | 売値 | rarity | 抵抗 |
|---|---|---|---|---|---|---|
| 11 | 糸顎魚 | 50–65m | 90–160cm | ¥40,000–95,000 | 5 | 小刻みな引き・テンションの揺れ |
| 12 | 裂け腹魚 | 60–75m | 110–180cm | ¥55,000–120,000 | 5 | 高スタミナ・RUN後に一度だけ8回復 |
| 13 | 逆鱗魚 | 70–85m | 130–210cm | ¥80,000–180,000 | 5 | 強めのRUN・0.7秒の予兆 |
| 14 | 名称不明種B | 80–100m | 180–260cm | ¥180,000–420,000 | 6 | 長めの抵抗・0.75秒の予兆 |

画像は自作3フレームのキャッシュです。糸状の顎、曖昧な腹部の隙間、逆向きの鱗、頭が大きく後半が細い非対称の魚形を使います。血・傷・歯の強調・人面・赤い目はありません。既存の`fish_art`差し替え口を維持しています。

LINE Lv4の85mでも、No.14が80〜85mに出現します。65〜85m帯のCASTごとにseed付き28%の出現候補判定を行い、6回目ごとには候補入りを保証します。これは即BITEや捕獲の保証ではなく、既存の距離・検知・接近・フッキングを経る遭遇機会です。Lv5解放にLv5を必要とする循環を防いでいます。

No.14はNo.10と同じCATCH後の「売る／戻す」を使い、自動売却しません。売却は売値加算、返却は収入0。どちらも発見・捕獲数・BEST SIZEを更新し、SaveとLv5解放を行います。返却時は`returned_unknown_b=true`になり、その後の売却でも消えません。`returned_unknown_a`は別に保持します。図鑑は14種になり、未発見は???、No.14の説明は「既知の分類体系では照合できない。」のみです。

ソナーでは既知でもNo.14は???。反応幅は通常5px・No.10が8px・No.14が16px・既存の一過性異常が40pxです。No.14のランディング後は水中の魚を隠し、同じ魚のソナー接触を1.5秒だけ残します。新しい説明文・警告・BGM変更はありません。

## 夕方・夜と一度限りのイベント

No.11初回捕獲で夕方、No.12初回捕獲で夜を解放します。環境色は各段階6秒で補間し、空・雲・山・水面・ボートを更新します。シーン専用に複製したLakeProfileを使い、共有Resourceを書き換えません。色の再描画は移行中のみ10Hz。Load時は捕獲記録・`night_unlocked`から時刻を復元します。

| イベント | 条件 | 内容 |
|---|---|---|
| Knock 1 | No.11発見・夕方以降・未実施 | 1打 |
| Knock 2 | No.12発見・60m到達・Knock 1完了 | 0.65秒間隔で2打 |
| Knock 3 | No.13発見・70m到達・Knock 2完了 | 0.3秒間隔で3打 |
| 0.0m接触 | Knock 3完了・夜・Sonar Lv4以上・未実施 | ソナー最上部だけに0.6秒の反応 |

条件成立後に3秒の間を置き、待機／通常釣り状態で開始します。Fight・CATCH・SHOP・図鑑・既存のソナー異常とは開始を重ねません。再生中の画面切替を防ぎ、CAST自体は継続できます。ノックは静かな低音・対応端末の短い振動・船の最大1.5pxの微動だけです。説明テキスト、カメラ揺れ、暗転、ジャンプスケアはありません。

低音は起動時に一度だけ生成する0.14秒・94HzのPCM仮音です。FishingControllerの`hull_knock_sound`にAudioStreamを指定して交換できます。外部音源は使用していません。イベント終了時に`hull_knock_count`を0→1→2→3、接触後に`zero_depth_contact_seen=true`として保存し、再起動でも再発しません。

## Lv5・経済・Save

No.14の発見後にLv5がSHOPへ出ます。購入は1タップ・即装備・残高控除・Saveです。未解放のLv5はLOCKED、実際のLv5到達後はMAXと表示します。

| カテゴリ | Lv5名 | 価格 | 効果 |
|---|---|---|---|
| ROD | 深淵ロッド | ¥420,000 | 対応500cm |
| REEL | ABYSS 8000 | ¥360,000 | 巻き速度×1.70 |
| LINE | 深海ライン | ¥300,000 | 最大120m |
| SONAR | ABYSS SCAN | ¥500,000 | 探知120m・将来用unlimited_display |

Resourceに指定の短いflavor_textも保持しています。今回のソナー表示は120mまでで、不可能な深度値は出しません。LINE5購入時は短い「DEPTH UNLOCKED / 85m → 120m」。装備性能120mと実プレイ上限100mを分離し、100mより深い帯・魚は追加していません。

後半魚1〜3匹の売値でLINE5を買える水準です。初回No.14を戻しても、No.11〜13の収入と次の捕獲で購入できます。新規ゲームは従来通り¥0・全Lv1で開始します。

JSON Saveはversion 1の追加項目で拡張します。既存の所持金・装備・No.01〜10記録・異常フラグ・A返却を保持し、新しい項目がない旧SaveではNo.11〜14未発見、B返却／夜／0m接触false、ノック0で復元します。夜はNo.12の記録からも復元します。不正型・範囲外の新項目は安全な既定値に戻し、Loadだけではファイルを変更しません。

`max_depth_reached_m`は60m・70mを初めて越えた時だけ保存を通知します。捕獲・選択・購入・イベント終了時にも原子的保存を行います。毎フレームFile IOはありません。

## Acceptanceと再現

Godot 4.6.3 stable、Linux Compatibility/Mesa llvmpipeで検証しました。詳細は [結果JSON](lategame-acceptance-results.json)。

- Late Game Acceptance: PASS（460項目）。後半20回の自然なCAST→検知→BITE→HOOK→Fight→CATCH、4種全部、Lv4で85mのNo.14捕獲・返却、Lv5購入後の100m捕獲・売却を確認。資金の追加なしでLINE5と残り3カテゴリを購入しました。
- 安全域で押し、RUN・危険域で離す再現操作のFight時間はNo.11約9.5秒、No.12約10.9秒、No.13約11.2秒、No.14約15.4秒（REEL Lv4）。全サイクルは約21.6〜28.7秒。選択を考える人間の時間は含みません。
- 1＋2＋3の6打・間隔・開始条件・0.6秒ソナー・保存・再発防止を確認。
- Phase 1〜5、MVP、Visual、Midgame Acceptance: 全PASS。従来のテストは10種以上のデータ件数とLv4の実深度85mへ対応し、No.01〜10の既存チェックを維持しました。
- 別プロセスのSave→終了→Loadで、所持金・LINE5・14種記録・A/B返却・夜・ノック3・0m接触・既存anomaly_seenを復元。Midgameの再起動テストもPASS。
- 16:9、19.5:9、20:9、640×360で実描画・タッチ／マウス選択・図鑑スクロール・Lv5ショップを確認。4比率とも待機120フレームにノード増加なし、Save書込0。
- Import・Headless Launch: PASS。Godot Error・重大Error: 0。仮想ディスプレイのVSync非対応Warningだけが描画テストに出ます。

iPhone/Android実機、端末別Safe Area・振動・ノックの音量感、初見プレイヤーの種別成功率は未測定です。No.15・No.00・ボス・エンディング・100m超のコンテンツは追加していません。

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/lategame_depth_acceptance.gd
godot --headless --path . --script tests/lategame_save_restart.gd -- --write
godot --headless --path . --script tests/lategame_save_restart.gd -- --read
godot --path . --script tests/lategame_capture.gd -- --output-dir=/tmp/biwako-lategame-captures
```

テストはプレイヤーのSaveから分離した`user://tests/`を使います。画面取得は既知No.10・Lv4のfixtureから進め、実際の接近・Fight・返却／売却を通ります。

## 画面例

| 状態 | 16:9 | 19.5:9 |
|---|---|---|
| A 50〜65m・No.11 | [画面](../lategame/screenshots/16x9-A-50_65m-no11.png) | [画面](../lategame/screenshots/19_5x9-A-50_65m-no11.png) |
| B 夜65〜85m | [画面](../lategame/screenshots/16x9-B-night-65_85m.png) | [画面](../lategame/screenshots/19_5x9-B-night-65_85m.png) |
| C No.13 Fight | [画面](../lategame/screenshots/16x9-C-no13-fight.png) | [画面](../lategame/screenshots/19_5x9-C-no13-fight.png) |
| D No.14 Fight | [画面](../lategame/screenshots/16x9-D-no14.png) | [画面](../lategame/screenshots/19_5x9-D-no14.png) |
| E 売る／戻す | [画面](../lategame/screenshots/16x9-E-no14-choice.png) | [画面](../lategame/screenshots/19_5x9-E-no14-choice.png) |
| F Lv5 Shop | [画面](../lategame/screenshots/16x9-F-lv5-shop.png) | [画面](../lategame/screenshots/19_5x9-F-lv5-shop.png) |
| G 0.0m Sonar | [画面](../lategame/screenshots/16x9-G-zero-depth-contact.png) | [画面](../lategame/screenshots/19_5x9-G-zero-depth-contact.png) |

[夕方](../lategame/screenshots/16x9-sunset.png) / [残留ソナー](../lategame/screenshots/16x9-no14-lingering-sonar.png) / [No.14図鑑](../lategame/screenshots/16x9-book-no14.png) / [20:9選択](../lategame/screenshots/20x9-E-no14-choice.png) / [640px Shop](../lategame/screenshots/640px-F-lv5-shop.png)。
