# Tasks: 日本住所補完 Gem (`jp_address_complement`)

**Input**: Design documents from `/specs/001-jp-address-complement-gem/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅

**TDD 方針**: 各タスクの実装は必ず「テストを先に書き → 失敗確認（RED） → 実装（GREEN） → リファクタ」の順で行う。  
**Rubocop**: 各コミット前に `bundle exec rubocop` が 100% PASS すること（`disable` コメント禁止）。  
**Coverage**: SimpleCov で 90% 以上を常時維持すること。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル、依存なし）
- **[Story]**: 対応するユーザーストーリー（US1〜US4）

---

## Phase 1: Setup（プロジェクト初期化）

**Purpose**: Gem の骨格・テスト基盤・Rubocop 設定を整備する

- [ ] T001 Gem の骨格を作成する（`bundle gem jp_address_complement` または手動）: `jp_address_complement.gemspec`, `lib/jp_address_complement.rb`, `lib/jp_address_complement/version.rb`
- [ ] T002 [P] `jp_address_complement.gemspec` に依存 gem を設定する（`activerecord`・`railties` を `add_dependency`、`rspec`・`simplecov`・`rubocop` を `add_development_dependency`）
- [ ] T003 [P] RSpec を初期化する: `spec/spec_helper.rb`（SimpleCov 計測・データベースクリーナー設定を含む）
- [ ] T004 [P] RuboCop の設定ファイルを作成する: `.rubocop.yml`（`rubocop-rails`・`rubocop-rspec` を有効化、プロジェクト固有の除外設定を明記）
- [ ] T005 [P] SQLite ベースのテスト用 DB 接続ヘルパーを作成する: `spec/support/database_helper.rb`（ActiveRecord を SQLite `:memory:` 接続、テーブル作成マイグレーションをここで実行）
- [ ] T006 [P] FakeRepository を作成する（TDD でコアロジックを DB なしでテストするためのメモリ実装）: `spec/support/fake_postal_code_repository.rb`

**Checkpoint**: `bundle exec rspec` が空で通過し、`bundle exec rubocop` が PASS すること

---

## Phase 2: Foundational（全ストーリーが依存する基盤）

**Purpose**: すべてのユーザーストーリー実装前に完了必須の共通基盤

⚠️ **CRITICAL**: このフェーズが完了するまでいかなるユーザーストーリー実装も開始しない

- [ ] T007 [P] `AddressRecord` の RSpec テストを実装する（TDD: 先に書いて RED を確認）: `spec/address_record_spec.rb`
- [ ] T008 `AddressRecord` 値オブジェクトを実装する（Ruby 3.2+ は `Data.define`、下位互換は `Struct`）: `lib/jp_address_complement/address_record.rb`
- [ ] T009 [P] `Normalizer` の RSpec テストを実装する（TDD: 先に書いて RED を確認）: `spec/normalizer_spec.rb`
- [ ] T010 `Normalizer` クラスを実装する（全角→半角変換・ハイフン除去・`〒` 除去・nil/不正入力で nil 返却）: `lib/jp_address_complement/normalizer.rb`
- [ ] T011 `PostalCodeRepository` 抽象基底クラスを実装する（`find_by_code` / `find_by_prefix` を `NotImplementedError` で定義）: `lib/jp_address_complement/repositories/postal_code_repository.rb`
- [ ] T012 [P] `Configuration` クラスを実装する（`repository` 属性の DI 設定）: `lib/jp_address_complement/configuration.rb`
- [ ] T013 [P] `JpAddressComplement` モジュールのトップレベル設定メソッドを実装する（`configure`, `configuration`, `reset_configuration!`）: `lib/jp_address_complement.rb`
- [ ] T014 [P] `PostalCode` ActiveRecord モデルを実装する（`table_name` 設定・基本バリデーション）: `lib/jp_address_complement/models/postal_code.rb`
- [ ] T015 [P] マイグレーションテンプレートを作成する（`postal_code`, `pref_code`, `pref`, `city`, `town`, `kana_*`, フラグ3つ、インデックス2つ）: `lib/generators/jp_address_complement/templates/create_jp_address_complement_postal_codes.rb.erb`

**Checkpoint**: `bundle exec rubocop` PASS / `bundle exec rspec` PASS / SimpleCov >= 90%

---

## Phase 3: User Story 1 — 郵便番号から住所を取得する (Priority: P1) 🎯 MVP

**Goal**: `JpAddressComplement.search_by_postal_code("1000001")` で住所レコードが返る

**Independent Test**:
```bash
bundle exec rspec spec/searcher_spec.rb spec/repositories/ spec/jp_address_complement_spec.rb --tag us1
```

### Tests for User Story 1（TDD: 必ず先に書いて RED を確認）

- [ ] T016 [P] [US1] `PostalCodeRepository` インターフェースの RSpec を実装する（メソッド未実装で `NotImplementedError` が発生することを確認）: `spec/repositories/postal_code_repository_spec.rb`
- [ ] T017 [P] [US1] `ActiveRecordPostalCodeRepository#find_by_code` の RSpec を実装する（`FakeRepository` ではなく SQLite メモリ DB を使用）: `spec/repositories/active_record_postal_code_repository_spec.rb`
- [ ] T018 [P] [US1] `Searcher#search_by_postal_code` の RSpec を実装する（`FakeRepository` 使用・正常系・空返却・不正入力）: `spec/searcher_spec.rb`
- [ ] T019 [P] [US1] トップレベル `JpAddressComplement.search_by_postal_code` の統合テストを実装する: `spec/jp_address_complement_spec.rb`

### Implementation for User Story 1

- [ ] T020 [P] [US1] `ActiveRecordPostalCodeRepository#find_by_code` を実装する（`postal_code` 完全一致 WHERE クエリ → `AddressRecord` 配列変換）: `lib/jp_address_complement/repositories/active_record_postal_code_repository.rb`
- [ ] T021 [US1] `Searcher` クラスを実装する（コンストラクタで `repository` を注入。`search_by_postal_code` メソッド: Normalizer で正規化 → Repository 委譲）: `lib/jp_address_complement/searcher.rb`
- [ ] T022 [US1] `JpAddressComplement.search_by_postal_code` モジュールメソッドを実装する（`configuration.repository` を使用した `Searcher` 呼び出し）: `lib/jp_address_complement.rb`
- [ ] T023 [US1] T016〜T022 がすべて GREEN になることを確認し、`bundle exec rubocop` をパスさせる

**Checkpoint**: `search_by_postal_code` が正常動作 / SimpleCov >= 90% / Rubocop PASS

---

## Phase 4: User Story 2 — 郵便番号の先頭数字から候補住所を取得する (Priority: P2)

**Goal**: `JpAddressComplement.search_by_postal_code_prefix("1000")` で候補一覧が返る

**Independent Test**:
```bash
bundle exec rspec spec/searcher_spec.rb spec/repositories/ --tag us2
```

### Tests for User Story 2（TDD: 必ず先に書いて RED を確認）

- [ ] T024 [P] [US2] `ActiveRecordPostalCodeRepository#find_by_prefix` の RSpec を実装する（SQLite メモリ DB。先頭4桁一致・4桁未満ガード・7桁完全一致）: `spec/repositories/active_record_postal_code_repository_spec.rb`
- [ ] T025 [P] [US2] `Searcher#search_by_postal_code_prefix` の RSpec を実装する（`FakeRepository` 使用・4桁未満は空返却）: `spec/searcher_spec.rb`
- [ ] T026 [P] [US2] トップレベル `JpAddressComplement.search_by_postal_code_prefix` の統合テストを実装する: `spec/jp_address_complement_spec.rb`

### Implementation for User Story 2

- [ ] T027 [P] [US2] `ActiveRecordPostalCodeRepository#find_by_prefix` を実装する（`WHERE postal_code LIKE ?` クエリ・`"#{prefix}%"` バインド）: `lib/jp_address_complement/repositories/active_record_postal_code_repository.rb`
- [ ] T028 [US2] `Searcher#search_by_postal_code_prefix` を実装する（Normalizer 正規化 → 4桁未満ガード → Repository 委譲）: `lib/jp_address_complement/searcher.rb`
- [ ] T029 [US2] `JpAddressComplement.search_by_postal_code_prefix` モジュールメソッドを実装する: `lib/jp_address_complement.rb`
- [ ] T030 [US2] `FakeRepository` に `find_by_prefix` を追加する: `spec/support/fake_postal_code_repository.rb`
- [ ] T031 [US2] T024〜T030 がすべて GREEN になることを確認し、`bundle exec rubocop` をパスさせる

**Checkpoint**: `search_by_postal_code_prefix` が正常動作 / SimpleCov >= 90% / Rubocop PASS

---

## Phase 5: User Story 3 — 郵便番号と住所の整合性を検証する (Priority: P3)

**Goal**: `JpAddressComplement.valid_combination?("1000001", "東京都千代田区千代田1-1")` が `true` を返す

**Independent Test**:
```bash
bundle exec rspec spec/searcher_spec.rb --tag us3
```

### Tests for User Story 3（TDD: 必ず先に書いて RED を確認）

- [ ] T032 [P] [US3] `Searcher#valid_combination?` の RSpec を実装する（`FakeRepository` 使用・部分一致 true / 不一致 false / 存在しない郵便番号 false / nil false）: `spec/searcher_spec.rb`
- [ ] T033 [P] [US3] トップレベル `JpAddressComplement.valid_combination?` の統合テストを実装する: `spec/jp_address_complement_spec.rb`

### Implementation for User Story 3

- [ ] T034 [US3] `Searcher#valid_combination?` を実装する（`find_by_code` → `any?` で `(record.pref + record.city + record.town.to_s).include?(address)` 判定。`town` が nil の場合も安全に処理する）: `lib/jp_address_complement/searcher.rb`
- [ ] T035 [US3] `JpAddressComplement.valid_combination?` モジュールメソッドを実装する: `lib/jp_address_complement.rb`
- [ ] T036 [US3] T032〜T035 がすべて GREEN になることを確認し、`bundle exec rubocop` をパスさせる

**Checkpoint**: `valid_combination?` が正常動作 / SimpleCov >= 90% / Rubocop PASS

---

## Phase 6: User Story 4 — Rails モデルでバリデーションを使用する (Priority: P4)

**Goal**: `validates :postal_code, jp_address_complement: { address_field: :address }` が動作する

**Independent Test**:
```bash
bundle exec rspec spec/validators/ spec/generators/ --tag us4
```

### Tests for User Story 4（TDD: 必ず先に書いて RED を確認）

- [ ] T037 [P] [US4] `JpAddressComplementValidator` の RSpec を実装する（整合 true / 不整合 false / 郵便番号空でスキップ / エラーメッセージ確認）: `spec/validators/jp_address_complement_validator_spec.rb`
- [ ] T038 [P] [US4] `InstallGenerator` の RSpec を実装する（`rails g jp_address_complement:install` でマイグレーションファイルが `db/migrate/` に生成されることを確認）: `spec/generators/install_generator_spec.rb`

### Implementation for User Story 4

- [ ] T039 [P] [US4] `JpAddressComplementValidator` を実装する（`ActiveModel::EachValidator` を継承・`address_field` オプションで対象フィールドを取得・`valid_combination?` 委譲・郵便番号空はスキップ）: `lib/jp_address_complement/validators/jp_address_complement_validator.rb`
- [ ] T040 [P] [US4] `InstallGenerator` を実装する（`Rails::Generators::Base` を継承・`copy_migration` でテンプレートを `db/migrate/` へコピー・タイムスタンプ付きファイル名生成）: `lib/generators/jp_address_complement/install_generator.rb`
- [ ] T041 [US4] `Railtie` を実装する（Rails 統合: デフォルトリポジトリの初期化・Rake タスクのロード・Generator の登録）: `lib/jp_address_complement/railtie.rb`
- [ ] T042 [US4] `lib/jp_address_complement.rb` の Railtie 自動ロードを設定する（`defined?(Rails)` での条件ロード）: `lib/jp_address_complement.rb`
- [ ] T043 [US4] T037〜T042 がすべて GREEN になることを確認し、`bundle exec rubocop` をパスさせる

**Checkpoint**: Rails バリデーター・Generator が正常動作 / SimpleCov >= 90% / Rubocop PASS

---

## Phase 7: Rake タスク — CSV インポート機能

**Purpose**: US1〜US4 すべての前提となる住所データ投入手段を提供する  
（論理的には基盤に近いが、コアロジックのテストは FakeRepository で代替できるため後回しにできる）

### Tests for Rake Task（TDD: 必ず先に書いて RED を確認）

- [ ] T044 [P] `CsvImporter` の RSpec を実装する（Shift_JIS テスト CSV を用意・UTF-8 変換確認・upsert 冪等性確認・不正行スキップ確認・CSV パスが存在しない場合は `Errno::ENOENT` または `JpAddressComplement::ImportError` を明確に発生させることを確認）: `spec/importers/csv_importer_spec.rb`
- [ ] T045 [P] Rake タスク実行テストを実装する（タスクが `jp_address_complement:import` というタスク名で存在すること、`CSV` 環境変数なしでエラーになること）: `spec/tasks/import_task_spec.rb`

### Implementation

- [ ] T046 [P] `CsvImporter` クラスを実装する（`CSV.foreach(path, encoding: 'Shift_JIS:UTF-8')` でストリーミング読み込み・1,000件ごとに `upsert_all` ・不正行は警告ログでスキップ）: `lib/jp_address_complement/importers/csv_importer.rb`
- [ ] T047 `jp_address_complement:import` Rake タスクを実装する（`ENV['CSV']` で CSV パスを受け取り・パス未指定でエラーメッセージ出力・`CsvImporter` 呼び出し・進捗ログ対応）: `lib/tasks/jp_address_complement.rake`
- [ ] T048 テスト用 Shift_JIS サンプル CSV ファイルを作成する（10件程度）: `spec/fixtures/ken_all_sample.csv`
- [ ] T049 T044〜T048 がすべて GREEN になることを確認し、`bundle exec rubocop` をパスさせる

**Checkpoint**: フルインポートが冪等に動作 / SimpleCov >= 90% / Rubocop PASS

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 複数ストーリーに横断的な品質向上

- [ ] T050 [P] `README.md` を作成する（インストール・セットアップ・基本 API 使用例・Rake タスク・Rails バリデーター例）: `README.md`
- [ ] T051 [P] `CHANGELOG.md` を作成する（0.1.0 の変更内容）: `CHANGELOG.md`
- [ ] T052 [P] エッジケースの追加テストを実装する（全角数字・「〒」付きハイフンあり・同一郵便番号複数レコード）: `spec/searcher_spec.rb`, `spec/normalizer_spec.rb`
- [ ] T053 `bundle exec rspec` でカバレッジレポートを確認し、SimpleCov 90% 未達のファイルを特定して対処する
- [ ] T054 `bundle exec rubocop -a` を実行して最終 100% PASS を確認する（auto-correct で修正できない違反は `.rubocop.yml` で justify する）
- [ ] T055 [P] `jp_address_complement.gemspec` の `summary`, `description`, `homepage`, `authors`, `license` を最終化する: `jp_address_complement.gemspec`
- [ ] T056 quickstart.md の手順に沿って新しい Rails アプリで実際にセットアップし、動作確認する（smoke test）
- [ ] T057 [P] パフォーマンスベンチマークを実装・計測する（郵便番号完全一致 < 10ms p99・先頭4桁前方一致 < 50ms を RSpec のタイミング計測で検証。SC-001・SC-003 の合否を明示）: `spec/performance_spec.rb`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1（Setup）**: 依存なし → 即座に開始可能
- **Phase 2（Foundational）**: Phase 1 完了後 → **全ユーザーストーリーをブロック**
- **Phase 3（US1）**: Phase 2 完了後 → 開始可能 🎯 MVP
- **Phase 4（US2）**: Phase 2 完了後 → Phase 3 と並行可能
- **Phase 5（US3）**: Phase 3 完了後（`find_by_code` 依存）→ Phase 4 と並行可能
- **Phase 6（US4）**: Phase 3 完了後（`valid_combination?` 依存）
- **Phase 7（Rake）**: Phase 2 完了後 → 独立して並行実行可能
- **Phase 8（Polish）**: Phase 3〜7 完了後

### User Story Dependencies

| ストーリー | 依存 | 理由 |
|-----------|------|------|
| US1 (P1) | Phase 2 のみ | 最初に実装すべき MVP |
| US2 (P2) | Phase 2 のみ | `find_by_prefix` は US1 の `find_by_code` と独立 |
| US3 (P3) | US1 | `valid_combination?` が `find_by_code` を内部利用 |
| US4 (P4) | US3 | Validator が `valid_combination?` を委譲 |

### Parallel Opportunities

```bash
# Phase 1: 並列実行可能なセットアップタスク
T002 gemspec 設定 & T003 RSpec 初期化 & T004 Rubocop 設定（同時実行可）

# Phase 2: 並列実行可能な基盤タスク
T007 AddressRecord テスト & T009 Normalizer テスト & T012 Configuration & T014 PostalCode モデル（同時実行可）

# Phase 3 (US1): TDD でテストと実装を並列計画
T016 Repository spec & T017 AR spec & T018 Searcher spec（先に全部 RED にしてから実装）

# Phase 4 (US2): Phase 3 と並行可能
T024-T026 US2 spec（Phase 3 が実装中でも US2 のテストは先行して書ける）
```

---

## Parallel Example: User Story 1

```bash
# Step 1: 全テストを先に書いて RED を確認（並列実行可）
Task T016: "PostalCodeRepository インターフェーステスト"
Task T017: "ActiveRecordPostalCodeRepository#find_by_code テスト"
Task T018: "Searcher#search_by_postal_code テスト（FakeRepository 使用）"
Task T019: "JpAddressComplement.search_by_postal_code 統合テスト"

# Step 2: 実装（T016 → T020 → T021 → T022 の順で GREEN にする）
Task T020: "ActiveRecordPostalCodeRepository#find_by_code 実装"
Task T021: "Searcher#search_by_postal_code 実装"
Task T022: "JpAddressComplement.search_by_postal_code 実装"
```

---

## Implementation Strategy

### MVP First（User Story 1 のみ）

1. Phase 1: Setup 完了
2. Phase 2: Foundational 完了（⚠️ 全ストーリーのブロッカー）
3. Phase 3: User Story 1 完了
4. **STOP & VALIDATE**: `bundle exec rspec spec/ --tag us1` で独立テスト
5. quickstart.md の Step 3（Rake タスク）まで動作確認してデモ可能

### Incremental Delivery

1. Setup + Foundational → 基盤完成
2. US1（Phase 3）→ 独立テスト → **MVP リリース可能**
3. US2（Phase 4）→ 独立テスト → デプロイ・デモ
4. US3（Phase 5）→ 独立テスト → デプロイ・デモ
5. US4（Phase 6）→ 独立テスト → デプロイ・デモ
6. Rake タスク（Phase 7）→ データ投入ツール完成
7. Polish（Phase 8）→ ドキュメント・品質最終仕上げ

---

## Notes

- **TDD（NON-NEGOTIABLE）**: 各実装タスクの前にテストを書き、RED を確認してから GREEN にする
- **Rubocop（NON-NEGOTIABLE）**: `bundle exec rubocop` は各コミット前に PASS 必須。`disable` コメント禁止
- **Coverage**: SimpleCov を常時確認し、90% を下回ったらすぐに対処する
- **FakeRepository 活用**: コアロジック（Searcher 等）のテストは `FakePostalCodeRepository` を注入し DB 不要で高速化する
- **Repository パターン**: コア実装は `ActiveRecord` を直接 `require` せず、`PostalCodeRepository` 経由のみでアクセスする
- **コミット粒度**: 各タスク完了時または論理グループ完了時にコミットする
- `[P]` = 異なるファイル・無依存のため並列実行可能
