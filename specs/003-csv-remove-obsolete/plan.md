# Implementation Plan: CSVインポート時の消えたレコード削除

**Branch**: `003-csv-remove-obsolete` | **Date**: 2025-02-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-csv-remove-obsolete/spec.md`

## Summary

KEN_ALL.CSV のフルインポート時に、今回のCSVに存在しない住所レコードをストアから削除する。削除は upsert が全て成功した後にのみ実行し、空CSVは拒否する。インポート完了時に追加・更新・削除件数を報告する。既存の `CsvImporter` を拡張し、一意キー `(postal_code, pref_code, city, town)` で「今回CSVに出現したキー集合」を保持したうえで、削除フェーズでそれに含まれない行を削除する。

## Technical Context

**Language/Version**: Ruby 3.x（3.2 以上推奨）  
**Primary Dependencies**: Rails 7.x、ActiveRecord、標準庫 CSV  
**Storage**: 単一テーブル `jp_address_complement_postal_codes`（既存）  
**Testing**: RSpec、SimpleCov 90% 以上  
**Target Platform**: Rails アプリケーション（Rake タスク経由）  
**Project Type**: Ruby gem（Rails Engine）  
**Performance Goals**: 既存インポート時間の約2倍以内を目安（upsert + 削除の二相）  
**Constraints**: Rubocop 100% パス、TDD 必須、既存一意キー `(postal_code, pref_code, city, town)` を変更しない  
**Scale/Scope**: KEN_ALL 相当の約12万行〜14万行の CSV を想定

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Gem-First**: 変更は `JpAddressComplement::Importers::CsvImporter` および Rake タスクに閉じ、gem 責務内。
- [x] **II. TDD**: テストを先に書き、Red-Green-Refactor で実装する。カバレッジ 90% 以上維持。
- [x] **III. Rubocop**: 100% パス、disable コメント禁止。
- [x] **IV. データ整合性**: 冪等性維持。削除は「今回のCSVに出現しなかったキー」に限定し、upsert 成功後に実施。Constitution の「削除検出は現在の全郵便番号セットに含まれない行を削除」に準拠。
- [x] **V. 機能要件**: 郵便番号検索・前方一致・不一致検出は変更しない。インポートの振る舞い拡張のみ。
- [x] **VI. シンプルさ**: 単一ストア・二相（upsert → delete）で YAGNI を守る。

## Project Structure

### Documentation (this feature)

```text
specs/003-csv-remove-obsolete/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1 (csv-import contract)
├── checklists/
│   └── requirements.md
└── tasks.md             # (/speckit.tasks - not created by plan)
```

### Source Code (repository root)

```text
lib/jp_address_complement/
├── importers/
│   └── csv_importer.rb   # 拡張: 二相インポート・件数集計・空CSV拒否
├── models/
│   └── postal_code.rb    # 既存（変更なし）
└── ...

lib/tasks/
└── jp_address_complement.rake  # 拡張: 件数報告出力（Rails 慣習）

spec/
├── importers/
│   └── csv_importer_spec.rb  # 拡張: 削除・空CSV・件数・失敗時
└── tasks/
    └── import_task_spec.rb   # 拡張: 出力メッセージ
```

**Structure Decision**: 既存の gem レイアウトをそのまま使用。新規テーブルは追加せず、`CsvImporter` と Rake タスクの拡張のみで完結する。

## Complexity Tracking

> 本機能では Constitution 違反はなく、追記なし。
