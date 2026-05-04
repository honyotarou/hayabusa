---
name: hayabusa-harness
description: >-
  Hayabusa リポジトリの Swift ハーネスと CI（LINE Harness OSS の考え方の Swift 写像）。
  scripts/harness.sh（fast / full / check）、check-encapsulation、GitHub Actions CI、Lefthook、Hummingbird live HTTP 統合テスト。
  Use when: Hayabusa, Swift, harness, CI, マージゲート, pre-commit, encapsulation, LocalPolicy, llama.cpp, 統合テスト.
---

# Hayabusa Swift ハーネス（`/hayabusa-harness`）

**正本**: このディレクトリの **SKILL.md** と **[steps-swift-harness.md](steps-swift-harness.md)**。詳細手順・ゲートが赤いときの分岐は `steps-*` 側。

## 1. 入口

| コマンド / キーワード | 意味 |
|------------------------|------|
| `fast` | **check-encapsulation** + LocalPolicy `swift test` + HayabusaApp `swift build`（ルート swift / llama 不要） |
| `full` / `check` | encapsulation + LocalPolicy + **llama.cpp** + `swift build -c release` + **`swift test -c release`** + App release |
| `./scripts/harness-check.sh` | `harness.sh check` と同じ（LINE の `harness-check.sh` に相当） |

CI（`.github/workflows/ci.yml`）は **`harness full`** を実行。

## 2. リポジトリ地図（ハーネス関連）

| 場所 | 役割 |
|------|------|
| `scripts/harness.sh` | **正本**のシェルゲート |
| `scripts/check-encapsulation.sh` | レイヤー import 規約（LINE `check:encapsulation` 相当） |
| `scripts/bootstrap-lefthook.sh` | `lefthook install` のラッパー |
| `scripts/harness-check.sh` | `check` のエイリアス |
| `scripts/copy_mlx_metallib.sh` | MLX 実行時のみ（ハーネス必須ではない） |
| `LocalPolicy/` | `swift test`（XCTest） |
| `HayabusaApp/` | メニューバー GUI — `swift build` |
| `Sources/HayabusaKit/` | サーバライブラリ（実行ファイルは `Sources/HayabusaCLI/`） |
| `Tests/HayabusaIntegrationTests/` | HTTP 統合テスト（`HummingbirdTesting` `.live`） |
| ルート `Package.swift` | **llama.cpp ビルド後**に `swift build` / `swift test` |
| `.github/workflows/ci.yml` | PR / main で **full** |
| `.github/workflows/release.yml` | タグリリース（既存） |
| `lefthook.yml` | pre-commit で **fast**（`*.swift` 変更時） |

## 3. 最小 Read ルール

| 状況 | 読むファイル |
|------|----------------|
| ハーネス / CI が赤い | [steps-swift-harness.md](steps-swift-harness.md) **「ゲートが赤いとき」** |
| Lefthook を入れたい | 同ファイル **Lefthook** |
| MLX metallib が必要 | ルート `scripts/copy_mlx_metallib.sh` と README の MLX 節 |

## 4. LINE スキルとの対応（概念のみ）

| LINE | Hayabusa Swift |
|------|----------------|
| `pnpm harness:fast` | `./scripts/harness.sh fast` |
| `pnpm harness` / `check` | `./scripts/harness.sh full` |
| `pnpm check:encapsulation` | `./scripts/check-encapsulation.sh`（`harness fast` / `full` に内包） |
| Vitest / Playwright / Hurl | LocalPolicy XCTest + **`HayabusaIntegrationTests`（実 TCP で `/health`・`/v1/chat/completions`）** |

## 5. 参照

- LINE Harness OSS の索引イメージ: グローバル **line** スキル（`steps-harness.md` の「クイックゲート」節と同型の fast / full 分離）
- [steps-swift-harness.md](steps-swift-harness.md)
