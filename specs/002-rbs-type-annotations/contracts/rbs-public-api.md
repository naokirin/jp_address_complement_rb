# RBS Public API Contract: JpAddressComplement

**Gem**: `jp_address_complement`  
**Feature**: 002-rbs-type-annotations  
**Contract Type**: 型シグネチャ（RBS）による公開 API 定義

このドキュメントは、FR-008 および FR-009 に基づき、`.rbs` に記述すべき**公開メソッドと Repository インターフェース**の型を契約として定義する。実装する RBS はこの契約に従うこと。

---

## 1. モジュールメソッド（`JpAddressComplement`）

以下のメソッドの引数・返り値型が `sig/` に正確に記述されていること。

### 1.1 `search_by_postal_code`

```rbs
# シグネチャ
def search_by_postal_code: (String) -> Array[JpAddressComplement::AddressRecord]
```

- **引数**: 郵便番号文字列（ハイフン・全角・〒 は正規化のため String のまま受け取り）。
- **返り値**: 対応する住所レコードの配列。存在しない場合は空配列。

### 1.2 `search_by_postal_code_prefix`

```rbs
def search_by_postal_code_prefix: (String) -> Array[JpAddressComplement::AddressRecord]
```

- **引数**: 郵便番号の先頭部分（4桁以上）。
- **返り値**: 候補レコードの配列。4桁未満の場合は空配列。

### 1.3 `valid_combination?`

```rbs
def valid_combination?: (String, String) -> bool
```

- **引数**: `(postal_code, address)`。
- **返り値**: 整合していれば `true`、そうでなければ `false`。

### 1.4 `configure`

```rbs
def configure: () { (JpAddressComplement::Configuration) -> void } -> void
```

- ブロックで `Configuration` を受け取り、設定を変更する。

### 1.5 `configuration`

```rbs
def configuration: () -> JpAddressComplement::Configuration
```

- 現在の設定オブジェクトを返す。

---

## 2. 値オブジェクト `AddressRecord`

`sig/manual/address_record.rbs`（または同等）に、以下の属性型がすべて定義されていること。

| 属性 | 型（RBS） |
|------|-----------|
| `postal_code` | `String` |
| `pref_code` | `String` |
| `pref` | `String` |
| `city` | `String` |
| `town` | `String?` |
| `kana_pref` | `String?` |
| `kana_city` | `String?` |
| `kana_town` | `String?` |
| `has_alias` | `bool` |
| `is_partial` | `bool` |
| `is_large_office` | `bool` |

- `AddressRecord` は `Data.define` により定義されているため、RBS では `class` または適切な構造で上記メンバを持つ型として定義する。

---

## 3. Repository インターフェース（`Repositories::PostalCodeRepository`）

抽象インターフェースとして、少なくとも以下のメソッドシグネチャを持つこと。  
※ 実装では `find_by_code` / `find_by_prefix` を使用しているため、RBS もこれに合わせる。

```rbs
module JpAddressComplement
  module Repositories
    class PostalCodeRepository
      def find_by_code: (String) -> Array[JpAddressComplement::AddressRecord]
      def find_by_prefix: (String) -> Array[JpAddressComplement::AddressRecord]
    end
  end
end
```

- **find_by_code**: 正規化済み 7 桁郵便番号で検索。
- **find_by_prefix**: 4 桁以上のプレフィックスで前方一致検索。

`ActiveRecordPostalCodeRepository` はこのインターフェースに従うクラスとして定義する。

---

## 4. 検証方法

- `bundle exec rake steep` がエラーゼロで終了すること。
- 利用側で `JpAddressComplement.search_by_postal_code(123)` のように誤った型を渡した場合、Steep が型エラーを報告すること。
- `sig/` 配下に、上記モジュールメソッド・`AddressRecord`・`PostalCodeRepository` のシグネチャが存在し、未定義の public メソッドがゼロであること（SC-003）。

---

## 5. 既存 API ドキュメントとの対応

Ruby の公開 API 仕様（引数・返り値・挙動）は `specs/001-jp-address-complement-gem/contracts/public-api.md` に定義されている。本契約はその型のみを RBS で表現したものであり、挙動の変更を意味しない。
