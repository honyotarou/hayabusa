# Hayabusa — Swift ハーネス詳細

親索引: [SKILL.md](SKILL.md)

## 1. 真実のソース

| 種別 | 置く場所 |
|------|-----------|
| LocalPolicy の振る舞い | `LocalPolicy/Tests/**/*.swift` |
| HTTP サーバの振る舞い | `Tests/HayabusaIntegrationTests/**/*.swift`（Hummingbird `.live` = 実 TCP） |
| レイヤー規約 | `scripts/check-encapsulation.sh` |
| 再現可能なゲート | `scripts/harness.sh` + CI |

## 2. 決定論ゲート（実行順）

**fast**（開発の内ループ、ルートの swift / llama 不要）:

1. `scripts/check-encapsulation.sh`（Server / Types / LocalPolicy / CLI の import 規約）
2. `LocalPolicy`: `swift test`
3. `HayabusaApp`: `swift build`（debug）

**full / check**（PR・マージ・CI）:

1. check-encapsulation
2. `LocalPolicy`: `swift test`
3. `vendor/llama.cpp` clone / cmake（`release.yml` と同フラグ、キャッシュがあればスキップ）
4. ルート: `swift build -c release`
5. ルート: `swift test -c release`（統合テスト含む）
6. `HayabusaApp`: `swift build -c release`

## 3. ゲートが赤いとき

| 落ちた段 | 典型原因 | 次の一手 |
|----------|----------|----------|
| **check-encapsulation** | 禁則 import（Server に MLX 等） | 依存を `HayabusaKit/Engine` 側に閉じる、HTTP 層は `InferenceEngine` のみ |
| **LocalPolicy swift test** | ポリシー変更・回帰 | 失敗テストと `HayabusaLocalPolicy` の期待を揃える |
| **HayabusaApp swift build** | GUI コンパイルエラー | `HayabusaApp/Sources` の型・import を修正 |
| **cmake / llama** | clone 失敗・キャッシュ破損・レイアウト差 | 共有ビルドでは `build/bin/libllama*.dylib`、`build/src` に `.a` がある場合あり。`Package.swift` の `-L` と `harness.sh` の検証は両方を想定。困ったら `vendor/llama.cpp/build` を消して再実行 |
| **ルート swift build** | CLlama リンク・SPM | `libllama.dylib` の有無を確認 |
| **ルート swift test** | ルート競合・HTTP 契約破壊 | `HayabusaHTTPIntegrationTests` と `HayabusaServer` のパス・検証を更新 |

**MLX `metallib`**: 実行時のみ。`scripts/copy_mlx_metallib.sh`（README の MLX 節）。CI では検証しない。

## 4. Lefthook

1. `brew install lefthook`
2. リポジトリルートで `./scripts/bootstrap-lefthook.sh`（または `lefthook install`）。
3. `*.swift` 変更の pre-commit で **`./scripts/harness.sh fast`**（encapsulation 込み）。

フルゲートはコミット前に手動で `./scripts/harness.sh full` を推奨。

## 5. CI/CD

- **ci.yml** / **release.yml**: `runs-on: macos-15` + Xcode **16.3**（`mlx-swift-lm` が Swift **tools 6.1** を要求）。
- **ci.yml**: PR / `main` / `master` で `harness full`（`swift test` まで含む）。
- **release.yml**: タグ `v*` の DMG（既存）。
- ルート `Package.swift` の **mlx-swift-lm** は **`revision` ピン**（`main` 直追いなし。更新はローカルで `harness full` 緑を確認してから revision を上げる）。

## 6. 今後足せるもの

- **SwiftLint** や行数キャップ（LINE の `ROUTE_LINE_CAPS` 型）
- **scheduled workflow** で main の `full` 定点観測
