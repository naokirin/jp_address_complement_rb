# Tasks: 都道府県コード変換・住所逆引き（住所→郵便番号）

**Input**: Design documents from `/specs/004-prefecture-code-reverse-lookup/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Constitution に従い TDD を採用。各ユーザーストーリーでテストを先に書き、失敗を確認してから実装する。

**Organization**: ユーザーストーリーごとにタスクをグループ化し、各ストーリーを独立して実装・テストできるようにする。

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: 並列実行可能（別ファイル、未完了タスクへの依存なし）
- **[Story]**: ユーザーストーリー（US1, US2, US3）
- 説明には対象ファイルパスを含める

## Path Conventions

- ライブラリ: `lib/jp_address_complement/`, `spec/` をリポジトリルートに使用（plan.md に準拠）

---

## Phase 1: Setup（ベースライン確認）

**Purpose**: 既存 gem のテスト・Lint が通ることを確認し、004 実装の前提を満たす

- [ ] T001 [P] 既存の RSpec がすべてパスすることを確認する（`bundle exec rspec`）
- [ ] T002 [P] 既存の Rubocop がパスすることを確認する（`bundle exec rubocop`）
- [ ] T003 既存の SimpleCov カバレッジを確認し、90% 以上であることを記録する

**Checkpoint**: 現状の green ベースラインが取れていること

---

## Phase 2: Foundational（全ストーリー共通の前提）

**Purpose**: 本機能では新規 DB や共通インフラは追加しない。Phase 1 完了後、各ユーザーストーリーに進める。

**Checkpoint**: Phase 1 完了後、User Story 1 から順に実装開始可能

---

## Phase 3: User Story 1 - 都道府県コードから都道府県名を取得する (Priority: P1) 🎯 MVP

**Goal**: 都道府県コード（2桁・数値または文字列）を渡すと都道府県名を返す。該当なし・不正入力時は nil。

**Independent Test**: `JpAddressComplement.prefecture_name_from_code("13")` が `"東京都"` を返すことを確認する。

### Tests for User Story 1（TDD: 先にテストを書き、失敗を確認する）

- [ ] T004 [P] [US1] `prefecture_name_from_code` のスペックを追加する（有効コード・ゼロパッド・存在しないコード・nil・空文字。47都道府県すべてのコード⇔名称が正しく動作することを 1 件以上の代表例で検証し、必要に応じて全件ループで検証する） in `spec/jp_address_complement/prefecture_spec.rb`

### Implementation for User Story 1

- [ ] T005 [US1] JIS X 0401 の 47 都道府県マッピング定数と `name_from_code` を実装する in `lib/jp_address_complement/prefecture.rb`
- [ ] T006 [US1] モジュールメソッド `JpAddressComplement.prefecture_name_from_code` を追加する in `lib/jp_address_complement.rb`

**Checkpoint**: User Story 1 が単体で動作し、`prefecture_name_from_code("13")` で "東京都" が返る

---

## Phase 4: User Story 2 - 都道府県名から都道府県コードを取得する (Priority: P2)

**Goal**: 都道府県の正式名称を渡すと 2 桁のコード文字列を返す。該当なし・省略表記・不正入力時は nil。

**Independent Test**: `JpAddressComplement.prefecture_code_from_name("東京都")` が `"13"` を返すことを確認する。

### Tests for User Story 2（TDD: 先にテストを書き、失敗を確認する）

- [ ] T007 [P] [US2] `prefecture_code_from_name` のスペックを追加する（正式名称・省略表記で nil・存在しない・nil・空文字。47都道府県すべて名称→コードが正しく動作することを代表例または全件で検証する） in `spec/jp_address_complement/prefecture_spec.rb`

### Implementation for User Story 2

- [ ] T008 [US2] `code_from_name` と名称→コード用マッピングを追加する in `lib/jp_address_complement/prefecture.rb`
- [ ] T009 [US2] モジュールメソッド `JpAddressComplement.prefecture_code_from_name` を追加する in `lib/jp_address_complement.rb`

**Checkpoint**: User Story 2 が単体で動作し、`prefecture_code_from_name("東京都")` で "13" が返る

---

## Phase 5: User Story 3 - 住所（分離フィールド）から郵便番号候補を取得する（逆引き） (Priority: P3)

**Goal**: pref・city・town（任意）を分離引数で渡すと、完全一致で検索し郵便番号の配列を返す。入力不十分・該当なし時は []。

**Independent Test**: `JpAddressComplement.search_postal_codes_by_address(pref: "東京都", city: "千代田区", town: "千代田")` で対応する郵便番号が含まれることを確認する。

### Tests for User Story 3（TDD: 先にテストを書き、失敗を確認する）

- [ ] T010 [P] [US3] `find_postal_codes_by_address` のスペックを追加する（pref+city+town / pref+city のみ / 入力不十分で [] / 該当なしで []） in `spec/repositories/active_record_postal_code_repository_spec.rb`
- [ ] T011 [P] [US3] `search_postal_codes_by_address` のスペックを追加する（FakeRepository に `find_postal_codes_by_address` をスタブまたは実装して使用。正常・空・nil/空文字で [] のケースを含める） in `spec/searcher_spec.rb`

### Implementation for User Story 3

- [ ] T012 [US3] `find_postal_codes_by_address(pref:, city:, town: nil)` をインターフェースに追加する in `lib/jp_address_complement/repositories/postal_code_repository.rb`
- [ ] T013 [US3] `find_postal_codes_by_address` を完全一致クエリで実装する（重複除く） in `lib/jp_address_complement/repositories/active_record_postal_code_repository.rb`
- [ ] T014 [US3] `search_postal_codes_by_address(pref:, city:, town: nil)` を追加し Repository を呼ぶ in `lib/jp_address_complement/searcher.rb`
- [ ] T015 [US3] モジュールメソッド `JpAddressComplement.search_postal_codes_by_address` を追加する in `lib/jp_address_complement.rb`

**Checkpoint**: User Story 3 が単体で動作し、逆引きで郵便番号配列が返る

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 複数ストーリーにまたがる仕上げ

- [ ] T016 [P] 新規 API 3 件（prefecture_name_from_code, prefecture_code_from_name, search_postal_codes_by_address）を CHANGELOG に追記する
- [ ] T017 全ファイルで `bundle exec rubocop` を実行し、警告・エラーを解消する
- [ ] T018 全テストを実行し、SimpleCov でカバレッジ 90% 以上を満たすことを確認する（`bundle exec rspec`）
- [ ] T019 [P] quickstart.md の手順で 3 API の動作を手動確認する（任意）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: 依存なし。即時開始可能。
- **Phase 2 (Foundational)**: 本機能ではタスクなし。Phase 1 完了後に Phase 3 へ。
- **Phase 3 (US1)**: Phase 1 完了後開始。他ストーリーに非依存。
- **Phase 4 (US2)**: Phase 3 完了後推奨（同一 Prefecture モジュールを拡張）。独立テスト可能。
- **Phase 5 (US3)**: Phase 1 完了後開始可能（Repository/Searcher は既存）。Phase 3/4 と並行も可。
- **Phase 6 (Polish)**: 実装したいストーリーがすべて完了してから実施。

### User Story Dependencies

- **US1 (P1)**: Phase 1 完了後から開始可能。他ストーリーに非依存。
- **US2 (P2)**: Prefecture モジュールを拡張するため、US1 完了後の方が自然。独立テスト可能。
- **US3 (P3)**: 既存 Repository/Searcher の拡張のため、Phase 1 完了後から開始可能。US1/US2 と並行可能。

### Within Each User Story

- テストを先に追加し、失敗することを確認してから実装する（TDD）。
- 実装は contracts/data-model に従う。

### Parallel Opportunities

- T001 と T002 は並列可能。
- Phase 3 の T004 と、Phase 4 の T007、Phase 5 の T010・T011 はそれぞれ別ファイルのため、ストーリー単位で並列化可能。
- Phase 6 の T016 と T019 は他と並列可能。

---

## Parallel Example: User Story 1

```bash
# Phase 3: まずテストを追加して RED を確認
Task T004: spec/jp_address_complement/prefecture_spec.rb に prefecture_name_from_code のスペックを追加

# 続けて実装で GREEN
Task T005: lib/jp_address_complement/prefecture.rb に定数と name_from_code を実装
Task T006: lib/jp_address_complement.rb に prefecture_name_from_code を追加
```

---

## Implementation Strategy

### MVP First（User Story 1 のみ）

1. Phase 1 を完了する。
2. Phase 3（US1）のテストを追加し、失敗を確認する。
3. Phase 3（US1）の実装を完了する。
4. **STOP and VALIDATE**: `prefecture_name_from_code("13")` が "東京都" を返すことを確認する。
5. 必要ならデモ・コミットする。

### Incremental Delivery

1. Phase 1 → ベースライン確認。
2. Phase 3（US1）→ コード→名称を検証してリリース候補。
3. Phase 4（US2）→ 名称→コードを追加して検証。
4. Phase 5（US3）→ 逆引きを追加して検証。
5. Phase 6 → CHANGELOG・Rubocop・カバレッジで仕上げ。

### Parallel Team Strategy

- Phase 1 を共有で完了したあと、
  - 担当 A: Phase 3（US1）→ Phase 4（US2）（Prefecture を順に拡張）
  - 担当 B: Phase 5（US3）（Repository + Searcher + モジュールメソッド）
- 各ストーリーは独立してテスト可能。

---

## Notes

- [P] タスクは別ファイルで依存がなければ並列実行可能。
- [USn] は spec.md のユーザーストーリーとの対応を示す。
- 各ストーリーは単体で完了・テストできるようにする。
- 実装前にテストの失敗を確認する（TDD）。
- タスクまたは論理的なまとまりごとにコミットする。
- チェックポイントでストーリー単位の動作確認を行う。
