# Public API Contract: 都道府県コード変換・住所逆引き（004 追加 API）

**Gem**: `jp_address_complement`  
**Namespace**: `JpAddressComplement`  
**Contract Type**: Ruby Public API（004 で追加する公開インターフェース）

---

## 追加するモジュールメソッド

既存の `search_by_postal_code` / `search_by_postal_code_prefix` / `valid_combination?` に加え、以下 3 つを提供する。

---

### `prefecture_name_from_code(code) → String | nil`

都道府県コード（JIS X 0401、2桁）から都道府県名を返す。

**引数**

| 名前 | 型 | 説明 |
|-----|----|------|
| `code` | `String`, `Integer`, `nil` | 都道府県コード。数値（例: 13）またはゼロパディング文字列（例: "13", "01"）。 |

**戻り値**: `String` または `nil`

- 有効なコード（01–47）の場合は対応する都道府県名（例: "東京都"）。
- 存在しないコード・範囲外・nil・空文字の場合は `nil`。例外は発生しない。

**例**

```ruby
JpAddressComplement.prefecture_name_from_code("13")   # => "東京都"
JpAddressComplement.prefecture_name_from_code(13)     # => "東京都"
JpAddressComplement.prefecture_name_from_code("01")   # => "北海道"
JpAddressComplement.prefecture_name_from_code(99)     # => nil
JpAddressComplement.prefecture_name_from_code(nil)    # => nil
JpAddressComplement.prefecture_name_from_code("")     # => nil
```

---

### `prefecture_code_from_name(name) → String | nil`

都道府県名（正式名称）から都道府県コードを 2 桁の文字列で返す。

**引数**

| 名前 | 型 | 説明 |
|-----|----|------|
| `name` | `String`, `nil` | 都道府県の正式名称（例: "東京都", "北海道"）。省略表記は受け付けない。 |

**戻り値**: `String` または `nil`

- 正式名称に一致する場合は 2 桁の文字列（例: "13", "01"）。ゼロパディングを維持する。
- 一致しない場合・nil・空文字の場合は `nil`。例外は発生しない。

**例**

```ruby
JpAddressComplement.prefecture_code_from_name("東京都")  # => "13"
JpAddressComplement.prefecture_code_from_name("北海道")  # => "01"
JpAddressComplement.prefecture_code_from_name("東京")    # => nil（省略表記は不可）
JpAddressComplement.prefecture_code_from_name("不明")    # => nil
JpAddressComplement.prefecture_code_from_name(nil)       # => nil
JpAddressComplement.prefecture_code_from_name("")        # => nil
```

---

### `search_postal_codes_by_address(pref:, city:, town: nil) → Array<String>`

都道府県・市区町村・町域（任意）を指定し、該当する郵便番号の候補一覧を返す（逆引き）。

**引数**

| 名前 | 型 | 必須 | 説明 |
|-----|----|------|------|
| `pref` | `String` | ✅ | 都道府県名（正式名称）。住所データの `pref` と完全一致。 |
| `city` | `String` | ✅ | 市区町村名。住所データの `city` と完全一致。 |
| `town` | `String` | ❌ | 町域名。省略時は都道府県＋市区町村のみで検索。指定時は完全一致で絞り込む。 |

**戻り値**: `Array<String>`

- 該当する郵便番号（7桁文字列）の配列。重複は除く。
- 該当なし・pref または city が nil/空・入力不十分の場合は `[]`。例外は発生しない。

**照合**: 各フィールドは既存の住所データ（`pref`, `city`, `town`）と **完全一致**。入力はデータと同じ表記を前提とする。

**例**

```ruby
# 都道府県・市区町村・町域を指定
JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: "千代田区", town: "千代田")
# => ["1000001", ...]

# 町域は省略（都道府県＋市区町村のみ）
JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: "千代田区")
# => ["1000001", "1000002", ...]

# 該当なし
JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: "存在しない区")
# => []

# 入力不十分（検索しない）
JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: nil)
# => []
JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: "")
# => []
```

---

## Repository の拡張（内部契約）

`JpAddressComplement::Repositories::PostalCodeRepository` に以下を追加する。

### `find_postal_codes_by_address(pref:, city:, town: nil) → Array<String>`

- 都道府県・市区町村・町域で完全一致検索し、郵便番号の配列を返す。
- pref または city が nil/空の場合は `[]` を返す。
- 実装は `ActiveRecordPostalCodeRepository` で、既存の `postal_codes` テーブルに対して `WHERE pref = ? AND city = ? AND (town = ? OR town IS NULL)` に相当するクエリを発行し、結果の postal_code を重複排除して返す。
