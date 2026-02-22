# クイックスタート: jp_address_complement

**バージョン**: 0.1.0 (予定)  
**対応 Ruby**: 3.0 以上  
**対応 Rails**: 7.0 以上

---

## インストール

```ruby
# Gemfile
gem 'jp_address_complement'
```

```bash
bundle install
```

---

## セットアップ（Rails）

### 1. マイグレーションを生成する

```bash
rails g jp_address_complement:install
```

`db/migrate/YYYYMMDDHHMMSS_create_jp_address_complement_postal_codes.rb` が生成されます。

### 2. マイグレーションを実行する

```bash
rails db:migrate
```

### 3. 郵便番号データをインポートする

日本郵便のサイトから KEN_ALL.CSV をダウンロードします。

- URL: https://www.post.japanpost.jp/zipcode/dl/oogaki/zip/ken_all.zip

```bash
# ZIP を展開して CSV を取得後（例: ~/Downloads/KEN_ALL.CSV）
bundle exec rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV
```

文字コード（Shift_JIS → UTF-8）変換は自動で行われます。
ダウンロードしたそのままの CSV を指定してください。

---

## 基本的な使い方

### 郵便番号から住所を取得する

```ruby
# 7桁（ハイフンなし）
results = JpAddressComplement.search_by_postal_code("1000001")
# => [#<data JpAddressComplement::AddressRecord postal_code="1000001", pref="東京都", city="千代田区", town="千代田", ...>]

# ハイフンあり・〒記号あり も自動正規化
results = JpAddressComplement.search_by_postal_code("100-0001")
results = JpAddressComplement.search_by_postal_code("〒100-0001")

# 存在しない場合は空配列
results = JpAddressComplement.search_by_postal_code("0000000")
# => []
```

### 先頭4桁以上で候補を取得する

```ruby
# 先頭4桁で絞り込み
candidates = JpAddressComplement.search_by_postal_code_prefix("1000")
# => [#<data ... postal_code="1000001">, #<data ... postal_code="1000002">, ...]

# 先頭3桁以下は空返却（過大結果防止）
candidates = JpAddressComplement.search_by_postal_code_prefix("100")
# => []
```

### 郵便番号と住所の整合性を検証する

```ruby
# 都道府県名 + 市区町村名 + 町域名が入力住所に部分一致すれば true
JpAddressComplement.valid_combination?("1000001", "東京都千代田区千代田1-1")
# => true（番地が付加されていても true）

JpAddressComplement.valid_combination?("1000001", "大阪府大阪市北区")
# => false
```

---

## Rails モデルでバリデーションを使う

```ruby
class Order < ApplicationRecord
  validates :postal_code, presence: true
  validates :postal_code, jp_address_complement: { address_field: :address }
end
```

```ruby
order = Order.new(postal_code: "1000001", address: "東京都千代田区千代田1-1 ○○ビル")
order.valid?  # => true

order2 = Order.new(postal_code: "1000001", address: "大阪府大阪市北区")
order2.valid?  # => false
order2.errors[:postal_code]  # => ["と住所が一致しません"]
```

---

## Rails 以外の環境での使用（Rack / Sinatra）

```ruby
require 'jp_address_complement'
require 'my_custom_repository'  # 利用者が用意するリポジトリ実装

# カスタムリポジトリを注入
JpAddressComplement.configure do |config|
  config.repository = MyCustomPostalCodeRepository.new
end

# 以降は通常どおり使用可能
results = JpAddressComplement.search_by_postal_code("1000001")
```

---

## データ更新

```bash
# 最新の KEN_ALL.CSV をダウンロードして再インポート
bundle exec rake jp_address_complement:import CSV=/path/to/new/KEN_ALL.CSV
```

既存データは upsert（追加・更新）されます。更新タイミングは利用者が任意に決定してください。

---

## トラブルシューティング

| 問題 | 対処 |
|------|------|
| `jp_address_complement_postal_codes` テーブルが存在しない | `rails g jp_address_complement:install && rails db:migrate` を実行 |
| 検索結果が空になる | `rake jp_address_complement:import` でデータをインポートしているか確認 |
| 文字化けが起きる | KEN_ALL.CSV はそのまま渡してください（変換は自動） |
