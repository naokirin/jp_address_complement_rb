# 郵便番号→住所検索サンプル（Rails）

[jp_address_complement](https://github.com/naokirin/jp_address_complement) を使い、郵便番号から住所を検索する最小限の Rails アプリです。

## 前提

- Ruby 3.2+
- 親リポジトリ（`jp_address_complement_rb`）のルートで `bundle install` 済みであること

## セットアップ

```bash
cd examples/rails/search_postal_code_to_address
bundle install
bin/rails db:create db:migrate db:seed
```

## 起動

```bash
bin/rails server
```

ブラウザで http://localhost:3000 を開き、郵便番号（例: `1000001` または `100-0001`）を入力して「検索」を押すと住所一覧が表示されます。

## サンプルデータ

`db:seed` で次の郵便番号が登録されます。

| 郵便番号   | 住所例                 |
|-----------|------------------------|
| 1000001   | 東京都千代田区千代田 等 |
| 0600000   | 北海道札幌市中央区      |
| 1500002   | 東京都渋谷区渋谷        |

## 本番用データの投入（任意）

[日本郵便の郵便番号データ](https://www.post.japanpost.jp/zipcode/download.html) から **KEN_ALL.CSV** をダウンロードし、次で一括投入できます。

```bash
CSV=/path/to/KEN_ALL.CSV bin/rails jp_address_complement:import
```

## 構成

- **ルート** `/` … 郵便番号入力フォームと検索結果
- **コントローラ** `AddressesController#index` … `JpAddressComplement.search_by_postal_code` を呼び出し
- **DB** SQLite（`storage/development.sqlite3`）
- **gem** `jp_address_complement` を Gemfile の `path: "../../../"` で参照
