# Tasks: CSVインポート時の消えたレコード削除

**Input**: Design documents from `/specs/003-csv-remove-obsolete/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Constitution で TDD 必須のため、各 User Story でテストを先に記載。Red-Green-Refactor で実装する。

**Organization**: User Story ごとに Phase を分け、US1 を MVP として独立検証可能にする。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並行実行可能（別ファイル・未完了タスクへの依存なし）
- **[US1/US2]**: 対応する User Story
- 各タスクの説明に **ファイルパス** を明記する

## Path Conventions

- 本リポジトリ: `lib/jp_address_complement/`, `spec/` をリポジトリルート基準で使用
- Rake: `lib/tasks/jp_address_complement.rake`

---

## Phase 1: Setup（ベースライン確認）

**Purpose**: 003 着手前の既存テスト・Lint が通る状態を確認する

- [x] T001 既存の CsvImporter と Rake タスクのテストがパスすることを確認する（spec/importers/csv_importer_spec.rb, spec/tasks/import_task_spec.rb）
- [x] T002 ベースラインとして bundle exec rubocop がパスすることを確認する

**Checkpoint**: 既存インポート仕様が GREEN の状態

---

## Phase 2: Foundational（全 User Story の前提）

**Purpose**: インポート戻り値の型を定義し、US1/US2 の実装で共通利用する

**⚠️ CRITICAL**: この Phase 完了まで User Story 実装に着手しない

- [x] T003 [P] CsvImporter の import 戻り値用の型（例: Data.define(:upserted, :deleted) または Hash）を lib/jp_address_complement/importers/csv_importer.rb に定義する

**Checkpoint**: 戻り値型が定義済み。US1 実装で import の戻り値をこの型に差し替え可能

---

## Phase 3: User Story 1 - フルインポートで新CSVにない住所レコードを削除する (Priority: P1) 🎯 MVP

**Goal**: 今回のCSVに含まれない住所レコードをストアから削除し、CSV とストアの内容を一致させる。

**Independent Test**: 既存データがある状態で、一部レコードを除いたCSVでインポートを実行し、除いたレコードがストアから消えていることを確認する。

### Tests for User Story 1（先に書き、RED を確認してから実装）

- [x] T004 [P] [US1] 新CSVに含まれないレコードが削除されることを spec/importers/csv_importer_spec.rb で検証する（Given 3件存在, When B を除くCSVでインポート, Then A,C のみ残る）
- [x] T005 [P] [US1] 空CSV（有効行0件）で ImportError が発生し既存データが変更されないことを spec/importers/csv_importer_spec.rb で検証する
- [x] T006 [P] [US1] 同じCSVで再インポートしても冪等であることを spec/importers/csv_importer_spec.rb で検証する
- [x] T007 [P] [US1] upsert 途中で失敗した場合は削除フェーズを実行せず既存データが維持されることを spec/importers/csv_importer_spec.rb で検証する（モックまたはスタブで失敗を再現）

### Implementation for User Story 1

- [x] T008 [US1] CSV 走査中に出現した一意キー (postal_code, pref_code, city, town) を Set で保持する処理を lib/jp_address_complement/importers/csv_importer.rb に追加する
- [x] T009 [US1] 有効行が1件もない場合に空CSVと判定し JpAddressComplement::ImportError を発生させる処理を lib/jp_address_complement/importers/csv_importer.rb に追加する
- [x] T010 [US1] upsert が全て成功した後に、キー集合に含まれない行を jp_address_complement_postal_codes から削除する処理を lib/jp_address_complement/importers/csv_importer.rb に追加する
- [x] T011 [US1] import の戻り値を Phase 2 で定義した型（upserted 件数・deleted 件数）に変更する処理を lib/jp_address_complement/importers/csv_importer.rb に実装する

**Checkpoint**: User Story 1 が単体で動作し、削除・空CSV拒否・冪等・失敗時不削除がテストで確認できる状態

---

## Phase 4: User Story 2 - 削除と追加・更新が同一インポートで正しく反映される (Priority: P2)

**Goal**: 追加・更新・削除が一括で正しく反映され、インポート完了時に件数が報告される。

**Independent Test**: 既存データに対し、一部削除・一部追加・一部変更したCSVでインポートし、最終状態がCSVと一致し、件数が表示されることを確認する。

### Tests for User Story 2

- [x] T012 [P] [US2] 同一インポートで削除・追加・更新が正しく反映される統合テストを spec/importers/csv_importer_spec.rb に追加する（例: A 削除・C 追加 → B,C のみ残る）
- [x] T013 [P] [US2] Rake タスク実行時に標準出力に upserted/deleted 件数が含まれることを spec/tasks/import_task_spec.rb で検証する

### Implementation for User Story 2

- [x] T014 [US2] jp_address_complement:import タスクで CsvImporter#import の戻り値を受け取り、標準出力に「インポート完了: upsert N 件, 削除 M 件」を表示する処理を lib/tasks/jp_address_complement.rake に追加する

**Checkpoint**: User Story 1 と 2 がともに動作し、Rake から件数が確認できる状態

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: 品質ゲートとドキュメントの最終確認

- [x] T015 [P] 全テストが GREEN であることと bundle exec rubocop がパスすることを確認する
- [x] T016 [P] SimpleCov でカバレッジ 90% 以上を確認する
- [x] T017 公開 API 変更（CsvImporter#import の戻り値が Integer → 件数オブジェクト）に合わせて CHANGELOG を更新する（Constitution Quality Gates 準拠）
- [x] T018 quickstart.md の手順（インポートで消えたレコード削除・空CSV拒否・件数表示）を手動で確認し、必要なら docs を更新する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: 依存なし。即時開始可能。
- **Phase 2 (Foundational)**: Phase 1 完了後に開始。全 User Story の前提となる。
- **Phase 3 (US1)**: Phase 2 完了後に開始。MVP。
- **Phase 4 (US2)**: Phase 3 完了後に開始。US1 の拡張（件数報告・Rake 出力）。
- **Phase 5 (Polish)**: Phase 4 完了後に実施。T017（CHANGELOG）は Constitution Quality Gates 必須。

### User Story Dependencies

- **User Story 1 (P1)**: Phase 2 完了後から開始可能。他ストーリーに依存しない。
- **User Story 2 (P2)**: Phase 3 完了後から開始可能。US1 の import 戻り値を Rake が表示するだけなので、US1 実装に依存。

### Within Each User Story

- テストを先に書き、失敗を確認してから実装（TDD）。
- T004〜T007 が RED の状態で T008〜T011 を実装して GREEN にする。
- T012〜T013 が RED の状態で T014 を実装して GREEN にする。

### Parallel Opportunities

- Phase 1: T001 と T002 は順不同（T002 は Lint のみ）。
- Phase 2: T003 のみ。
- Phase 3: T004, T005, T006, T007 は [P] のため並行してテストを記述可能。T008〜T011 は順序あり（キー保持→空CSV→削除→戻り値）。
- Phase 4: T012 と T013 は [P] で並行してテスト記述可能。
- Phase 5: T015 と T016 は [P] で並行可能。T017（CHANGELOG）と T018（quickstart 確認）は順不同で実施。

---

## Parallel Example: User Story 1

```text
# テストを並行して追加（いずれも spec/importers/csv_importer_spec.rb）:
T004: 新CSVにないレコード削除の example
T005: 空CSVで ImportError の example
T006: 冪等の example
T007: upsert 失敗時は削除しない example
```

---

## Implementation Strategy

### MVP First（User Story 1 のみ）

1. Phase 1 完了 → ベースライン確認
2. Phase 2 完了 → 戻り値型定義
3. Phase 3 完了 → 削除・空CSV拒否・冪等・戻り値
4. **STOP and VALIDATE**: CsvImporter のテストのみで US1 を検証
5. 必要ならデモまたはコミット

### Incremental Delivery

1. Phase 1 + 2 → 基盤のみ
2. Phase 3 (US1) → 削除機能が単体で動作（MVP）
3. Phase 4 (US2) → 件数報告と Rake 出力
4. Phase 5 → 品質ゲートと quickstart 確認

### Notes

- [P] タスクは別ファイル・依存なしで並行可能。
- [US1]/[US2] でストーリーとタスクを対応付ける。
- 各 User Story は独立して完了・検証可能。
- テストは必ず先に書き、失敗を確認してから実装する。
- チェックポイントでストーリー単位の検証を行う。
- **SC-003（許容可能な範囲）**: パフォーマンスは plan 上の目安（既存インポート時間の約2倍以内）とする。本 tasks では専用の計測・検証タスクは設けず、必要に応じて手動またはベンチで確認する。
