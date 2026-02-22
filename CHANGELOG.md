## [Unreleased]

### Added

- RBS type annotations and Steep type checking (see [specs/002-rbs-type-annotations](../specs/002-rbs-type-annotations/))
  - Public API and internal methods annotated with rbs-inline
  - `sig/` and `sig/manual/` for type definitions; `AddressRecord` hand-defined in `sig/manual/address_record.rbs`
  - Rake tasks: `rake rbs:generate` (generate RBS from annotations), `rake steep` (type check)
  - CI runs `bundle exec rake steep`; type errors fail the build

## [0.1.0] - 2026-02-22

- Initial release
