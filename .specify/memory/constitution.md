<!--
Sync Impact Report
==================
Version change: 1.0.1 → 1.0.2
Bump type: PATCH（gem名 typo 修正・原則 IV にインポート戦略を追記）
Modified principles:
  - I. Gem-First: gem名 typo修正 jp_address_Complement → jp_address_complement
  - IV. データ整合性と定期更新: 差分インポート戦略・DB負荷最適化方针を追記
Added sections: none
Removed sections: none
Templates updated:
  - .specify/templates/plan-template.md ✅ updated
  - .specify/templates/spec-template.md ✅ (変更なし)
  - .specify/templates/tasks-template.md ✅ (変更なし)
Deferred TODOs: none
-->

# JpAddressComplement Constitution

## Core Principles

### I. Gem-First (単一責務 gem 設計)

本プロジェクトは Rails アプリケーションに組み込む単一目的の gem として設計する。
gem は自己完結し、独立してテスト・ドキュメント化できなければならない。
機能追加の際は必ず「この gem の責務か」を問い、責務外の機能は含まない。

- gem 名は `jp_address_complement`、名前空間は `JpAddressComplement` に閉じ、外部名前空間を汚染しない。
- 外部依存は最小限とし、追加する場合は明確な理由を文書化する。
- Rails への結合は Railtie/Engine 経由のみとし、本体ロジックは Rails 非依存に保つ。

### II. TDD 必須 (NON-NEGOTIABLE)

テストを先に書き、失敗を確認してから実装する。Red-Green-Refactor サイクルを厳守する。

- 実装コードより先にテストを書く。テストが失敗することを確認してから実装を始める。
- テストカバレッジは **90% 以上** を維持する（SimpleCov で計測）。
- ユニットテスト・統合テストを両方用意する。
- テストは意図を明確に示す記述でなければならない（`describe` / `context` / `it` の適切な使用）。

### III. Rubocop 完全準拠 (NON-NEGOTIABLE)

すべてのコードは `rubocop` を 100% パスしなければならない。

- `# rubocop:disable` コメントの使用は **禁止**。
- Rubocop の設定変更（`.rubocop.yml`）で対処する場合は、その理由をコメントで明記する。
- CI/CD パイプラインで Rubocop チェックを必須ゲートとして設定する。
- PR マージ前に必ず Rubocop をパスすること。

### IV. データ整合性と定期更新

日本郵便が公開する郵便番号 CSV データを正確に取り込み・管理する。

- データソース URL（ZIP）: https://www.post.japanpost.jp/zipcode/dl/oogaki/zip/ken_all.zip
- データの取り込みは冪等（同一データを重複投入してもデータが重複しない）でなければならない。
- 定期更新の仕組み（Rake タスク等）を提供し、最新データへの追従を可能とする。
- 文字コード（Shift-JIS → UTF-8 変換）や改行コードの差異を適切に処理する。

#### インポート戦略（DB 負荷最適化）

**基本方针: 差分インポートを強く推奨するが、負荷・運用コストを考慮して最適な手段を選択する。**

1. **差分インポート（標準）**
   - CSV 全件を読み込み、既存データとの差分（追加・変更・削除）のみ DB へ反映する。
   - `INSERT ... ON CONFLICT DO UPDATE`（upsert）を活用し、変更がない行はスキップする。
   - 削除検出は：削除フラグ列（`deleted_at`）もしくは「現在の全郵便番号セットに含まれない行を削除」で対応する。
   - 大量 upsert はバッチ分割（例: 1,000件/バッチ）で実行し、ロック持続時間を最小化する。

2. **全更新（フォールバック）**
   - 初回セットアップ時、または差分検知機構が利用不可な場合に限り使用する。
   - 全更新時は「一時テーブルへ載せ替え、アトミックに本テーブルと入れ替える」方式を検討する（ダウンタイムなし）。

3. **差分検知の仕組み**
   - 日本郵便が提供する差分データが利用可能な場合はそちらを優先する。
   - 差分判定にはデータのチェックサム（MD5/SHA256）もしくはバージョン情報で変更の有無を判定する。
   - 差分がない場合は DB への書き込みを全スキップする。

### V. 機能要件の厳守

提供する機能は以下の3つに限定し、各機能は明確なインターフェースを持つ。

1. **郵便番号から住所取得**: 7桁の郵便番号（ハイフンあり・なし両対応）から住所を返す。
2. **前方一致住所候補取得**: 郵便番号の先頭 4桁以上の入力で、対象となる住所候補一覧を返す。
3. **郵便番号と住所の不一致検出**: 郵便番号と住所の組み合わせが正しいかを検証し、不一致の場合はその理由を返す。

- 各機能は引数バリデーションを行い、不正入力には明確な例外またはエラーオブジェクトを返す。
- 戻り値の型は一貫性を持たせる（nil ではなく空配列・Result オブジェクト等）。

### VI. シンプルさ優先

複雑さは価値によって正当化されなければならない。

- YAGNI（You Aren't Gonna Need It）原則を適用する。
- 抽象化は2つ以上のユースケースが存在してから導入する。
- 設計判断には必ず理由を文書化する。

## Technology Standards

- **言語**: Ruby 3.x（3.2 以上を推奨）
- **対応フレームワーク**: Rails 7.x 以上
- **テストフレームワーク**: RSpec
- **カバレッジ計測**: SimpleCov（目標 90% 以上）
- **Lint**: RuboCop（100% 必須、disable 禁止）
- **gem 管理**: Bundler
- **データ形式**: 日本郵便oogaki CSV（Shift-JIS エンコード）
- **プロジェクト種別**: Ruby gem（Rails Engine）

## Quality Gates

各 PR・マージ前に以下をすべて満たすこと：

- [ ] `bundle exec rspec` が全テスト PASS
- [ ] `bundle exec rubocop` が PASS（警告・エラーゼロ、disable コメントなし）
- [ ] `SimpleCov` のカバレッジレポートで 90% 以上を確認
- [ ] 新機能・変更にはテストが付随している（TDD サイクルを経ていること）
- [ ] 公開 API の変更には CHANGELOG を更新

## Governance

- この Constitution はプロジェクトのすべての開発慣行より優先される。
- 修正には以下が必要：変更内容の文書化・理由の明記・影響するテンプレート/タスクへの反映。
- 原則 II（TDD）・原則 III（Rubocop）は **絶対要件** であり、例外なく遵守する。
- すべての PR レビューでこの Constitution への準拠を確認する。
- 複雑さの追加は必ず正当化し、Complexity Tracking セクションに記録する。
- バージョニングポリシー：
  - MAJOR: 後方互換性のない原則削除・再定義
  - MINOR: 新原則追加・セクション追加
  - PATCH: 表現の明確化・誤字修正・非意味的な改訂

**Version**: 1.0.2 | **Ratified**: 2026-02-22 | **Last Amended**: 2026-02-22
