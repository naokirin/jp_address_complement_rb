# Implementation Plan: RBS 型注釈の導入

**Branch**: `002-rbs-type-annotations` | **Date**: 2026-02-22 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/002-rbs-type-annotations/spec.md`

---

## Summary

gem の実装全体に RBS 型注釈を導入し、利用者（および IDE/LSP）が型情報を参照して安全に API を呼び出せるようにする。  
**技術方針**: `rbs-inline` でソース内に `# @rbs` アノテーションを記述し、`rbs-inline --output sig/ lib/` で `.rbs` を自動生成。Steep で `default` レベル型チェックを実行。`Data.define` の `AddressRecord` は `sig/manual/address_record.rbs` に手書き定義。Rake タスクで `rake rbs:generate`・`rake steep` を提供し、CI で型チェックをゲートとする。

---

## Technical Context

**Language/Version**: Ruby 3.2 以上（既存 gemspec 準拠）  
**Primary Dependencies**: 既存（Rails 7.x, RSpec, SimpleCov, RuboCop）＋ 開発依存: `rbs-inline`（~> 1.0）, `steep`, `rbs-rails`, `gem_rbs_collection`  
**Storage**: 変更なし（利用アプリケーションの DB）  
**Testing**: RSpec（既存）、型チェックは Steep。カバレッジ 90% 以上維持。  
**Target Platform**: Ruby gem（開発・CI で Steep 実行）  
**Project Type**: Ruby gem（Rails 組み込み型ライブラリ）— 型注釈追加のみ  
**Performance Goals**: 既存の郵便番号検索・インポート性能は変更しない  
**Constraints**: Rubocop 100% PASS（disable 禁止維持）、TDD 維持、型エラーゼロ（`# steep:ignore` は理由明記で最小限）  
**Scale/Scope**: `lib/` 配下全 `.rb` のメソッド（public/private/protected）に rbs-inline アノテーション、`sig/` と `sig/manual/` で型定義を管理

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Gem-First**: 型情報は `JpAddressComplement` 名前空間内の API を記述するのみ。外部名前空間を汚染しない。RBS/Steep は開発時ツールで gem 責務の範囲内（型付き API 提供）。
- [x] **II. TDD**: 既存 RSpec はすべてパス維持。型アノテーション追加は振る舞いを変えない。Rake タスク・Steepfile の追加はテスト可能な単位で TDD する。
- [x] **III. Rubocop**: `rubocop:disable` は使用しない。rbs-inline コメントと競合する場合は `.rubocop.yml` を最小限で調整し理由を明記。
- [x] **IV. データ整合性**: 本機能はデータ取り込み・永続化に変更を加えない。
- [x] **V. 機能要件**: 既存 3 機能（`search_by_postal_code` / `search_by_postal_code_prefix` / `valid_combination?`）および `configure`・`configuration` のシグネチャを正確に記述。新機能追加は行わない。
- [x] **VI. シンプルさ**: rbs-inline + Steep は Ruby 型周りの事実上の標準。手動 `sig/manual/` は `Data.define` の制約による最小限の例外。YAGNI で過剰な型抽象は導入しない。

**Constitution Check Result**: ✅ 全ゲート PASS

---

## Project Structure

### Documentation (this feature)

```text
specs/002-rbs-type-annotations/
├── plan.md              # このファイル (/speckit.plan コマンド出力)
├── spec.md              # 機能仕様
├── research.md          # Phase 0 出力 (/speckit.plan で生成)
├── data-model.md        # Phase 1 出力 (/speckit.plan で生成)
├── quickstart.md        # Phase 1 出力 (/speckit.plan で生成)
├── contracts/           # Phase 1 出力（必要に応じて型関連コントラクト）
└── tasks.md             # Phase 2 出力 (/speckit.tasks で生成 — plan では作成しない)
```

### Source Code (repository root)

既存の 001 で確立した構成を維持し、型用のディレクトリ・設定を追加する。

```text
# 既存（001 と同様）
lib/
├── jp_address_complement.rb
├── jp_address_complement/
│   ├── version.rb
│   ├── configuration.rb
│   ├── railtie.rb
│   ├── address_record.rb          # Data.define — 手動 RBS 対象
│   ├── normalizer.rb
│   ├── searcher.rb
│   ├── repositories/
│   │   ├── postal_code_repository.rb
│   │   └── active_record_postal_code_repository.rb
│   ├── models/
│   │   └── postal_code.rb
│   ├── validators/
│   │   └── address_validator.rb
│   ├── importers/
│   │   └── csv_importer.rb
│   └── generators/
│       └── jp_address_complement/ ...
lib/tasks/
└── jp_address_complement.rake     # ここに steep / rbs:generate タスクを追加するか、別 rake で管理

# 本機能で追加
sig/                                 # rbs-inline の出力先（自動生成）
├── jp_address_complement.rbs        # 等（rbs-inline が生成）
├── jp_address_complement/           # 名前空間別 .rbs
│   ├── address_record.rbs
│   ├── configuration.rbs
│   ├── normalizer.rbs
│   ├── searcher.rbs
│   ├── repositories/
│   │   ├── postal_code_repository.rbs
│   │   └── active_record_postal_code_repository.rbs
│   └── ...
└── manual/                          # 手動定義（rbs-inline で上書きされない）
    └── address_record.rbs           # Data.define 全フィールド型

Steepfile                            # プロジェクトルート。target: lib + sig、level: default
```

**Structure Decision**: 既存 `lib/` 構成はそのまま。`sig/` を新設し、自動生成は `sig/` 直下および `sig/jp_address_complement/` 以下、手動補完は `sig/manual/` に分離。Rake タスクは既存 `lib/tasks/jp_address_complement.rake` に `steep` と `rbs:generate` を追加するか、プロジェクト方針に合わせて別ファイルでも可。

---

## Complexity Tracking

| 複雑化要素 | 正当化理由 | より単純な代替案が却下される理由 |
|-----------|-----------|-------------------------------|
| RBS + Steep + rbs-inline の導入 | 利用者への型情報提供（P1）と開発時の型維持（P1）を満たすため | 型なしのままでは SC-001〜SC-005 および CC を満たせない |
| sig/manual の手動 RBS | `Data.define` の AddressRecord は rbs-inline の自動生成が完全に機能しないため | 手書き以外に正確な型を提供する手段がない |
| 開発依存 gem の追加（steep, rbs-inline, rbs-rails, gem_rbs_collection） | FR-002/FR-003: 生成・型チェックと Rails/AR 型の参照に必須 | これらなしでは Steep のエラーゼロと IDE 連携を達成できない |
