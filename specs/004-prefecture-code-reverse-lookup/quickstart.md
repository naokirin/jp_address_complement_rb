# クイックスタート: 都道府県コード変換・住所逆引き（004）

**前提**: 001 のセットアップ（マイグレーション・郵便番号データのインポート）が完了していること。  
逆引き機能は既存の `jp_address_complement_postal_codes` テーブルを利用します。都道府県コード⇔名称は DB 不要で利用できます。

---

## 都道府県コードから都道府県名を取得する

```ruby
# 2桁の文字列（ゼロパディング）
JpAddressComplement.prefecture_name_from_code("13")
# => "東京都"

JpAddressComplement.prefecture_name_from_code("01")
# => "北海道"

# 数値も受け付ける
JpAddressComplement.prefecture_name_from_code(13)
# => "東京都"

# 該当しないコード・nil・空文字の場合は nil（例外なし）
JpAddressComplement.prefecture_name_from_code(99)  # => nil
JpAddressComplement.prefecture_name_from_code(nil) # => nil
```

---

## 都道府県名から都道府県コードを取得する

```ruby
# 正式名称のみ有効（省略表記は不可）
JpAddressComplement.prefecture_code_from_name("東京都")
# => "13"

JpAddressComplement.prefecture_code_from_name("北海道")
# => "01"

# 戻り値は常に 2 桁の文字列（ゼロパディング維持）
JpAddressComplement.prefecture_code_from_name("北海道")
# => "01"

# 該当しない名称・省略表記・nil・空の場合は nil
JpAddressComplement.prefecture_code_from_name("東京") # => nil
JpAddressComplement.prefecture_code_from_name(nil)   # => nil
```

---

## 住所から郵便番号を検索する（逆引き）

都道府県・市区町村・町域を **分離した引数** で渡します。都道府県と市区町村は必須、町域は任意です。各フィールドは住所データと **完全一致** で照合されます（データと同じ表記で渡してください）。

```ruby
# 都道府県・市区町村・町域を指定
JpAddressComplement.search_postal_codes_by_address(
  pref: "東京都",
  city: "千代田区",
  town: "千代田"
)
# => ["1000001", ...]

# 町域は省略（都道府県＋市区町村に属する郵便番号をすべて返す）
JpAddressComplement.search_postal_codes_by_address(
  pref: "東京都",
  city: "千代田区"
)
# => ["1000001", "1000002", ...]

# 該当なし・入力不十分の場合は空配列（例外なし）
JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: "存在しない区")
# => []

JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: nil)
# => []
```

---

## パフォーマンス（逆引き）

逆引きの応答時間を 50ms 以下に保つため、次の複合インデックスの追加を推奨します（未追加の場合は data-model.md を参照）。

```ruby
# マイグレーション例（推奨）
add_index :jp_address_complement_postal_codes,
          [:pref, :city, :town],
          name: "idx_jp_address_complement_reverse_lookup"
```

既存の郵便番号テーブルに上記インデックスがない場合、データ量によってはクエリが遅くなる可能性があります。
