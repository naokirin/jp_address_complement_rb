# Research: 日本住所補完 Gem — Phase 0 調査結果

**Branch**: `001-jp-address-complement-gem`  
**Date**: 2026-02-22  
**Status**: Complete

---

## 1. Repository パターン（Rails 非依存コア）

### Decision
コア検索ロジックは `PostalCodeRepository` インターフェースを介してデータアクセスする。
Rails 環境向けに `ActiveRecordPostalCodeRepository` を同梱し、他環境では利用者がアダプターを注入できる設計とする。

### Rationale
- Repository が返す値は Plain Ruby の `AddressRecord` 構造体（Struct/Data）とする。ActiveRecord インスタンスを返さないことで、コアロジックへの AR 依存を完全に排除できる。
- テスト時にはメモリ実装（`FakePostalCodeRepository`）を注入することで、DBへの依存なくコアロジックを単体テストできる（TDD 親和性 ◎）。

### Alternatives Considered
- **ActiveRecord 直接依存**: 最もシンプルだが Rails 以外での利用が不可能になり FR-015 に違反する。
- **rom-rb (Ruby Object Mapper)**: データマッパーパターンで AR 依存を排除できるが、利用者側にも rom-rb の学習コストが生じ、シンプルさ原則（VI）に反する。
- **dry-rb/dry-container でのDI**: 本格的な DI コンテナで柔軟性が高いが YAGNI 違反。シンプルなコンストラクタ注入で十分。

### Interface Design
```ruby
module JpAddressComplement
  module Repositories
    # インターフェース（Duck typing、RBS で型定義も提供）
    class PostalCodeRepository
      # @param code [String] 7桁郵便番号
      # @return [Array<AddressRecord>]
      def find_by_code(code) = raise NotImplementedError

      # @param prefix [String] 4桁以上の前方一致プレフィックス
      # @return [Array<AddressRecord>]
      def find_by_prefix(prefix) = raise NotImplementedError
    end
  end
end
```

---

## 2. Railtie / Generator 設計

### Decision
- `JpAddressComplement::Railtie` を通じて Rails に統合する。
- `rails g jp_address_complement:install` でマイグレーションファイルを `db/migrate/` に生成する（Devise パターン）。
- Railtie の initializer でデフォルトリポジトリ（`ActiveRecordPostalCodeRepository`）を DI コンテナへ登録する。

### Rationale
- Railtie は軽量で、モデル・ビューを持たない Gem では Engine より Railtie の方が適切（Constitution I 準拠）。
- Generator によるマイグレーション生成は Rails コミュニティ標準のパターン（devise, kaminari 等と同様）。
- Rails 以外の環境では Railtie がロードされないため、コア機能に影響しない。

### Alternatives Considered
- **Rails::Engine**: 不要なルーティング/ビュー機能が含まれ、オーバースペック。
- **自動テーブル作成**: 利用者の制御が失われる。standard_procedures に反する。

---

## 3. CSV インポート — 文字コード変換

### Decision
`CSV.foreach(path, encoding: 'Shift_JIS:UTF-8', ...)` で Shift_JIS→UTF-8 変換をストリーミング処理する。Ruby 標準ライブラリのみで実現可能。

### Rationale
- Ruby の `CSV.foreach` は `encoding: 'src:dst'` 形式でトランスコードをストリーム処理できる。
- メモリ効率が高く（全件をメモリに載せない）、12万件程度では問題なし。
- 外部ライブラリ不要でシンプルさ原則（VI）に合致。

---

## 4. バッチ upsert — パフォーマンス設計

### Decision
`ActiveRecord::Base.connection.upsert_all`（Rails 6+ 標準）を 1,000 件/バッチで分割実行する。

### Benchmark Evidence
| 件数 | 手法 | 所要時間 |
|------|------|---------|
| 100,000 | `upsert_all` | 約 3〜4 秒 |
| 100,000 | `activerecord-import` | 約 4.8 秒 |
| 1,000,000 | `upsert_all` | 約 48.7 秒 |

- 12万件 ✕ upsert_all（1,000件/バッチ）= 推定 **3〜5 秒**。SC-004（60秒以内）を十分に満足。
- Rails 7 の `upsert_all` は `update_only` / `record_timestamps` オプションで制御が容易。

### Alternatives Considered
- **activerecord-import gem**: バリデーション付きインポートが必要な場合に検討。今回は Rake タスクが事前バリデーション済み CSV を前提とするため不要。
- **PostgreSQL COPY コマンド**: 100万件超でメリットが出るが、DB 非依存が必要な本 Gem では採用しない。

### Idempotency Strategy
- `upsert_all` の unique key: `postal_code` カラム
- 同一郵便番号が複数レコード（大口事業所等）存在するため、`(postal_code, city, town)` の複合キーを一意制約の対象とする。
- 削除された郵便番号の検出は初期版では対応しない（Deferred）。

---

## 5. 文字列照合（`valid_combination?`）

### Decision
`String#include?` で部分一致検索する。照合対象は「都道府県名 + 市区町村名 + 町域名」の連結文字列。

```ruby
address_string.include?(record.pref + record.city + record.town)
```

### Rationale
- DB クエリではなくアプリ層で判定するため、高速かつシンプル。
- 同一郵便番号に複数レコードがある場合は `any?` で評価。
- 全角・半角の正規化は照合前に実施（`Unicode::NFC` または `String#unicode_normalize`）。

---

## 6. DB スキーマ設計

### インデックス戦略
- `postal_codes` テーブル
  - PK: `id`（`bigint`）
  - `postal_code VARCHAR(7)`: インデックス（完全一致検索 O(log n)）
  - `postal_code_prefix VARCHAR(3)`: 前方一致高速化のための派生カラム（先頭3桁）をインデックス化、またはプレフィックス LIKE インデックス
  - `pref_code VARCHAR(2)`, `pref VARCHAR(10)`, `city VARCHAR(50)`, `town VARCHAR(100)`, `kana_pref`, `kana_city`, `kana_town`

### LIKE インデックス vs. 派生カラム
- PostgreSQL: `LIKE 'prefix%'` は B-tree インデックスで最適化可能（`text_pattern_ops`）
- MySQL/MariaDB: `LIKE 'prefix%'` は先頭一致なら B-tree インデックスを使用
- SQLite: 同様に先頭一致 LIKE は B-tree インデックスが有効
- **結論**: 追加カラム不要。クエリを `WHERE postal_code LIKE ?` (`'1000%'`)で発行し、`postal_code` への B-tree インデックスで SC-003（50ms）を達成可能。

---

## 7. 未解決事項（Deferred）

| 項目 | 理由 |
|------|------|
| 削除済み郵便番号の検出 | 初期版スコープ外。差分インポートの複雑化を避ける（YAGNI） |
| RBS 型定義の提供 | 実装後に追加可能。初期版では不要 |
| 差分専用インポート（差分 CSV 活用） | 日本郵便の差分 CSV 形式が変動するリスクがあるため延期 |
