# GitHub 初期反映

## 現在の状態

ローカルの初期構成は作成済みです。接続済み GitHub アプリの認証では、`biwako-shindo` の新規作成が権限不足（HTTP 403）で拒否されたため、GitHub への作成・反映は保留です。

想定する作成先は `hidetora1986/biwako-shindo`、公開範囲は Private です。

## 空のリポジトリを作成する

GitHub の新規作成画面で `biwako-shindo` を作成します。README、ライセンス、`.gitignore` の自動追加は使用しません。GitHub 連携アプリのアクセス対象に、このリポジトリを追加します。

既存ファイルやコミットがあるリポジトリへは、そのまま初期反映せず、内容を確認してから進めます。

## 初期反映する

このローカルリポジトリを使用する場合:

```sh
cd biwako-shindo
git remote -v
git push -u origin main
git push -u origin feature/mvp-fishing
gh repo edit hidetora1986/biwako-shindo --default-branch main
```

`main` の初回 push は、README のみを含む初期化コミットを公開するためのものです。Godot プロジェクトや開発コミットは `feature/mvp-fishing` にだけ反映します。以降、`main` に直接 push しません。

## 履歴付きバンドルから復元する

`biwako-shindo.bundle` がある場合、両ブランチを含む履歴を復元できます。

```sh
git clone --branch feature/mvp-fishing biwako-shindo.bundle biwako-shindo
cd biwako-shindo
git branch main origin/main
git remote set-url origin https://github.com/hidetora1986/biwako-shindo.git
```

復元後、上記の初期反映を行います。ZIP はソースファイルのみで、Git の履歴とブランチは含みません。

## GitHub 側の確認

- デフォルトブランチが `main` であること。
- `feature/mvp-fishing` に `project.godot` と各ディレクトリが存在すること。
- `main` には初期化コミットのみがあり、MVP 開発が統合されていないこと。
- 利用プランが対応していれば、`main` のブランチ保護で Pull Request 必須、force push 禁止、削除禁止を設定すること。

GitHub 側のブランチ保護はまだ設定できていません。MVP Acceptance 完了後に Pull Request で統合する運用は、[開発手順](development.md) に従います。
