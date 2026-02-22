# Implementation Plan: 都道府県コード変換・住所逆引き（住所→郵便番号）

**Branch**: `004-prefecture-code-reverse-lookup` | **Date**: 2026-02-23 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/004-prefecture-code-reverse-lookup/spec.md`

---

## Summary

都道府県コード⇔都道府県名の相互変換と、住所（都道府県・市区町村・町域を分離した入力）から郵便番号候補を取得する逆引き機能を追加する。  
**技術方針**: コード⇔名称は JIS X 0401（01–47）の静的なマッピングで実装し、DB 不要で即時応答する。逆引きは既存の `PostalCodeRepository` に `find_postal_codes_by_address(pref:, city:, town:)` を追加し、既存の `postal_codes` テーブルに対して都道府県・市区町村・町域の完全一致で検索する。既存の Searcher / モジュールメソッドと同様に、Repository 経由で Rails 非依存のコアロジックを保つ。

---

## Technical Context

**Language/Version**: Ruby 3.0+（3.2 以上推奨）  
**Primary Dependencies**: Rails 7.x 以上（オプション）、RSpec、SimpleCov、RuboCop  
**Storage**: 都道府県コード⇔名称はメモリ内の定数マッピング。逆引きは既存の `jp_address_complement_postal_codes` テーブルを利用。  
**Testing**: RSpec（カバレッジ 90% 以上、SimpleCov 計測）  
**Target Platform**: Ruby gem（Rails 組み込み時は Railtie 経由）  
**Project Type**: Ruby gem（ライブラリ）  
**Performance Goals**:
- 都道府県コード⇔名称: &lt; 5ms（定数参照のため trivial）
- 逆引き: &lt; 50ms p99（既存 DB インデックス活用、後述の複合インデックス追加を推奨）
**Constraints**: Rubocop 100% PASS（disable 禁止）、TDD 必須  
**Scale/Scope**: 47 都道府県のマッピング、逆引きは既存の約 12 万件の郵便番号データに対して完全一致検索。  
**Encoding**: 入力・出力とも UTF-8。既存仕様と同一。

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Gem-First**: 機能はすべて `JpAddressComplement` 名前空間に閉じる。都道府県マッピングは gem 内の定数、逆引きは既存 Repository の拡張のみ。責務は「住所・郵便番号の補完・変換」の範囲内。
- [x] **II. TDD**: 新機能に対し先にテストを書き、Red-Green-Refactor を厳守。既存の FakeRepository パターンを拡張して逆引きをテスト可能にする。
- [x] **III. Rubocop**: 新規・変更コードは `rubocop:disable` なしで 100% パス。
- [x] **IV. データ整合性**: 新規テーブルは追加しない。既存の郵便番号データと JIS X 0401 の都道府県コード体系を一致させて使用。インポート戦略は変更なし。
- [x] **V. 機能要件**: 都道府県コード→名称・名称→コード・逆引きの 3 機能を明確なインターフェースで提供。該当なし時は仕様どおりコード⇔名称は `nil`、逆引きは `[]`。不正入力は例外を投げず `nil` / `[]` で応答。
- [x] **VI. シンプルさ**: 都道府県マッピングは 47 件の静的なハッシュ/定数で足りる（YAGNI）。逆引きは既存 Repository に 1 メソッド追加で対応。

**Constitution Check Result**: ✅ 全ゲート PASS

---

## Project Structure

### Documentation (this feature)

```text
specs/004-prefecture-code-reverse-lookup/
├── plan.md              # このファイル
├── spec.md              # 機能仕様
├── research.md          # Phase 0 調査
├── data-model.md        # Phase 1 データモデル
├── quickstart.md        # Phase 1 利用者向けガイド
├── contracts/           # Phase 1 API コントラクト
│   └── public-api-prefecture-and-reverse.md
└── tasks.md             # （/speckit.tasks で生成）
```

### Source Code (repository root)

既存構造を拡張するのみ。新規ディレクトリは作らない。

```text
lib/jp_address_complement/
├── jp_address_complement.rb     # モジュールメソッド 3 つ追加（後述）
├── searcher.rb                  # 逆引きメソッド 1 つ追加
├── prefecture.rb                # 新規: 都道府県コード⇔名称（定数＋メソッド）
├── repositories/
│   ├── postal_code_repository.rb           # find_postal_codes_by_address を追加
│   └── active_record_postal_code_repository.rb  # 上記の実装
└── （その他既存ファイルは変更なし）

spec/
├── jp_address_complement/
│   └── prefecture_spec.rb        # 新規: 都道府県変換のユニットテスト
├── searcher_spec.rb              # 逆引きのテストを追加
├── repositories/
│   └── active_record_postal_code_repository_spec.rb  # find_postal_codes_by_address のテスト
└── （既存テストは必要に応じて拡張）
```

**Structure Decision**: 既存の gem レイアウトを維持。都道府県ロジックは `Prefecture` モジュール（定数＋クラスメソッド）に集約し、逆引きは `Searcher` と `PostalCodeRepository` に追加する。

---

## Complexity Tracking

（本機能では Constitution 違反はなく、記録不要）
