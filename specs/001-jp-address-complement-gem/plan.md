# Implementation Plan: 日本住所補完 Gem

**Branch**: `001-jp-address-complement-gem` | **Date**: 2026-02-22 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/001-jp-address-complement-gem/spec.md`

---

## Summary

日本国内の住所を郵便番号から補完・検証できる Rails 7.x 以上向け Ruby gem を実装する。  
**技術方針**: 住所データは利用アプリケーションの DB に永続化し（メモリロードなし）、インポートは Rake タスク経由とする。コア検索ロジックは Repository パターンで ActiveRecord 依存を排除し、Rails 以外の環境でも動作可能な設計とする。

---

## Technical Context

**Language/Version**: Ruby 3.0+（3.2 以上推奨）  
**Primary Dependencies**: Rails 7.x 以上、RSpec、SimpleCov、RuboCop  
**Storage**: 利用アプリケーションの DB（ActiveRecord 対応 DB であれば何でも可）。開発・テスト環境は SQLite。  
**Testing**: RSpec（カバレッジ 90% 以上、SimpleCov 計測）  
**Target Platform**: Ruby gem（Rail Engine ではなく Railtie を使用）  
**Project Type**: Ruby gem（Rails 組み込み型ライブラリ）  
**Performance Goals**:
- 郵便番号完全一致検索: < 10ms p99（DBインデックス使用前提）  
- 先頭4桁前方一致検索: < 50ms  
- Rake インポート（12万件）: < 60秒  
**Constraints**: Rubocop 100% PASS（disable 禁止）、TDD 必須  
**Scale/Scope**: 全国郵便番号（約12万件）を管理  
**Encoding**: KEN_ALL.CSV は Shift_JIS。Rake タスクが UTF-8 に自動変換。  
**Batch Strategy**: `upsert_all` + 1,000件/バッチ分割。冪等性は `(postal_code, pref_code, city, town)` の一意制約で保証。

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Gem-First**: `JpAddressComplement` 名前空間に閉じる。Railtie 経由で Rails 統合。Rails 非依存コアロジックを Repository パターンで実現。
- [x] **II. TDD**: テストを先に書く。RSpec + SimpleCov カバレッジ 90%+ の計画あり。FakeRepository でコアロジックを DB なしテスト可能。
- [x] **III. Rubocop**: `rubocop:disable` 使用禁止。`.rubocop.yml` で設定変更時は理由明記。CI に Rubocop ゲートを設定。
- [x] **IV. データ整合性**: `upsert_all`（ON CONFLICT DO UPDATE）で冪等インポート。1,000件/バッチで DB ロック最小化。Shift_JIS→UTF-8 変換を Rake タスクで自動実行。
- [x] **V. 機能要件**: 3機能（`search_by_postal_code` / `search_by_postal_code_prefix` / `valid_combination?`）のインターフェースを contracts/public-api.md で明確化。引数バリデーション・空返却挙動を定義済み。
- [x] **VI. シンプルさ**: Repository パターンの採用は FR-010/FR-015（Rails 非依存要件）で正当化済み。DI は Devise/Kaminari と同レベルのシンプルなコンストラクタ注入で実現。YAGNI 遵守（差分インポート・RBS・rom-rb は Deferred）。

**Constitution Check Result**: ✅ 全ゲート PASS

---

## Project Structure

### Documentation (this feature)

```text
specs/001-jp-address-complement-gem/
├── plan.md              ✅ このファイル
├── spec.md              ✅ 機能仕様
├── research.md          ✅ Phase 0 調査結果
├── data-model.md        ✅ データモデル設計
├── quickstart.md        ✅ 利用者向けガイド
├── contracts/
│   └── public-api.md    ✅ 公開 API コントラクト
└── tasks.md             （/speckit.tasks コマンドで生成）
```

### Source Code (repository root)

```text
jp_address_complement.gemspec
lib/
├── jp_address_complement.rb              # エントリポイント・モジュールメソッド定義
├── jp_address_complement/
│   ├── version.rb                        # VERSION 定数
│   ├── configuration.rb                  # Config クラス（repository DI 設定）
│   ├── railtie.rb                        # Rails Railtie（Rails 統合・initializer）
│   ├── address_record.rb                 # AddressRecord 値オブジェクト（Data/Struct）
│   ├── normalizer.rb                     # 郵便番号正規化（全角→半角・ハイフン除去）
│   ├── searcher.rb                       # コア検索ロジック（Repository 経由）
│   ├── repositories/
│   │   ├── postal_code_repository.rb     # 抽象基底クラス（インターフェース）
│   │   └── active_record_postal_code_repository.rb   # ActiveRecord 実装
│   ├── models/
│   │   └── postal_code.rb               # ActiveRecord モデル
│   ├── validators/
│   │   └── jp_address_complement_validator.rb  # ActiveModel バリデーター
│   ├── importers/
│   │   └── csv_importer.rb              # CSV インポートロジック
│   └── generators/
│       └── jp_address_complement/
│           ├── install_generator.rb      # rails g jp_address_complement:install
│           └── templates/
│               └── create_postal_codes.rb.erb  # マイグレーションテンプレート

lib/tasks/
└── jp_address_complement.rake            # jp_address_complement:import タスク

spec/
├── spec_helper.rb
├── jp_address_complement_spec.rb         # トップレベルモジュールメソッドの統合テスト
├── normalizer_spec.rb
├── searcher_spec.rb
├── repositories/
│   └── active_record_repository_spec.rb
├── validators/
│   └── jp_address_complement_validator_spec.rb
├── importers/
│   └── csv_importer_spec.rb
├── generators/
│   └── install_generator_spec.rb
└── support/
    ├── fake_repository.rb                # テスト用 FakeRepository
    └── database_helper.rb
```

**Structure Decision**: Ruby gem の標準構成（`lib/`, `spec/`, `lib/tasks/`）を採用。Generator テンプレートは Rails のコンベンションに従い `lib/generators/` 配下に配置。

---

## Complexity Tracking

| 複雑化要素 | 正当化理由 | より単純な代替案が却下される理由 |
|-----------|-----------|-------------------------------|
| Repository パターン | FR-010/FR-015: Rails 非依存コアが必須 | ActiveRecord 直接依存では Rack/Sinatra 環境での利用不可 |
| Railtie + Generator | FR-014: Rails 標準のマイグレーション管理 | 自動テーブル作成は利用者の制御を奪い、既存マイグレーション設計に干渉する |
| upsert_all バッチ分割 | SC-004: 60秒以内インポート＋ Constitution IV の冪等性要件 | 逐次 `find_or_create_by` では12万件に数分かかり SC-004 を満足できない |
