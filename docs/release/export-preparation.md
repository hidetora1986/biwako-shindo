# RC1 mobile export preparation

ProjectはGodot 4.6.3 Compatibility、Landscape、640×360基準／expand、Nearest。名称・English description・Versionを`project.godot`へ設定。正式UIからDebug Triggerへ到達する経路はなく、Debug APIは`OS.is_debug_build()`で限定する。ストア公開は実施しない。

`export_presets.cfg`はまだ存在しない。検証していないPresetを完成品として置かず、Godot Export画面から次の手順で追加できる。

## Android: BLOCKED

この環境はJava 21あり、Android SDKとGodot 4.6.3 Export Templatesなし。APK／AABを生成していない。

1. Godot 4.6.3と同じExport Templates、対応Android SDK／Build Toolsを用意する。
2. Editor SettingsでJava SDKとAndroid SDKのローカルパスを設定。
3. ExportへAndroid Presetを追加し、Landscape、識別子、Version、必要最低限の権限を設定。
4. 共有してよいPresetのみ`export_presets.cfg`として追跡する。キー、Password、Machine pathはRepositoryへ含めない。
5. `godot --headless --path . --export-debug Android /tmp/biwako-shindo-rc1.apk`でSmoke Exportし、実機のInstall／Launch／Touch／Japanese font／Saveを確認。

## iOS: BLOCKED

LinuxでmacOS／Xcode／Apple署名環境がない。iOS Buildを実行していない。

macOSで同VersionのTemplatesとXcodeを用意し、iOS Preset、Bundle Identifier、Orientation／Safe Area、アプリ素材を設定する。署名証明書とProvisioning ProfileはRepository外で管理する。Xcode Build／実機Touch／バックグラウンド／Saveを別途実施。

Android／iOSとも今回の結果はProject設定・素材出所の確認まで。Build PASS・端末性能PASS・公開準備完了とは扱わない。
