# Tasks: RBS 型注釈の導入

**Input**: Design documents from `/specs/002-rbs-type-annotations/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: User story ごとにタスクをグループ化し、各ストーリーを独立して実装・検証できるようにする。

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: 並行実行可能（別ファイル・依存なし）
- **[Story]**: ユーザーストーリー（US1, US2, US3）
- 説明には対象ファイルパスを明記する

## Path Conventions

- リポジトリルート: `lib/`, `sig/`, `Steepfile`, `jp_address_complement.gemspec`
- 型定義: `sig/`, `sig/manual/`
- Rake: `lib/tasks/jp_address_complement.rake` または同等

---

## Phase 1: Setup（共有インフラ）

**Purpose**: RBS/Steep 用の開発依存と設定の追加

- [x] T001 Add development dependencies (rbs-inline, steep, rbs-rails, gem_rbs_collection) to jp_address_complement.gemspec per research.md
- [x] T002 Create Steepfile at project root with target :lib, signature "sig", check "lib" per research.md and plan.md
- [x] T003 Create sig/ and sig/manual/ directories (sig/manual/ for hand-written RBS not overwritten by rbs-inline)
- [x] T004 [P] Add rbs_collection.yaml or configure gem_rbs_collection at repo root when required（必要条件は research.md セクション 4「rbs_collection の設定」を参照）

---

## Phase 2: Foundational（全ストーリーの前提）

**Purpose**: Rake タスクと手動 RBS を整え、どのユーザーストーリーもここが完了するまで開始できない

**⚠️ CRITICAL**: この Phase が完了するまでユーザーストーリーの実装に着手しない

- [x] T005 Create sig/manual/address_record.rbs with all fields (postal_code, pref_code, pref, city, town, kana_pref, kana_city, kana_town, has_alias, is_partial, is_large_office) per contracts/rbs-public-api.md and data-model.md
- [x] T006 Add Rake task rbs:generate (bundle exec rbs-inline --output sig/ lib/) in lib/tasks/jp_address_complement.rake
- [x] T007 Add Rake task steep (bundle exec steep check) in lib/tasks/jp_address_complement.rake
- [x] T008 [P] Adjust .rubocop.yml if rbs-inline comments violate existing rules; document reason in comment (FR-010, no rubocop:disable)

**Checkpoint**: Foundation ready — T006・T007 完了後、`bundle exec rake rbs:generate` と `bundle exec rake steep` を一度手動実行し動作を確認する（CC-003: Rake タスクの検証は手動で代替）。以降、US1/US2/US3 の実装を開始可能。

---

## Phase 3: User Story 1 — Gem 利用者が型情報を参照して安全に呼び出せる (P1) 🎯 MVP

**Goal**: 公開 API のシグネチャが sig/ に存在し、steep check がエラーゼロで終了する。AddressRecord の型が明示され、誤った型の引数で Steep がエラーを報告する。

**Independent Test**: `bundle exec rake steep` がエラーゼロで終了する。sig/ に公開メソッドと AddressRecord の型が定義されている。誤った型（例: Integer）を渡すコードで Steep が型エラーを報告する。

### Implementation for User Story 1

- [x] T009 [US1] Add rbs-inline annotations to lib/jp_address_complement.rb (configure, configuration, repository, search_by_postal_code, search_by_postal_code_prefix, valid_combination?, default_repository) per contracts/rbs-public-api.md
- [x] T010 [US1] Add rbs-inline annotations to lib/jp_address_complement/configuration.rb
- [x] T011 [US1] Add rbs-inline annotations to lib/jp_address_complement/normalizer.rb
- [x] T012 [US1] Add rbs-inline annotations to lib/jp_address_complement/searcher.rb
- [x] T013 [US1] Add rbs-inline annotations to lib/jp_address_complement/repositories/postal_code_repository.rb (find_by_code, find_by_prefix)
- [x] T014 [US1] Add rbs-inline annotations to lib/jp_address_complement/repositories/active_record_postal_code_repository.rb
- [x] T015 [US1] Run bundle exec rake rbs:generate and fix Steep errors (add sig/manual reference if needed, use # steep:ignore with reason only for false positives) until bundle exec rake steep exits 0
- [x] T016 [US1] Verify bundle exec rake steep exits 0, bundle exec rspec passes, bundle exec rubocop passes, and SimpleCov remains ≥90%

**Checkpoint**: User Story 1 完了 — 利用者向けに型情報が参照可能で、steep check が通る状態

---

## Phase 4: User Story 2 — Gem 開発者が rbs-inline コメントで型を維持できる (P1)

**Goal**: lib/ 配下のすべての .rb に rbs-inline アノテーションを付与し、rbs-inline で sig/ を生成できる。シグネチャ変更でアノテーションを更新しないと steep がエラーを出す。未注釈メソッドがあれば Steep が警告する。

**Independent Test**: lib/ の全 .rb に rbs-inline が付与されている。bundle exec rake rbs:generate で sig/ が更新される。bundle exec rake steep がエラーゼロで完了する。

### Implementation for User Story 2

- [x] T017 [P] [US2] Add rbs-inline annotations to lib/jp_address_complement/address_record.rb (Data.define は manual を併用する想定で必要範囲のみでも可)
- [x] T018 [P] [US2] Add rbs-inline annotations to lib/jp_address_complement/version.rb and lib/jp_address_complement/railtie.rb
- [x] T019 [P] [US2] Add rbs-inline annotations to lib/jp_address_complement/models/postal_code.rb
- [x] T020 [P] [US2] Add rbs-inline annotations to lib/jp_address_complement/validators/address_validator.rb
- [x] T021 [P] [US2] Add rbs-inline annotations to lib/jp_address_complement/importers/csv_importer.rb
- [x] T022 [P] [US2] Add rbs-inline annotations to lib/generators/jp_address_complement/install_generator.rb
- [x] T023 [US2] Run bundle exec rake rbs:generate and ensure bundle exec rake steep exits 0; fix any new type errors
- [x] T024 [US2] Resolve any Steep warnings for unannotated methods so that FR-004 (型エラーゼロ) and SC-002 are met

**Checkpoint**: User Story 2 完了 — 開発者が rbs-inline で型を一括維持できる状態

---

## Phase 5: User Story 3 — CI で型チェックが自動実行される (P2)

**Goal**: PR 時に steep check が自動実行され、型エラーがあるとマージできないようにする。

**Independent Test**: CI 設定に steep check が含まれており、bundle exec rake steep が成功する。型エラーを意図的に入れた変更で CI が失敗する。

### Implementation for User Story 3

- [x] T025 [US3] Add steep check to CI (e.g. .github/workflows/*.yml or project CI config) so that bundle exec rake steep is run and non-zero exit fails the job
- [x] T026 [US3] Document rake steep and rake rbs:generate in README or docs so contributors can run type check locally (align with specs/002-rbs-type-annotations/quickstart.md)

**Checkpoint**: User Story 3 完了 — CI で型安全性が継続的に保護される

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 複数ストーリーにまたがる仕上げ

- [x] T027 [P] Validate developer workflow per specs/002-rbs-type-annotations/quickstart.md (rbs:generate → steep の流れが動作すること)
- [x] T028 Update CHANGELOG for RBS/type annotations support if this is a user-facing change

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: 依存なし — 即時開始可能
- **Phase 2 (Foundational)**: Phase 1 完了後に実施 — 全ユーザーストーリーをブロック
- **Phase 3 (US1)**: Phase 2 完了後に実施 — MVP
- **Phase 4 (US2)**: Phase 2 完了後に実施可能（US1 完了後が望ましい：公開 API が先に型付きになる）
- **Phase 5 (US3)**: Phase 3 または Phase 4 完了後（steep がローカルで通っていることが前提）
- **Phase 6 (Polish)**: 必要なストーリー完了後に実施

### User Story Dependencies

- **US1 (P1)**: Phase 2 完了後から開始。他ストーリーに依存しない。
- **US2 (P1)**: Phase 2 完了後から開始。US1 完了後に進めると sig/ の状態が安定する。
- **US3 (P2)**: Phase 3 または 4 の完了後。CI に steep を追加するだけなので、US1 完了後でも実施可能。

### Within Each User Story

- 公開 API（モジュールメソッド・Repository）の型を先に揃え、その後に内部実装の型を揃える。
- 各 Phase の最後で bundle exec rake steep / rspec / rubocop で検証する。

### Parallel Opportunities

- Phase 1: T004 [P] は他と並行可能
- Phase 2: T008 [P] は他と並行可能
- Phase 4: T017〜T022 は [P] のため、別々のファイルを並行してアノテーション追加可能
- Phase 6: T027 [P], T028 は並行可能

---

## Parallel Example: User Story 2

```text
# Phase 4 で複数ファイルに同時にアノテーションを追加する例
T017: lib/jp_address_complement/address_record.rb
T018: lib/jp_address_complement/version.rb, lib/jp_address_complement/railtie.rb
T019: lib/jp_address_complement/models/postal_code.rb
T020: lib/jp_address_complement/validators/address_validator.rb
T021: lib/jp_address_complement/importers/csv_importer.rb
T022: lib/generators/jp_address_complement/install_generator.rb
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup を完了
2. Phase 2: Foundational を完了（Rake タスク・sig/manual/address_record.rbs）
3. Phase 3: User Story 1 を完了（公開 API の型・steep エラーゼロ）
4. **STOP and VALIDATE**: bundle exec rake steep が 0、rspec 全件パス、rubocop パスを確認
5. 必要ならこの時点でマージ・リリース可能（型情報提供の最小単位）

### Incremental Delivery

1. Setup + Foundational → 基盤完了
2. US1 完了 → 利用者に型情報が提供され、steep が通る（MVP）
3. US2 完了 → 開発者が全ファイルで rbs-inline を維持可能
4. US3 完了 → CI で型チェックが必須に
5. Polish で quickstart 検証・CHANGELOG 更新

### Suggested MVP Scope

- **MVP**: Phase 1 + Phase 2 + Phase 3（User Story 1 まで）
- これで「Gem 利用者が型情報を参照して安全に呼び出せる」が満たされ、SC-001, SC-002, SC-003 の主要部分を達成できる。

---

## Notes

- 各タスクはチェックボックス・Task ID・必要時は [P]/[USn]・対象パスを明記している。
- テストタスクは spec で明示的に要求されていないため、独立検証は「bundle exec rake steep / rspec / rubocop」の実行で行う。
- コミットはタスク単位または論理的なまとまりで行うとよい。
- どのチェックポイントでも、その時点でストーリーを独立して検証可能。
