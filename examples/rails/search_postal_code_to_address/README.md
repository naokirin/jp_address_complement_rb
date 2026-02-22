# 郵便番号→住所検索サンプル（Rails）

[jp_address_complement](https://github.com/naokirin/jp_address_complement) の公開インターフェースを試せるサンプル Rails アプリです。

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

ブラウザで http://localhost:3000 を開くと、画面上部のナビから次の5つのデモを試せます。

| デモ | 対応 API | 説明 |
|------|----------|------|
| 郵便番号→住所（7桁） | `search_by_postal_code` | 7桁完全一致で住所を検索 |
| プレフィックス検索 | `search_by_postal_code_prefix` | 先頭4桁以上で候補を絞り込み |
| 整合性チェック | `valid_combination?` | 郵便番号と住所の組み合わせが正しいか判定 |
| 都道府県コード⇔名 | `prefecture_name_from_code` / `prefecture_code_from_name` | JIS都道府県コードと都道府県名の相互変換 |
| 住所→郵便番号の逆引き | `search_postal_codes_by_address` | 都道府県・市区町村・町域から郵便番号一覧を取得 |

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

- **ルート** `/` … 各デモへのナビと郵便番号→住所（7桁）のフォーム
- **コントローラ** `AddressesController` … 各アクションで `JpAddressComplement` の API を呼び出し
- **DB** SQLite（`storage/development.sqlite3`）
- **gem** `jp_address_complement` を Gemfile の `path: "../../../"` で参照
