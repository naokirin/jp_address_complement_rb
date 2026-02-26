# カバレッジ確認レポート

**実施日**: 2026-02-26  
**現在のカバレッジ**: 行 95.21% (338/355)、分岐 90.76% (108/119)  
**未カバー**: 行 17、分岐 11

---

## 1. 重要度が高い未カバー（テスト追加を推奨）

### 1.1 モジュール公開 API の未カバー（`lib/jp_address_complement.rb`）

| 行 | 内容 | 重要度 | 理由 |
|----|------|--------|------|
| 99 | `valid_combination?(postal_code, address)` | 中 | モジュール経由の呼び出し経路。Searcher 単体ではテストされているが、`JpAddressComplement.valid_combination?` のワイヤリングが未検証。 |
| 116 | `search_postal_codes_by_address(pref:, city:, town: nil)` | **高** | 逆引き検索の**モジュール公開 API**。`searcher_spec` では Searcher インスタンス経由のみで、**モジュール経由のテストが存在しない**。 |

**推奨**: `spec/jp_address_complement_spec.rb` に以下を追加することを推奨します。

- `JpAddressComplement.search_postal_codes_by_address(pref:, city:, town: nil)` の example（`:us3` など既存タグでよい）
- 必要に応じて `JpAddressComplement.valid_combination?` が確実に 1 回は実行されることを確認（既存 example でカバーされている可能性はあるが、行 99 が 0 のため明示 1 例あると安心）

---

### 1.2 AddressRecord の Ruby 3.1 以下フォールバック（`lib/jp_address_complement/address_record.rb`）

| 行 | 内容 | 重要度 | 理由 |
|----|------|--------|------|
| 24-28 | `else` 分支: `Struct.new(...)`（Ruby &lt; 3.2） | 中 | 現在のテストは Ruby 3.2+ で `Data.define` のみ実行。Ruby 3.1 以下をサポートするなら、そのバージョンで CI を回すか、条件分岐の else をテストする必要がある。 |

**推奨**: Ruby 3.1 以下をサポートする場合は、該当バージョンでの CI 実行または `AddressRecord` の振る舞いテストで else 分支を検証する。

---

### 1.3 CSV インポートの `read_and_upsert` 先頭（`lib/jp_address_complement/importers/csv_importer.rb`）

| 行 | 内容 | 重要度 | 理由 |
|----|------|--------|------|
| 82-84 | `read_and_upsert` 内の `keys_in_csv = {}`、`total_upserted = 0`、`batch = []` | 要確認 | `import` は `read_and_upsert` を呼ぶため、通常はここを通る想定。カバレッジ 0 の場合は、実行順や require の影響の可能性がある。 |

**推奨**: 全 spec 実行後に再度カバレッジを取得し、82–84 行がまだ 0 なら、`CsvImporter#import` から `read_and_upsert` が確実に呼ばれる 1 例を追加する。

---

### 1.4 Rake タスク（`lib/tasks/jp_address_complement.rake`）

| 行 | 内容 | 重要度 | 理由 |
|----|------|--------|------|
| 11 | `rbs generate` タスクの `sh 'bundle exec rbs-inline ...'` | 低 | 開発用タスク。実際の `sh` 実行はタスク spec で未実行。 |
| 16 | `steep` タスクの `sh 'bundle exec steep check'` | 低 | 同上。 |

**推奨**: 必要なら `spec/tasks/` でタスクが定義され `invoke` 可能であることのテストに留め、`sh` の実行までテストするかはコストと相談。

---

## 2. 重要度が低い／許容しやすい未カバー

### 2.1 セッター・Rails 環境（`lib/jp_address_complement.rb`）

| 行 | 内容 | 理由 |
|----|------|------|
| 13 | `require_relative 'jp_address_complement/railtie' if defined?(Rails)` の **then** | テストが Rails 外で実行されているため、Rails 時の分支は未カバーで自然。 |
| 42 | `base_record_class=(klass)` | 設定用セッター。テストで未使用。 |
| 58 | `postal_code_table_name=(name)` | 同上。 |
| 119-122 | `private` と `default_repository` の定義 | テストで `configuration.repository` を差し替えているため、`default_repository` が呼ばれず 0。デフォルトリポジトリの単体テストを別で持つか、1 例だけ「repository 未設定で search を呼ぶ」テストを書くとカバー可能。 |

---

### 2.2 抽象メソッド（`lib/jp_address_complement/repositories/postal_code_repository.rb`）

| 行 | 内容 | 理由 |
|----|------|------|
| 31 | `find_postal_codes_by_address` の `NotImplementedError` | インターフェース用。実装は `ActiveRecordPostalCodeRepository` 側でテストされているため、基底の raise は未カバーで許容しやすい。 |

---

### 2.3 Prefecture（`lib/jp_address_complement/prefecture.rb`）

| 分岐 | 内容 | 理由 |
|------|------|------|
| 70 行の then | `code_from_name` で `name` が空文字/空白のみのときの `nil` 返却 | エッジケース。`code_from_name("")` や `code_from_name("  ")` の 1 例があると分岐カバーが上がる。 |
| 97・98 行の then/else | `normalize_code_string` の空文字チェック・正規表現マッチ | 同上。不正入力・空文字のテストでカバー可能。 |

---

### 2.4 KenAllDownloader（`lib/jp_address_complement/ken_all_downloader.rb`）

| 分岐 | 内容 | 理由 |
|------|------|------|
| 57 行 | `uri.port \|\| (uri.scheme == 'https' ? 443 : 80)` の then/else | 実際の HTTP 接続なしのテストのため、port の分岐が未カバー。ネットワークを伴うテストは別途検討。 |

---

## 3. まとめと優先アクション

- **最優先**: `JpAddressComplement.search_postal_codes_by_address` のモジュール経由のテストを 1 例以上追加する（行 116 は重要な公開 API）。
- **推奨**: `valid_combination?` のモジュール経由が確実に 1 回実行されることを確認する（既存 spec で足りていれば、行 99 の 0 は実行順などに起因する可能性あり）。
- **任意**: Prefecture の `code_from_name("")` / `name_from_code` のエッジケース、AddressRecord の Ruby &lt; 3.2 対応、Rake の rbs/steep タスク、`default_repository` の 1 例追加などは、リスクとコストに応じて対応。

以上で、テストで検証されていない行・分岐のうち、重要なロジックに関わる部分の洗い出しと優先度付けを完了しています。
