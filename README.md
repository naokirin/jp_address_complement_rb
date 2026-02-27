# JpAddressComplement

日本郵便の郵便番号データ（KEN_ALL 形式、UTF-8 版 utf_ken_all.csv）を用いて、Rails アプリで住所の補完・検索・検証を行うための gem です。

## 特徴

- **自前の RDB に住所情報を登録し、それを利用する**  
  外部 API や別サービスに問い合わせるのではなく、アプリのデータベース内に郵便番号・住所データを保持し、そのテーブルに対して検索・検証を行います。

- **運用時に外部サービスに依存しない**  
  住所補完や検証はすべて自前 DB に対して行うため、外部 API の障害・レート制限・仕様変更の影響を受けず、オフライン環境でも利用できます。

- **RDB のリレーションを活用できる**  
  郵便番号テーブルを自前で持つため、都道府県コードや市区町村名で他のテーブルと JOIN したり、アプリ固有のマスタと組み合わせたりしやすい設計です。

- **CSV を直接利用する方式も選べる**  
  データベースを使わず、ローカルに配置した KEN_ALL 形式の UTF-8 CSV（`utf_ken_all.csv`）をそのまま読み込んで検索する `CsvPostalCodeRepository` も利用できます。CSV のパスは設定で指定できます。

### 主な機能

- **郵便番号から住所を検索**（7桁完全一致・先頭4桁以上のプレフィックス検索）
- **住所から郵便番号の逆引き**
- **郵便番号と住所文字列の整合性検証**（フォーム用バリデーション）
- **都道府県コード（JIS X 0401）と都道府県名の相互変換**

## 必要環境

- Ruby 3.2 以上
- Rails 7.1 以上
- ActiveRecord 利用を前提としています

## インストール

### 1. Gem の追加

アプリの `Gemfile` に追加して `bundle install` します。

```ruby
gem 'jp_address_complement'
```

Bundler を使わない場合:

```bash
gem install jp_address_complement
```

### 2. テーブルの作成

郵便番号データを格納するマイグレーションを生成し、マイグレートします。

```bash
rails g jp_address_complement:install
rails db:migrate
```

### 3. 住所データのインポート

日本郵便の KEN_ALL 形式 CSV（UTF-8 版 `utf_ken_all.csv`）をインポートする必要があります。

**方法A: 公式サイトから UTF-8 版を自動ダウンロードしてインポート**

```bash
DOWNLOAD=1 rake jp_address_complement:import
```

**方法B: 手元の UTF-8 CSV ファイルを指定してインポート**

[郵便番号データダウンロード](https://www.post.japanpost.jp/zipcode/dl/utf-zip.html) から UTF-8 版の `utf_ken_all.zip` を取得し、展開した `utf_ken_all.csv` のパスを指定します。

```bash
CSV=/path/to/utf_ken_all.csv rake jp_address_complement:import
```

インポートには数分かかる場合があります。完了後、`jp_address_complement_postal_codes` テーブルにデータが入っている状態になります。

---

## 利用方法

### 郵便番号から住所を検索（7桁完全一致）

```ruby
# 郵便番号はハイフン・全角・〒記号があっても自動で正規化されます
records = JpAddressComplement.search_by_postal_code('1000001')
# => [#<Data AddressRecord ...>, ...]

records.each do |r|
  puts "#{r.pref} #{r.city} #{r.town}"  # 例: 東京都 千代田区 千代田
  puts r.postal_code   # "1000001"
  puts r.pref_code     # "13" (JIS都道府県コード)
end
```

### 郵便番号のプレフィックス検索（4桁以上）

入力中の郵便番号の先頭から候補を絞り込むときに使えます。

```ruby
records = JpAddressComplement.search_by_postal_code_prefix('1000')
# 先頭が "1000" で始まる郵便番号の住所レコードの配列
```

### 郵便番号と住所の整合性チェック

「この郵便番号とこの住所の組み合わせは正しいか？」を判定します。フォームのバリデーションに利用できます。

```ruby
JpAddressComplement.valid_combination?('1000001', '東京都千代田区千代田')
# => true

JpAddressComplement.valid_combination?('1000001', '大阪府大阪市北区')
# => false
```

### モデルでのバリデーション（AddressValidator）

`ActiveModel::Validations` と組み合わせて、郵便番号と住所フィールドの組み合わせを検証できます。

```ruby
class Order
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :postal_code, :address

  validates :postal_code, presence: true
  validates :address, presence: true
  validates_with JpAddressComplement::AddressValidator,
                 postal_code_field: :postal_code,
                 address_field: :address
end
```

`postal_code_field` / `address_field` を省略すると、それぞれ `:postal_code` / `:address` が使われます。

### 都道府県コードと都道府県名の変換

JIS X 0401 の都道府県コード（01〜47）と都道府県名の相互変換ができます。

```ruby
JpAddressComplement.prefecture_name_from_code(13)
# => "東京都"
JpAddressComplement.prefecture_name_from_code('13')
# => "東京都"

JpAddressComplement.prefecture_code_from_name('東京都')
# => "13"
```

### 住所から郵便番号を逆引き

都道府県・市区町村・町域を指定して、対応する郵便番号の一覧を取得します。

```ruby
codes = JpAddressComplement.search_postal_codes_by_address(
  pref: '東京都',
  city: '千代田区',
  town: '千代田'
)
# => ["1000001"] など、該当する郵便番号の配列
```

`town` は省略可能です。その場合は都道府県＋市区町村で検索されます。

### 設定のカスタマイズ（任意）

リポジトリ（データ取得の実装）を差し替えたい場合は、Rails の初期化処理などで設定できます。

```ruby
# config/initializers/jp_address_complement.rb
JpAddressComplement.configure do |config|
  config.repository = MyApp::CustomPostalCodeRepository.new
  # PostalCode モデルの継承元（未設定時は ActiveRecord::Base）
  config.postal_code_model_base = ApplicationRecord
  # 郵便番号テーブル名（未設定時は 'jp_address_complement_postal_codes'）。マイグレーションで別名のテーブルを作った場合に指定
  config.postal_code_table_name = 'my_postal_codes'
end
```

### CSV をローカルに配置して利用する（DB を使わない場合）

RDB やマイグレーションを使わず、KEN_ALL 形式（UTF-8 版 `utf_ken_all.csv`）の CSV をローカルに置いたまま検索だけ行いたい場合は、`CsvPostalCodeRepository` を使います。CSV のパスは任意に指定できます。

```ruby
require 'jp_address_complement'
require 'jp_address_complement/repositories/csv_postal_code_repository'

# CSV ファイルのパスを設定して Repository を差し替える
JpAddressComplement.configure do |config|
  config.repository = JpAddressComplement::Repositories::CsvPostalCodeRepository.new(
    '/path/to/utf_ken_all.csv'   # 任意のパスを指定可能（UTF-8 版）
  )
end

# 以降は search_by_postal_code など、既存の API をそのまま利用できる
records = JpAddressComplement.search_by_postal_code('1000001')
```

- 初回の検索時に CSV を読み込み、メモリ上にインデックスを構築します（2回目以降はメモリ検索のみ）。
- CSV は日本郵便の KEN_ALL 形式と同じ列構成を前提とし、UTF-8 版 `utf_ken_all.csv` を想定しています。

---

## Development

リポジトリをクローンしたあと、`bin/setup` で依存関係を入れます。`bin/console` で対話的にコードを試せます。

### 型チェック（RBS / Steep）

本 gem は [RBS](https://github.com/ruby/rbs) と [Steep](https://github.com/soutaro/steep) で静的型チェックを行っています。

```bash
bundle install
bundle exec rbs collection install   # 任意: サードパーティ RBS のインストール
bundle exec rake rbs:generate        # sig/ を rbs-inline から生成
bundle exec rake steep               # 型チェック（CI では exit 0 が必須）
```

詳細は [specs/002-rbs-type-annotations/quickstart.md](specs/002-rbs-type-annotations/quickstart.md) を参照してください。

ローカルに gem をインストールするには `bundle exec rake install` を実行します。新バージョンをリリースする場合は `lib/jp_address_complement/version.rb` のバージョンを更新し、`bundle exec rake release` でタグの作成・プッシュと [RubyGems.org](https://rubygems.org) への push が行われます。

## Contributing

バグ報告やプルリクエストは [GitHub のリポジトリ](https://github.com/naokirin/jp_address_complement) で歓迎しています。
