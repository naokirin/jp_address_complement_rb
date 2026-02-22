# Feature Specification: RBS 型注釈の導入

**Feature Branch**: `002-rbs-type-annotations`  
**Created**: 2026-02-22  
**Status**: Draft  
**Input**: User description: "RBSを導入し、gemの実装全体に型を記述します。rbs-inlineを活用してコメントから自動生成するようにし、Steepで型チェックをするようにします。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gem 利用者が型情報を参照して安全に呼び出せる (Priority: P1)

Gem を利用する Rails アプリ開発者（またはエディタ・LSP）が、`JpAddressComplement` モジュールおよびその公開メソッドの引数・返り値の型をシグネチャファイルから確認できる。
これにより IDE の補完・型エラー検出が機能し、誤った型の引数を渡すミスを事前に検知できる。

**Why this priority**: 型情報はまず「使う側」に価値をもたらす。公開 API のシグネチャが正確に記述されていることがすべての型安全性の起点となる。

**Independent Test**: Gem の `sig/` ディレクトリに生成された `.rbs` ファイルを Steep でチェックし、エラーゼロが確認できることで独立してテスト可能。

**Acceptance Scenarios**:

1. **Given** gem をインストールした開発者が Steep を設定した時、**When** `steep check` を実行すると、**Then** gem 公開 API（`search_by_postal_code`・`search_by_postal_code_prefix`・`valid_combination?`・`configure`・`configuration`）に関するシグネチャエラーがゼロで終了する。
2. **Given** gem の `sig/` ディレクトリが存在する時、**When** 利用者が参照すると、**Then** `AddressRecord` の全フィールド（`postal_code`・`pref_code`・`pref`・`city`・`town` 等）の型が明示されている。
3. **Given** 誤った型の引数（例：`Integer` の郵便番号）を渡すコードを書いた時、**When** Steep でチェックすると、**Then** 型エラーが報告される。

---

### User Story 2 - Gem 開発者が rbs-inline コメントで型を維持できる (Priority: P1)

Gem の開発者（コントリビューター）が、ソースコード（`.rb` ファイル）内に `rbs-inline` 記法のアノテーションコメントを追記することで型を宣言し、`rbs-inline` コマンドで `.rbs` ファイルを自動生成できる。
実装コードと型シグネチャを1つのファイルで同期管理できるため、実装変更時に型の更新漏れが起きにくい。

**Why this priority**: 型ファイルの生成・維持コストが最小化されないと開発サイクルで型管理が形骸化する。P1 の型シグネチャ提供を持続的に維持するための基盤として同等の優先度とする。

**Independent Test**: `lib/` 配下すべての `.rb` ファイルに `rbs-inline` アノテーションを追加した後、`rbs-inline --output sig/ lib/` を実行し、`sig/` に正しい `.rbs` ファイルが生成されることを確認することで独立してテスト可能。

**Acceptance Scenarios**:

1. **Given** `lib/` 配下のすべての `.rb` ファイルに `rbs-inline` 記法のアノテーションが付与されている時、**When** `rbs-inline --output sig/ lib/` を実行すると、**Then** `sig/` 配下に対応する `.rbs` ファイルが生成（または更新）される。
2. **Given** 既存の実装メソッドにアノテーションが付与されている時、**When** メソッドのシグネチャを変更してもアノテーションを更新しないまま `steep check` を実行すると、**Then** 型の不整合がエラーとして検出される。
3. **Given** アノテーションなしのメソッドが残存する時、**When** `steep check` を実行すると、**Then** 未注釈メソッドに関する警告が出力され、開発者が気づける。

---

### User Story 3 - CI で型チェックが自動実行される (Priority: P2)

Gem のコントリビューターがコードを変更してプルリクエストを作成した時、型チェック（`steep check`）が自動的に実行され、型エラーを含む変更がマージされることを防止できる。

**Why this priority**: 型チェックが CI に組み込まれていないと、型安全性の維持が属人化しやすい。P1・P2 の成果を継続的に保護するために重要だが、ローカル実行が先に確立されることが前提となるため P2 とする。

**Independent Test**: Rakefile または CI 設定ファイルに `steep check` タスクが追加されており、実行して正常に型チェックが完了することを確認することで独立してテスト可能。

**Acceptance Scenarios**:

1. **Given** `steep check` が Rake タスクとして登録されている時、**When** `bundle exec rake steep` を実行すると、**Then** Steep による型チェックが実行され、エラーゼロで完了する。
2. **Given** 型エラーを含む変更がある時、**When** `bundle exec rake steep` を実行すると、**Then** 型エラーが出力され、終了コードが非ゼロとなる。

---

### Edge Cases

- `AddressRecord` は `Data.define` で定義されており `rbs-inline` による自動生成が完全に機能しない場合、`sig/manual/address_record.rbs` に全フィールドの型（`String`・`bool` 等）を手書きする。
- Steep の型チェックが ActiveRecord や Rails 内部の型まで追跡しようとして誤検知（false positive）が発生する場合は、`Steep::Interface::Builder` のスタブや `# steep:ignore` による局所的な抑制で対処する。
- `rbs-inline` が生成するシグネチャと、Gem のパブリック API として公開したいシグネチャが乖離する場合（例：内部型の露出）は、`sig/` 内でシグネチャを手動補正する運用を明確にする。
- Ruby バージョンが `3.2` 以上でのみ動作する `Data.define` の型表現について、Steep 未対応の場合はモンキーパッチ的なアプローチ（型定義のオーバーライド）が必要になることがある。その場合は**発生時のみ**対応し、通常は `sig/manual/address_record.rbs` の手書き定義で足りる想定とする。

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 本機能は、gem の `lib/` 配下のすべての `.rb` ファイルに `rbs-inline` 記法の型アノテーションコメントを付与し、型情報を明示しなければならない。対象ファイルは、公開 API・内部実装・バリデーター・ジェネレーター・リポジトリ・インポーターを含む。アノテーション付与の対象は `public`・`private`・`protected` を問わずすべてのメソッドとする。
- **FR-002**: `rbs-inline` gem を開発依存として gemspec に追加し、`rbs-inline --output sig/ lib/` コマンドで `sig/` 配下に `.rbs` ファイルを自動生成できなければならない。
- **FR-003**: `steep`・`rbs-rails`・`gem_rbs_collection` を開発依存として gemspec に追加し、`Steepfile` の設定により `lib/` と `sig/` を対象として `default` レベルで型チェックを実行できなければならない。`default` は標準的な整合性検査を行い、外部ライブラリの型定義が不完全でも過剰な false positive を発生させない。Rails/ActiveRecord の型定義は `rbs-rails` および `gem_rbs_collection` から取得し、不足分がある場合のみ Steep の対象外設定で補完する。
- **FR-004**: `steep check` が型エラーゼロで完了しなければならない。許容できない型の誤検知がある場合のみ `# steep:ignore` コメントで局所的に抑制し、その理由をコメントで明記しなければならない。
- **FR-005**: `rbs-inline` による `.rbs` 生成コマンドを Rake タスク（例: `rake rbs:generate`）として登録し、開発者が容易に再生成できなければならない。
- **FR-006**: `steep check` を Rake タスク（例: `rake steep`）として登録し、`bundle exec rake steep` で型チェックを実行できなければならない。
- **FR-007**: `AddressRecord`（`Data.define` 使用）・`Configuration`・`Normalizer`・`Searcher`・`Repositories::PostalCodeRepository`（インターフェース）・`Repositories::ActiveRecordPostalCodeRepository`・バリデーター・インポーター・ジェネレーターのすべてに型シグネチャが定義されなければならない。`AddressRecord` については `sig/manual/address_record.rbs` に全フィールド（`postal_code`・`pref_code`・`pref`・`city`・`town`・`kana_pref`・`kana_city`・`kana_town`・`has_alias`・`is_partial`・`is_large_office`）の型を手書きで定義する。
- **FR-008**: 公開メソッド（`JpAddressComplement.search_by_postal_code`・`search_by_postal_code_prefix`・`valid_combination?`・`configure`・`configuration`）の引数型と返り値型が `.rbs` ファイルに正確に記述されなければならない。
- **FR-009**: `Repositories::PostalCodeRepository` はインターフェース（抽象型）として定義し、`find_by_code(code: String): Array[AddressRecord]` および `find_by_prefix(prefix: String): Array[AddressRecord]` のシグネチャを持たなければならない（現行実装のメソッド名に合わせる）。
- **FR-010**: 既存の RuboCop ルールに準拠した状態（`bundle exec rubocop` エラーゼロ）を維持しなければならない。`rbs-inline` アノテーションコメントが既存ルールと競合する場合は、`.rubocop.yml` を最小限の変更で調整する。
- **FR-011**: 既存のすべての RSpec テスト（`bundle exec rspec`）が引き続き全件パスし、SimpleCov カバレッジが 90% 以上を維持しなければならない。型アノテーションの追加はテストの振る舞いを変更してはならない。

### Key Entities

- **型アノテーションコメント (rbs-inline annotation)**: `lib/` 配下の `.rb` ファイルに記述する `# @rbs` 記法のコメント。メソッドの引数型・返り値型・インスタンス変数の型などを宣言するために使用する。ソースコードと同一ファイルで管理することで実装との同期を容易にする。
- **RBS シグネチャファイル (`.rbs`)**: `sig/` ディレクトリ直下に配置される型定義ファイル。`rbs-inline` コマンドにより `.rb` ファイルのアノテーションから自動生成される。Steep がこのファイルを参照して型チェックを実施する。手動で追補が必要な型定義（`Data.define` フォールバック等）は `sig/manual/` サブディレクトリに分離して管理する。
- **Steepfile**: `steep check` の対象ディレクトリ・型定義の参照先・チェックレベル等を設定するファイル。プロジェクトルートに配置し、gem の型チェック範囲を制御する。チェックレベルは `default`（標準 strictness）を使用する。
- **型エラー抑制コメント (`# steep:ignore`)**: Steep が false positive を報告する箇所に限定して使用するインラインコメント。理由の明記を必須とし、乱用を避けるためコードレビューで管理する。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `bundle exec rake rbs:generate` を実行すると、`sig/` 配下のすべての `.rbs` ファイルが最新の実装に基づいて生成・更新される。実行時にエラーが発生しない。
- **SC-002**: `bundle exec rake steep` を実行すると、型チェックがエラーゼロで完了する。
- **SC-003**: `sig/` 配下に生成される `.rbs` ファイルにおいて、gem が公開するすべての public メソッドに引数型と返り値型のシグネチャが定義されている。シグネチャが定義されていない public メソッドがゼロ件であること。
- **SC-004**: 型アノテーション追加後も `bundle exec rspec` が全件パスし、SimpleCov カバレッジが 90% 以上を維持する。
- **SC-005**: 型アノテーション追加後も `bundle exec rubocop` がエラーゼロ・`rubocop:disable` コメントなしで完了する。

### Constitution Compliance Criteria

> これらの基準は Constitution に基づく必須成功条件です。

- **CC-001**: `bundle exec rspec` が全テスト PASS し、SimpleCov カバレッジが **90% 以上**である。
- **CC-002**: `bundle exec rubocop` が PASS（警告・エラーゼロ、`rubocop:disable` コメントなし）。
- **CC-003**: すべての実装コードは先にテストを書き、Red-Green-Refactor サイクルを経ている（TDD）。ただし本機能はアノテーションの追加が主体であり、型チェックの設定・Rake タスクの実装については TDD サイクルを適用する。Rake タスク（rbs:generate・steep）の動作検証は、`bundle exec rake rbs:generate` および `bundle exec rake steep` の手動実行で代替可能とする。
- **CC-004**: gem は `JpAddressComplement` 名前空間に閉じており、コア検索ロジックは Repository インターフェースを介してデータアクセスし、ActiveRecord への直接依存を持たない。型導入によりこの設計が損なわれてはならない。

## Assumptions

- 対象 Ruby バージョンは `>= 3.2.0`（gemspec で既に指定済み）。`Data.define` を使用している `AddressRecord` については、`rbs-inline` による自動生成が完全機能しない場合に備えて `sig/manual/address_record.rbs` に全フィールドの型を手書きで定義する。
- `rbs-inline` の記法は gem リリース時点の安定バージョン（1.x 系、`~> 1.0`）を使用する。バージョンは gemspec の development_dependency で束縛する（実際の最新安定版に合わせて調整）。
- `steep` gem についても同様に development_dependency として追加し、特定のマイナーバージョン範囲に固定する。
- Rails 内部・ActiveRecord の型定義は `rbs-rails` および `gem_rbs_collection` を開発依存として追加することで取得する。これらで解決できない型定義が残る場合のみ Steep の対象外設定（`library` 除外や `ignore` ディレクティブ）を最小限に適用する。
- `rbs-inline` で自動生成したシグネチャは `sig/` 直下に出力する。手動で追加・修正が必要な型定義（`Data.define` のフォールバック型定義等）は `sig/manual/` サブディレクトリに分離して管理する。`sig/manual/` 配下のファイルは `rbs-inline` コマンドで上書きされない。
- 既存の `sig/jp_address_complement.rbs` はコメントのみを残した最小ファイルになっているため、本機能で完全に置き換える。

## Clarifications

### Session 2026-02-22

- Q: Steep の型チェック strictness レベルはどれを使用するか？ → A: `default`（標準 strictness）。外部 gem の型定義が不完全な環境でも false positive を抑えつつ gem 自体のコードを型チェックできるため。
- Q: Rails/ActiveRecord の型定義はどのように取得するか？ → A: `rbs-rails` + `gem_rbs_collection` を開発依存として追加し公式・準公式の型定義を最大限活用する。不足分のみ Steep の対象外設定で補完する。
- Q: `sig/` 配下のファイル管理構成（自動生成 vs 手動）はどうするか？ → A: `sig/` 直下に自動生成ファイルを配置し、手動補完（`Data.define` フォールバック等）は `sig/manual/` に分離する。`sig/manual/` は `rbs-inline` 生成で上書きされない。
- Q: `rbs-inline` アノテーションを付与するメソッドのアクセス修飾子範囲は？ → A: `public`・`private`・`protected` を問わずすべてのメソッドに付与する。gem の規模が小さくメンテナンスコストが許容範囲内であり、内部実装の型バグも早期検出できるため。
- Q: `Data.define` で定義された `AddressRecord` の型表現方法は？ → A: `sig/manual/address_record.rbs` に全フィールドの型を手書きで定義する。`untyped` 扱いや `# steep:ignore` による一時振りはしない。
