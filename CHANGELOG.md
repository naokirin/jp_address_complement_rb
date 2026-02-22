## [Unreleased]

### Changed

- **CSV インポート（003: 消えたレコード削除）**
  - `JpAddressComplement::Importers::CsvImporter#import` の戻り値を **Integer から `ImportResult`（Data.define :upserted, :deleted）に変更**（破壊的変更）
  - フルインポート時に、今回のCSVに存在しない住所レコードをストアから削除するようにした
  - 空CSV（有効行0件）の場合はインポートを拒否し、`JpAddressComplement::ImportError` を発生させる
  - Rake タスク `jp_address_complement:import` の完了メッセージを「インポート完了: upsert N 件, 削除 M 件」形式に変更

### Added

- RBS type annotations and Steep type checking (see [specs/002-rbs-type-annotations](../specs/002-rbs-type-annotations/))
  - Public API and internal methods annotated with rbs-inline
  - `sig/` and `sig/manual/` for type definitions; `AddressRecord` hand-defined in `sig/manual/address_record.rbs`
  - Rake tasks: `rake rbs:generate` (generate RBS from annotations), `rake steep` (type check)
  - CI runs `bundle exec rake steep`; type errors fail the build

## [0.1.0] - 2026-02-22

- Initial release
