# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Ruby 3.x（3.2 以上推奨）  
**Primary Dependencies**: Rails 7.x 以上、RSpec、SimpleCov、RuboCop  
**Storage**: SQLite（開発・テスト）/ 任意のActiveRecord対応DB（本番）  
**Testing**: RSpec（カバレッジ 90% 以上、SimpleCov 計測）  
**Target Platform**: Ruby gem（Rails Engine）  
**Project Type**: Ruby gem（Rails 組み込み型ライブラリ）  
**Performance Goals**: 郵便番号→住所検索 < 10ms p95  
**Constraints**: Rubocop 100% PASS（disable 禁止）、TDD 必須  
**Scale/Scope**: 全国郵便番号（約12万件）を管理

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] **I. Gem-First**: 実装は `JpAddresscomplement` 名前空間に閉じているか。Rails 非依存のコアロジックか。
- [ ] **II. TDD**: テストを先に書き、失敗を確認してから実装しているか。RSpec カバレッジ 90% 以上の計画があるか。
- [ ] **III. Rubocop**: `rubocop:disable` を使用していないか。CI で Rubocop が必須ゲートとして設定されているか。
- [ ] **IV. データ整合性**: 日本郵便 CSV の取り込みが冪等か。文字コード変換を適切に処理しているか。
- [ ] **V. 機能要件**: 3つの機能（住所取得・候補取得・不一致検出）のインターフェースが明確か。バリデーションがあるか。
- [ ] **VI. シンプルさ**: 複雑化は正当化されているか。YAGNI 原則に従っているか。

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
