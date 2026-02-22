# Data Model: 日本住所補完 Gem

**Branch**: `001-jp-address-complement-gem`  
**Date**: 2026-02-22

---

## エンティティ一覧

### 1. `postal_codes` テーブル（DB永続化）

利用アプリケーションの DB に作成される住所データテーブル。Gem からマイグレーションを提供する。

#### スキーマ定義

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_jp_address_complement_postal_codes.rb
create_table :jp_address_complement_postal_codes do |t|
  t.string :postal_code,  limit: 7,   null: false  # 郵便番号（7桁、数字のみ）
  t.string :pref_code,    limit: 2,   null: false  # 都道府県コード（JIS X 0401）
  t.string :pref,         limit: 10,  null: false  # 都道府県名（漢字）
  t.string :city,         limit: 50,  null: false  # 市区町村名（漢字）
  t.string :town,         limit: 100, null: true   # 町域名（漢字）- nil 可（大口事業所等）
  t.string :kana_pref,    limit: 20,  null: true   # 都道府県名（カナ）
  t.string :kana_city,    limit: 100, null: true   # 市区町村名（カナ）
  t.string :kana_town,    limit: 200, null: true   # 町域名（カナ）
  t.boolean :has_alias,   default: false            # 通称あり（KEN_ALL フラグ）
  t.boolean :is_partial,  default: false            # 丁目区分あり
  t.boolean :is_large_office, default: false        # 大口事業所専用フラグ
  t.timestamps
end

# インデックス
add_index :jp_address_complement_postal_codes, :postal_code          # 完全一致
add_index :jp_address_complement_postal_codes, [:postal_code, :pref_code, :city, :town],
          unique: true, name: 'idx_jp_address_complement_unique'     # 冪等性保証
```

#### フィールド定義

| カラム名 | 型 | NOT NULL | 説明 |
|---------|-----|----------|------|
| `id` | bigint | ✅ | PK（自動採番） |
| `postal_code` | varchar(7) | ✅ | ハイフンなし7桁郵便番号 |
| `pref_code` | varchar(2) | ✅ | 都道府県コード（01〜47） |
| `pref` | varchar(10) | ✅ | 都道府県名（漢字） |
| `city` | varchar(50) | ✅ | 市区町村名（漢字） |
| `town` | varchar(100) | ❌ | 町域名（漢字）、以下一律で適用 |
| `kana_pref` | varchar(20) | ❌ | 都道府県カナ |
| `kana_city` | varchar(100) | ❌ | 市区町村カナ |
| `kana_town` | varchar(200) | ❌ | 町域カナ |
| `has_alias` | boolean | ✅ | 通称フラグ |
| `is_partial` | boolean | ✅ | 丁目区分フラグ |
| `is_large_office` | boolean | ✅ | 大口事業所フラグ |
| `created_at` | datetime | ✅ | 作成日時 |
| `updated_at` | datetime | ✅ | 更新日時 |

#### インデックス戦略

| インデックス名 | カラム | 用途 |
|--------------|--------|------|
| `idx_postal_code` | `(postal_code)` | US-1: 完全一致検索 O(log n) |
| `idx_jp_address_complement_unique` | `(postal_code, pref_code, city, town)` | 冪等 upsert の一意性制約 |

**先頭4桁前方一致**: `postal_code` への B-tree インデックスは `LIKE '1000%'` の先頭一致クエリに対して有効（PostgreSQL/MySQL/SQLite 共通）。追加インデックス不要。

---

### 2. `AddressRecord` — Plain Ruby 値オブジェクト

DB から取得したデータを Repository が返す際の値オブジェクト。ActiveRecord インスタンスを返さないことでコアロジックの AR 依存を排除する。

```ruby
module JpAddressComplement
  # Ruby 3.2+ Data クラス（immutable struct）
  AddressRecord = Data.define(
    :postal_code,     # String  — 7桁、ハイフンなし
    :pref_code,       # String  — 都道府県コード
    :pref,            # String  — 都道府県名
    :city,            # String  — 市区町村名
    :town,            # String? — 町域名（nilable）
    :kana_pref,       # String? — 都道府県カナ
    :kana_city,       # String? — 市区町村カナ
    :kana_town,       # String? — 町域カナ
    :has_alias,       # Boolean
    :is_partial,      # Boolean
    :is_large_office  # Boolean
  )
end
```

- **不変（Immutable）**: `Data.define` により凍結された値オブジェクト。
- **Ruby 3.0 互換**: `Data` クラスは Ruby 3.2 以降。3.0/3.1 では `Struct.new(..., keyword_init: true)` にフォールバック。

---

### 3. `PostalCodeRepository` — データアクセス抽象化インターフェース

```ruby
module JpAddressComplement
  module Repositories
    class PostalCodeRepository
      # @param code [String] 正規化済み7桁郵便番号
      # @return [Array<AddressRecord>]
      def find_by_code(code)
        raise NotImplementedError, "#{self.class}#find_by_code is not implemented"
      end

      # @param prefix [String] 4桁以上の郵便番号プレフィックス
      # @return [Array<AddressRecord>]
      def find_by_prefix(prefix)
        raise NotImplementedError, "#{self.class}#find_by_prefix is not implemented"
      end
    end
  end
end
```

---

### 4. `ActiveRecordPostalCodeRepository` — Rails 向け実装

```ruby
module JpAddressComplement
  module Repositories
    class ActiveRecordPostalCodeRepository < PostalCodeRepository
      MODEL_CLASS = "JpAddressComplement::PostalCode"  # AR モデル（遅延定数参照）

      def find_by_code(code)
        model.where(postal_code: code).map { to_record(_1) }
      end

      def find_by_prefix(prefix)
        model.where("postal_code LIKE ?", "#{prefix}%").map { to_record(_1) }
      end

      private

      def model = Object.const_get(MODEL_CLASS)

      def to_record(ar)
        AddressRecord.new(
          postal_code: ar.postal_code,
          pref_code:   ar.pref_code,
          pref:        ar.pref,
          city:        ar.city,
          town:        ar.town,
          kana_pref:   ar.kana_pref,
          kana_city:   ar.kana_city,
          kana_town:   ar.kana_town,
          has_alias:   ar.has_alias,
          is_partial:  ar.is_partial,
          is_large_office: ar.is_large_office
        )
      end
    end
  end
end
```

---

### 5. `PostalCode` — ActiveRecord モデル（Rails 環境のみ）

```ruby
module JpAddressComplement
  class PostalCode < ActiveRecord::Base
    self.table_name = "jp_address_complement_postal_codes"

    validates :postal_code, presence: true, format: { with: /\A\d{7}\z/ }
    validates :pref, :city, presence: true
  end
end
```

---

## エンティティ関係図

```
KEN_ALL.CSV (Shift_JIS, 外部ファイル)
    │
    │ Rake Task (Shift_JIS→UTF-8 変換 + upsert_all, 1,000件/バッチ)
    ▼
jp_address_complement_postal_codes (利用アプリの DB テーブル)
    │
    │ ActiveRecordPostalCodeRepository#find_by_code / find_by_prefix
    ▼
AddressRecord（Plain Ruby 値オブジェクト）
    │
    │ JpAddressComplement::Searcher (コアロジック)
    ▼
呼び出し元（Rails アプリ / Rack アプリ / RSpec テスト）
```

---

## データ検証ルール

| ルール | 適用箇所 |
|--------|---------|
| 郵便番号は7桁数字のみ（正規化後） | `Normalizer` クラス、`PostalCode` モデル |
| 全角数字→半角正規化 | `Normalizer` クラス（入力受付時） |
| ハイフン除去（〒100-0001 → 1000001） | `Normalizer` クラス（入力受付時） |
| 4桁未満プレフィックスは空返却 | `Searcher#search_by_prefix` のガード節 |
| nil/空文字/数字以外はエラーなしで空返却 | `Normalizer` では nil 返却、`Searcher` でガード |
| 不正 CSV 行は警告ログ出力してスキップ | `Importer` クラス |
