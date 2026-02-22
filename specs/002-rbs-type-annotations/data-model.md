# Data Model: RBS 型注釈（型構造）

**Branch**: `002-rbs-type-annotations`  
**Date**: 2026-02-22

本ドキュメントは DB スキーマではなく、**型定義（RBS）の構造**を記述する。エンティティは「どの .rbs に何を定義するか」および「主要な型の形」とする。

---

## 1. sig/ ディレクトリ構成

```text
sig/
├── jp_address_complement.rbs          # トップレベルモジュール（rbs-inline 生成）
├── jp_address_complement/             # 名前空間別（rbs-inline 生成）
│   ├── address_record.rbs             # Data の手動補完が必要な場合は manual を参照
│   ├── configuration.rbs
│   ├── normalizer.rbs
│   ├── searcher.rbs
│   ├── repositories/
│   │   ├── postal_code_repository.rbs
│   │   └── active_record_postal_code_repository.rbs
│   ├── models/
│   │   └── postal_code.rbs
│   ├── validators/
│   │   └── address_validator.rbs
│   ├── importers/
│   │   └── csv_importer.rbs
│   └── generators/
│       └── ...
└── manual/                            # 手動定義（rbs-inline で上書きされない）
    └── address_record.rbs             # AddressRecord の全フィールド型
```

- **自動生成**: `rbs-inline --output sig/ lib/` により `sig/` 直下および `sig/jp_address_complement/` 以下が更新される。
- **手動**: `sig/manual/` のみ開発者が編集する。主に `Data.define` 由来の `AddressRecord` 用。

---

## 2. AddressRecord（手動 RBS）

`lib/jp_address_complement/address_record.rb` は `Data.define`（Ruby 3.2+）で定義されている。rbs-inline が十分な型を生成しないため、`sig/manual/address_record.rbs` で全フィールドを明示する。

### フィールドと型

| フィールド | 型（RBS） | 説明 |
|-----------|-----------|------|
| `postal_code` | `String` | 7桁郵便番号（ハイフンなし） |
| `pref_code` | `String` | 都道府県コード |
| `pref` | `String` | 都道府県名 |
| `city` | `String` | 市区町村名 |
| `town` | `String?` | 町域名（nil 可） |
| `kana_pref` | `String?` | 都道府県カナ |
| `kana_city` | `String?` | 市区町村カナ |
| `kana_town` | `String?` | 町域カナ |
| `has_alias` | `bool` | 通称フラグ |
| `is_partial` | `bool` | 丁目区分フラグ |
| `is_large_office` | `bool` | 大口事業所フラグ |

### 定義方針

- RBS では `class` または `interface` で上記属性を持つ型を定義する。
- `sig/jp_address_complement/address_record.rbs` が rbs-inline で生成される場合、`sig/manual/address_record.rbs` を `sig/` から参照する形（例: 型エイリアスや require 相当）で整合させる。Steep が両方を読みにいく設定とする。

---

## 3. 公開 API の型シグネチャ（要約）

以下は FR-008 で要求される「公開メソッドの引数・返り値型」の要約。詳細は `contracts/rbs-public-api.md` を参照。

| メソッド | 引数 | 返り値 |
|----------|------|--------|
| `JpAddressComplement.search_by_postal_code` | `(code: String)` | `Array[AddressRecord]` |
| `JpAddressComplement.search_by_postal_code_prefix` | `(prefix: String)` | `Array[AddressRecord]` |
| `JpAddressComplement.valid_combination?` | `(postal_code: String, address: String)` | `bool` |
| `JpAddressComplement.configure` | ブロック `(Configuration) -> void` | `void` |
| `JpAddressComplement.configuration` | なし | `Configuration` |

---

## 4. Repository インターフェース（RBS）

`Repositories::PostalCodeRepository` は抽象インターフェースとして RBS で定義する（FR-009）。実装は `find_by_code` / `find_by_prefix`（現行実装に合わせる）。

| メソッド | シグネチャ |
|----------|------------|
| `find_by_code` | `(code: String) -> Array[AddressRecord]` |
| `find_by_prefix` | `(prefix: String) -> Array[AddressRecord]` |

`ActiveRecordPostalCodeRepository` はこのインターフェースに従うクラスとして定義する。

---

## 5. その他対象クラス・モジュール

以下のすべてに型シグネチャ（rbs-inline または手動）を定義する（FR-007）。

- `Configuration` — 設定オブジェクト（`repository` アクセサ等）
- `Normalizer` — 正規化メソッドの入出力型
- `Searcher` — `search_by_postal_code` / `search_by_postal_code_prefix` / `valid_combination?`
- `Repositories::PostalCodeRepository` — 上記インターフェース
- `Repositories::ActiveRecordPostalCodeRepository` — 上記実装
- `Validators::AddressValidator` — ActiveModel バリデーター
- `Importers::CsvImporter` — インポートメソッド
- Generators — ジェネレータークラス

---

## 6. Steep からの参照関係

```
Steepfile
  └── target :lib
        signature "sig"   → sig/*.rbs, sig/jp_address_complement/**/*.rbs, sig/manual/*.rbs
        check "lib"       → lib/**/*.rb（rbs-inline コメントは参照しない。生成済み .rbs を参照）
```

- `sig/manual/` は `signature "sig"` に含まれるため、Steep は `sig/` 全体を読みにいく。
- rbs-inline は `lib/` のコメントから `sig/` を生成するだけであり、Steep の実行時には生成済み `.rbs` が存在している前提とする。
