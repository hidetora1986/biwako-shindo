# MVP Phase 2 — キャスト・ルアー沈下・魚接近・ヒット

## 範囲と操作

ユーザー指示に基づき、Phase 1の湖上・水中・ボート・7匹の遊泳・HUDを維持し、CAST → 飛行 → 着水 → 沈下 → 接近 → アタリ → フッキング → HITを追加します。開発先は `feature/mvp-fishing` のみ。

画面下部中央の **CAST** をタップ／PCで左クリックすると投げます。魚がルアーに寄り、**!** が出たら画面の広い領域をタップ／左クリックしてフッキングします。ボタンを狙う必要はありません。成功は **HIT!**、時間切れは **MISS**。REELは表示しません。金額は¥0、ソナーはPhase 1の固定表示を維持します。

## 責務と状態

- `scenes/lake/lake_scene.tscn` / `scripts/lake/lake_scene.gd`: 湖の描画、魚の初期配置、レイアウト。FishingControllerへ環境を渡すだけ。
- `scenes/fishing/fishing.tscn` / `scripts/fishing/fishing_controller.gd`: 入力、1匹の予約、検知のタイミング、フッキング猶予、MISS再試行、Phase 2限定リセット。
- `scenes/fishing/lure.tscn` / `scripts/fishing/lure_controller.gd`: 独立したルアーの弧、着水の波紋・しぶき、メートル深度、沈下、0.7秒の小さなアタリ運動。`lure_art`で正式Textureへ交換可能。
- `scripts/fish/fish_controller.gd`: Phase 1のSWIM/TURNにAPPROACH_LURE/BITE/HOOKEDを追加。SpriteFramesの交換方法は維持。
- `scripts/ui/lake_hud.gd`: CAST、深度、!、HIT!/MISSの表示・Safe Area。入力・釣り判定を持たない。

ルアーとFishingControllerの状態はREADY / CASTING / SINKING / WAITING / BITTEN / HOOKED / RESET。ルアーはシーン内の1つを再利用します。CASTはREADYのみ、フックはBITTENのみ受け付け、遷移を即時に行うためタッチからのマウスイベント重複・連打・多点タッチでも二重に処理しません。タッチのCASTはボタン領域の押下を直接受け付け、PCのCASTはGodotのButton入力を使用します。

## 現在の調整値

| 項目 | 値・挙動 |
| --- | --- |
| 飛行 | 0.55秒、竿先から水面左側へ32pxの簡易弧 |
| 着水 | 0.45秒の小さい波紋・しぶき。ノードやParticleの追加なし |
| 沈下 | 2.3m/秒、着水から15mまで約6.52秒 |
| 深度 | `depth_m`はメートル、描画は水面～水底と湖の表示深度から変換。Phase 2は最大15m |
| ライン | 竿先からルアーへ1pxのLine2D。飛行・沈下・アタリに追従 |
| 検知 | キャストから2.2秒後、0.45秒間隔。近い魚から距離・クールダウン・確率を判定 |
| 魚の検知範囲 | `bite_detection_radius`、初期130論理px。魚ごとに変更可 |
| 接近確率 | `bite_probability`、初期0.65。近くの魚への再検知で徐々に上昇し、長い待ちを減らす |
| 接近速度 | `approach_speed`初期72px/秒＋魚の泳速に応じた微差。魚が実際に水中を移動する |
| 最早アタリ | キャストから5秒経過かつ接近魚との距離22px以内。着水直後の即HITを防ぐ |
| アタリ | !表示と短いルアー運動。最初の0.7秒の予兆を含め、全1.5秒をフッキング可能にして甘めの判定 |
| ハプティクス | Android/iOSのみ60ms。未対応端末のGodot APIは何もしない。PCでは呼ばない |
| MISS | 0.9秒表示。魚が離れ、当該魚は4秒の再検知クールダウン。2秒後から別の魚を再検知、再CAST不要 |
| HIT | 魚・ルアーをHOOKEDで約1秒保持。湖と他の魚のアニメーションは続く |
| RESET | 0.2秒間入力をロックし、ルアーを隠し、魚を遊泳へ戻してREADYへ |
| CAST領域 | 基本136×48論理px。320px幅の縮小表示でも物理44px以上の高さを維持 |

魚は常時ルアーへ向かわず、予約は同時に1匹のみ。他の魚はPhase 1の泳ぎを続けます。画面比率を変えてもルアーのメートル深度を維持し、魚・ライン・表示を再配置します。乱数は`random_seed`で再現でき、テストでは複数seed・待機時間・繰り返しCASTを使います。

## Phase 3への引き継ぎ

**HIT後の自動リセットはPhase 2限定のテスト処理です。Phase 3でFishingFightへ置換予定。** `hook_succeeded`シグナルと `_begin_reset()` のコメントが引き継ぎ位置です。

REELファイト、ラインテンション、魚スタミナ、捕獲、売却、金額増加、ショップ、装備、図鑑、セーブ、ホラー、ボスは実装しません。スワイプキャストと正式な竿アニメーションは後工程。現在の竿画像と竿先アンカーを利用し、竿の物理は追加していません。

## 確認

[Phase 2 Acceptance](phase2-acceptance.md)と`tests/phase2_acceptance.gd`を参照してください。MVP全体のAcceptanceとmainへの統合は未実施です。
