## [Unreleased]

### Changed

- **CSV インポート（003: 消えたレコード削除）**
  - `JpAddressComplement::Importers::CsvImporter#import` の戻り値を **Integer から `ImportResult`（Data.define :upserted, :deleted）に変更**（破壊的変更）
  - フルインポート時に、今回のCSVに存在しない住所レコードをストアから削除するようにした
  - 空CSV（有効行0件）の場合はインポートを拒否し、`JpAddressComplement::ImportError` を発生させる
  - Rake タスク `jp_address_complement:import` の完了メッセージを「インポート完了: upsert N 件, 削除 M 件」形式に変更

### Added

- **都道府県コード変換・住所逆引き（004）**
  - `JpAddressComplement.prefecture_name_from_code(code)` — 都道府県コード（2桁）から正式名称を返す（該当なしは nil）
  - `JpAddressComplement.prefecture_code_from_name(name)` — 都道府県の正式名称から2桁コードを返す（該当なしは nil）
  - `JpAddressComplement.search_postal_codes_by_address(pref:, city:, town: nil)` — 都道府県・市区町村・町域から郵便番号候補を逆引き（該当なし・入力不十分時は []）

- RBS type annotations and Steep type checking (see [specs/002-rbs-type-annotations](../specs/002-rbs-type-annotations/))
  - Public API and internal methods annotated with rbs-inline
  - `sig/` and `sig/manual/` for type definitions; `AddressRecord` hand-defined in `sig/manual/address_record.rbs`
  - Rake tasks: `rake rbs:generate` (generate RBS from annotations), `rake steep` (type check)
  - CI runs `bundle exec rake steep`; type errors fail the build

## [0.1.0] - 2026-02-22

- Initial release
