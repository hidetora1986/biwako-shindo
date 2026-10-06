# RC1 asset / secret audit

正式名称: **琵琶湖深度**。English: **BIWAKO SHINDO**。Version: **0.9.0-rc1**。

| 対象 | 出所・扱い |
| --- | --- |
| 魚No.01〜15、船、空、湖、山、湖底、UIアイコン | Repository内GDScriptによる自作プロシージャル／Placeholder。外部画像を取得していない |
| Opening専用背景4シーン | OpenAI画像生成による新規Placeholderイラスト。既存魚/HUDの流用や外部著作物のダウンロードなし。詳細: `assets/opening/README.md` |
| No.00の水中曲線・ソナー反応 | 自作Control描画。全身素材はない |
| 音 | 自作WAV生成。94Hzの短いノックと低音量ライン音。正式BGMはない |
| 日本語フォント | 既存Web版の`assets/fonts/NotoSansJP.ttf`を物語UIにも利用。SIL Open Font License 1.1（同ディレクトリのOFL.txt参照）。CreditsにNoto Sans JPを記載。OSのSystemFont Fallbackも維持 |
| docs内PNG | 現RCのGodot Compatibilityレンダラー出力。合成・外部画像なし。深層のScreenshotは隔離したDebug装備Fixtureを使用し、進行検証とは区別する |
| Godot | 4.6.3 stable。エンジンはMIT。最終配布時にエンジンと同梱ライブラリのライセンス通知を確認する |

有料・出所不明アセット、外部Monster画像、外部BGMは追加していない。

秘密情報監査は追跡ファイルとRC追加ファイルのPrivate Key header、GitHub Token、AWS Key ID、API Key形状を検査し該当0。署名鍵・証明書・Tokenを追加していない。`.godot/`、`.env*`、keystore／jks／p12／pem／key／cer／mobileprovision等をgitignore対象にする。パターン検査はあらゆる秘密情報形式の不在を保証するものではない。
