## [Unreleased]

## [0.3.0] - 2026-03-02

### Security

- **Zip Slip 脆弱性の修正**: 解凍先パスの検証を強化し、Zip Slip 攻撃を防止。あわせて `Dir.chdir` によるスレッド安全性の問題を解消

### Added

- 町域なしの住所も `valid_combination?` で一致とみなすように変更（テスト追加）

### Changed

- **ActiveSupport 依存の廃止**: `blank?` をネイティブ Ruby に置換
- **upsert_batch の改善**: N+1 DELETE を Arel バッチ削除に変更し、SQLite の式木深度上限エラーに対応（`DELETE_CHUNK_SIZE` 導入）
- **COL_* 定数の整理**: KenAll モジュールに集約し重複を解消
- README: `search_postal_codes_by_address` の戻り値を正しく記載

### Fixed

- RuboCop 違反の修正（Metrics/AbcSize 含む）および RBS シグネチャの更新

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
