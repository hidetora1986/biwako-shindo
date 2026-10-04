# UI の仕様

画面構成、タッチ操作、表示状態、画面遷移の仕様をこのディレクトリに保存します。

Phase 1は横持ち640×360を基準に、金額・表示専用ソナー・エリア深度のHUDを用意しています。中央16:9相当の範囲と端末Safe Areaを考慮します。[Phase 1仕様](../game-design/phase1-lake-scene.md)を参照してください。

Phase 2で下部中央にCASTを追加しました。基本136×48論理px、320px幅の縮小表示でも高さ44物理pxを維持します。ルアー深度・!・HIT!/MISSを表示し、アタリ中は画面の広い範囲でタッチ／左クリックを受け付けます。REELは表示しません。[Phase 2仕様](../game-design/phase2-casting.md)を参照してください。

Phase 3ではファイト中だけ右下のREEL、LINE TENSION、FISH STAMINAを表示。REELは長押し・解除、アタリは従来の広域タップです。ファイト中はCASTと深度パネルを隠し、魚とラインを見せます。釣果はCATCH!・魚画像・日本語名・cmサイズのパネル。[Phase 3仕様](../game-design/phase3-fight.md)を参照してください。
