# 開発手順

## ブランチ運用

`main` は安定版の統合先です。初期化コミット以降、直接機能を追加しません。今回のBoss Phaseは `4c9c3783`を基点とした `feature/boss-v1` で行います。`main`・`feature/mvp-fishing`・`feature/visual-refinement-v1`・`feature/midgame-depth-v1`・`feature/lategame-depth-v1` は保持し、変更しません。

作業開始時にブランチを確認します。

```sh
git switch feature/boss-v1
git status --short --branch
```

将来の拡張は、対応する開発を始めるときに安定版から分岐します。

```sh
git fetch origin
git switch -c feature/horror-phase1 origin/main
```

同じ方法で `feature/fish-expansion`、`feature/boss` などを追加できます。

## コミット方針

機能単位でコミットし、変更の目的が分かるメッセージを付けます。

```text
init: create Godot project
feat: add fishing scene
feat: implement casting
feat: add fish AI
feat: implement reel and tension
feat: add economy
feat: add equipment shop
feat: add sonar
feat: add first anomaly event
```

仕様だけの変更には `docs:`、不具合修正には `fix:` を使用します。

## Godot と Git

- 初期構築・確認に使用するバージョンは Godot 4.6.3 stable です。更新時はチームでバージョンをそろえます。
- `.godot/` はインポート時に再生成されるため追跡しません。
- `*.import` と `*.uid` はリソース参照のため追跡します。
- ビルド・書き出し先には `build/` または `exports/` を使用します。
- `export_presets.cfg` は共有用の設定として追跡できます。認証情報・署名鍵・ローカル秘密情報は含めません。
- 空のディレクトリは `.gitkeep`、仕様保存先は README で保持します。

## 初期プロジェクトの確認

```sh
godot --headless --editor --path . --import
godot --headless --path . --quit-after 5
git status --short
```

ヘッドレス実行はプロジェクトの読み込みを確認するためのものです。スマートフォンの表示・入力・書き出しは実機で確認します。

## 統合手順

1. [MVP 仕様書](game-design/mvp-spec.md) の必須機能と具体的な Acceptance 基準を確定する。
2. `feature/mvp-fishing` で実装し、Acceptance の確認結果を記録する。
3. MVP Acceptance 完了後、`feature/mvp-fishing` から `main` への Pull Request を作成する。
4. 差分・検証結果をレビューし、完了を確認してから統合する。

初期構築の段階では `main` へ統合しません。

Hidden Phaseは `dd80cf37` からの `feature/hidden-boss-v1` のみで実施。main・MVP・Visual・Midgame・Lategame・Bossの既存6ブランチへコミット／マージ／force pushしません。
