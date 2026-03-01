## [Unreleased]

## [0.2.0] - 2026-03-02

### Changed

- **Active Record をオプショナルに変更**
  - gemspec: `activerecord` / `railties` を runtime 依存から削除し、development 依存に移動
  - デフォルトリポジトリ・`base_record_class`: Gemfile のみで未 require の場合に備え、require を試してから利用するよう変更（`defined?` 判定を廃止）
  - Railtie: 同様に `require 'rails'` を試してから読み込むよう変更
  - `default_repository`: LoadError 時に利用者向けメッセージで `JpAddressComplement::Error` を発生
  - README: 必要環境・インストール手順に利用者側の対応を追記

## [0.1.0] - 2026-02-22

- Initial release
