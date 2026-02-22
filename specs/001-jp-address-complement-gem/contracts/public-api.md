# Public API Contract: JpAddressComplement

**Gem**: `jp_address_complement`  
**Namespace**: `JpAddressComplement`  
**Contract Type**: Ruby Public API（ライブラリの公開インターフェース定義）

---

## モジュールメソッド（`JpAddressComplement.*`）

### `search_by_postal_code(code) → Array<AddressRecord>`

郵便番号（7桁）に対応する住所レコードを返す。

**引数**

| 名前 | 型 | 説明 |
|-----|----|------|
| `code` | `String` | 郵便番号。ハイフンあり（`"100-0001"`）・全角数字・`〒` 記号はすべて自動正規化する |

**戻り値**: `Array<AddressRecord>`

- 一致するレコードが存在しない場合は `[]`（空配列）
- 同一郵便番号に複数レコードが存在する場合（大口事業所等）は全件返す

**エラー**: 不正入力（`nil`・空文字・数字以外を含む文字列）に対しては例外を発生させず `[]` を返す。

```ruby
# 成功例
JpAddressComplement.search_by_postal_code("1000001")
# => [#<data JpAddressComplement::AddressRecord
#           postal_code="1000001",
#           pref_code="13",
#           pref="東京都",
#           city="千代田区",
#           town="千代田",
#           kana_pref="トウキョウト",
#           kana_city="チヨダク",
#           kana_town="チヨダ",
#           has_alias=false,
#           is_partial=false,
#           is_large_office=false>]

# 正規化される入力例
JpAddressComplement.search_by_postal_code("100-0001")  # ハイフンあり
JpAddressComplement.search_by_postal_code("〒100-0001") # 〒付き
JpAddressComplement.search_by_postal_code("１０００００１")  # 全角数字

# 存在しない場合
JpAddressComplement.search_by_postal_code("0000000")  # => []

# 不正入力（エラーなし）
JpAddressComplement.search_by_postal_code(nil)        # => []
JpAddressComplement.search_by_postal_code("")         # => []
JpAddressComplement.search_by_postal_code("abc")      # => []
```

---

### `search_by_postal_code_prefix(prefix) → Array<AddressRecord>`

郵便番号の先頭4桁以上に一致する住所候補一覧を返す。

**引数**

| 名前 | 型 | 説明 |
|-----|----|------|
| `prefix` | `String` | 郵便番号の先頭部分（4桁以上）。全角数字は自動正規化 |

**戻り値**: `Array<AddressRecord>`

- 先頭4桁未満の場合は `[]`（過大結果防止のガード）
- 7桁完全一致の場合は `search_by_postal_code` と同等の結果

```ruby
# 先頭4桁
JpAddressComplement.search_by_postal_code_prefix("1000")
# => [#<data ... postal_code="1000001">, #<data ... postal_code="1000002">, ...]

# 先頭6桁
JpAddressComplement.search_by_postal_code_prefix("100000")
# => [#<data ... postal_code="1000001">]

# 先頭3桁以下 → 空返却
JpAddressComplement.search_by_postal_code_prefix("100")   # => []
JpAddressComplement.search_by_postal_code_prefix("10")    # => []
```

---

### `valid_combination?(postal_code, address) → Boolean`

郵便番号と住所文字列が整合しているかを検証する。

**引数**

| 名前 | 型 | 説明 |
|-----|----|------|
| `postal_code` | `String` | 郵便番号（自動正規化） |
| `address` | `String` | 住所文字列（番地・建物名が含まれていても可） |

**戻り値**: `Boolean`

- 郵便番号に対応するレコードの「都道府県名 + 市区町村名 + 町域名」が `address` に**部分一致**する場合は `true`
- 同一郵便番号に複数レコードがある場合はいずれか1件が一致すれば `true`
- 郵便番号が不正・存在しない場合は `false`

```ruby
JpAddressComplement.valid_combination?("1000001", "東京都千代田区千代田1-1 ○○ビル")  # => true
JpAddressComplement.valid_combination?("1000001", "東京都千代田区千代田")             # => true
JpAddressComplement.valid_combination?("1000001", "大阪府大阪市北区梅田")            # => false
JpAddressComplement.valid_combination?("0000000", "東京都千代田区千代田")            # => false（存在しない）
JpAddressComplement.valid_combination?(nil, "東京都...")                             # => false
```

---

### `configure { |config| ... }` — 設定ブロック

```ruby
JpAddressComplement.configure do |config|
  # カスタムリポジトリを注入（Rails 以外の環境向け）
  config.repository = MyCustomPostalCodeRepository.new
end
```

**設定オプション**

| オプション | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `repository` | `PostalCodeRepository` 準拠オブジェクト | `ActiveRecordPostalCodeRepository.new` | データアクセス実装 |

---

## 値オブジェクト: `AddressRecord`

`search_by_postal_code` および `search_by_postal_code_prefix` が返す値オブジェクト。

```ruby
record = JpAddressComplement.search_by_postal_code("1000001").first

record.postal_code      # => "1000001"  (String)
record.pref_code        # => "13"       (String)
record.pref             # => "東京都"   (String)
record.city             # => "千代田区" (String)
record.town             # => "千代田"   (String or nil)
record.kana_pref        # => "トウキョウト" (String or nil)
record.kana_city        # => "チヨダク"    (String or nil)
record.kana_town        # => "チヨダ"      (String or nil)
record.has_alias        # => false      (Boolean) 通称あり
record.is_partial       # => false      (Boolean) 丁目区分あり
record.is_large_office  # => false      (Boolean) 大口事業所専用
```

---

## ActiveModel バリデーター

```ruby
validates :postal_code_field, jp_address_complement: { address_field: :address_field_name }
```

**オプション**

| キー | 型 | 必須 | 説明 |
|-----|----|------|------|
| `address_field` | `Symbol` | ✅ | 住所文字列が格納されているモデルの属性名 |

**バリデーションの動作**

| 条件 | 結果 |
|------|------|
| `postal_code` フィールドが空 | バリデーターをスキップ（他バリデーターに委ねる） |
| 整合している | 通過 |
| 整合しない | `errors.add(:postal_code_field, "と住所が一致しません")` |

---

## Rake タスク

```bash
# インポート（Shift_JIS → UTF-8 変換を自動実行）
bundle exec rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV

# インポート進捗ログ付き
bundle exec rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV VERBOSE=true
```

**環境変数**

| 変数 | 必須 | 説明 |
|------|------|------|
| `CSV` | ✅ | KEN_ALL.CSV へのパス |
| `VERBOSE` | ❌ | `true` で進捗ログを出力（デフォルト: `false`） |
| `BATCH_SIZE` | ❌ | バッチ件数（デフォルト: `1000`） |

---

## Rails Generator

```bash
rails g jp_address_complement:install
```

**生成ファイル**

| ファイル | 説明 |
|---------|------|
| `db/migrate/YYYYMMDDHHMMSS_create_jp_address_complement_postal_codes.rb` | 住所テーブルマイグレーション |
