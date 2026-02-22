# Research: RBS 型注釈の導入 — Phase 0 調査結果

**Branch**: `002-rbs-type-annotations`  
**Date**: 2026-02-22  
**Status**: Complete

---

## 1. rbs-inline による型アノテーション

### Decision
`lib/` 配下の全 `.rb` ファイルに `rbs-inline` 記法（`# @rbs` コメント）でメソッドの引数・返り値型を記述し、`rbs-inline --output sig/ lib/` で `sig/` に `.rbs` を自動生成する。public / private / protected を問わずすべてのメソッドにアノテーションを付与する。

### Rationale
- 型定義をソースコードと同一ファイルで管理することで、実装変更時の型の更新漏れを防ぎ、FR-002 の「持続的な型維持」を満たす。
- rbs-inline は Ruby 3.x で広く使われる型注釈方式であり、Steep と組み合わせる標準的な選択。
- 全メソッド対象にすることで、内部実装の型バグも早期検出でき、gem 規模ではコストが許容範囲内（Clarifications 2026-02-22 で合意済み）。

### 記法例（rbs-inline）

```ruby
# メソッドの直前に # @rbs でシグネチャを記述
# @rbs def search_by_postal_code(code: String) -> Array[AddressRecord]
def search_by_postal_code(code)
  # ...
end
```

- 引数: `name: Type`。返り値: `-> Type` または `-> Array[AddressRecord]`。
- クラス・モジュールのインスタンス変数や定数の型も必要に応じて `# @rbs` で宣言可能。

### Alternatives Considered
- **手書き .rbs のみ**: 実装と型の二重管理になり、更新漏れが発生しやすい。却下。
- **型注釈なしで Steep の型推論のみ**: 現状の Steep では Ruby の型推論だけでは不十分で、公開 API の明示的シグネチャが必要。却下。

---

## 2. Steep の設定（Steepfile・チェックレベル）

### Decision
プロジェクトルートに `Steepfile` を配置し、対象を `lib/` と `sig/` に限定。チェックレベルは `default` とする。Rails/ActiveRecord の型定義は `rbs-rails` と `gem_rbs_collection` から取得する。

### Rationale
- **default**: 標準的な整合性検査を行い、外部ライブラリの型定義が不完全でも過剰な false positive を避けられる（Clarifications 2026-02-22）。
- `strict` は外部 gem の型不足で多数のエラーが出やすく、本 gem の型品質を保ちつつ CI を安定させるには `default` が適切。

### Steepfile 構成案

```ruby
# Steepfile
target :lib do
  signature "sig"
  check "lib"
  # Rails / ActiveRecord は rbs-rails / gem_rbs_collection で解決
  # 不足分のみ library や ignore で補完
end
```

- `signature "sig"`: `sig/` 直下および `sig/manual/` を参照。
- 開発依存に `rbs-rails` と `gem_rbs_collection` を追加し、`rbs_collection.yaml` で Rails 等の型を解決。

### Alternatives Considered
- **strict**: 厳格だが Rails 内部の型不足で誤検知が増える。`default` を採用。
- **型チェックなし**: SC-002（型エラーゼロ）を満たせない。却下。

---

## 3. Data.define と AddressRecord の RBS

### Decision
`AddressRecord` は Ruby 3.2 で `Data.define` により定義されている。rbs-inline による自動生成が Data クラスで完全に機能しない場合に備え、`sig/manual/address_record.rbs` に全フィールドの型を手書きで定義する。`sig/manual/` は `rbs-inline` の出力対象外とする。

### Rationale
- RBS の `Data` 型表現は Steep/rbs-inline のバージョンによって差があり、自動生成だけでは不十分な場合がある（Edge Cases 記載）。
- 手動定義を `sig/manual/` に分離することで、`rbs-inline` の再実行で上書きされず、メンテナンスが明確になる。

### 手動 RBS の内容（AddressRecord）

全フィールド: `postal_code`, `pref_code`, `pref`, `city`, `town`, `kana_pref`, `kana_city`, `kana_town`, `has_alias`, `is_partial`, `is_large_office` を、それぞれ `String` または `String?`、`bool` で定義する。RBS の `Data` クラス定義または `interface` で表現する。

### Alternatives Considered
- **AddressRecord を untyped のまま**: 公開 API の返り値型が不明になり SC-003 に違反。却下。
- **# steep:ignore で一時回避**: 恒久対応として不適切。手書き RBS で正しく定義する。

---

## 4. 開発依存 gem とバージョン

### Decision
gemspec の `development_dependency` に以下を追加する。

| gem | 用途 | バージョン方針 |
|-----|------|----------------|
| `rbs-inline` | ソースから .rbs 生成 | `~> 1.0`（安定版に合わせて調整） |
| `steep` | 型チェック | 特定マイナー範囲で固定 |
| `rbs-rails` | Rails/AR 型定義 | 利用可能な安定版 |
| `gem_rbs_collection` | 他 gem の型定義取得 | 利用可能な安定版 |

- 実際のバージョンは導入時に `bundle add --group development` 等で確認し、gemspec に記載する。

### Rationale
- FR-002 / FR-003 で必須。rbs-rails と gem_rbs_collection により、ActiveRecord や Rails 内部の型を参照し、Steep の誤検知を減らす（Clarifications 2026-02-22）。

---

## 5. Rake タスク

### Decision
- `rake rbs:generate`: `rbs-inline --output sig/ lib/` を実行し、`sig/` を更新する。
- `rake steep`: `steep check` を実行し、型チェック結果の終了コードをそのまま返す（エラー時は非ゼロ）。

既存の `lib/tasks/jp_address_complement.rake` に追加するか、プロジェクト方針に合わせて別 Rake ファイルでも可。

### Rationale
- FR-005 / FR-006 を満たす。開発者が `bundle exec rake rbs:generate` と `bundle exec rake steep` で統一して実行できるようにする。

---

## 6. RuboCop との共存

### Decision
rbs-inline の `# @rbs` コメントが既存 RuboCop ルール（行長・コメントスタイル等）と競合する場合は、`.rubocop.yml` を最小限の変更で調整し、理由をコメントで明記する。`# rubocop:disable` は使用しない（Constitution III）。

### Rationale
- FR-010 および Constitution III 準拠。rbs-inline は行が長くなりがちなため、該当ルールの例外を設定で許可する場合がある。

### Alternatives Considered
- **rubocop:disable**: 禁止のため使用しない。
- **アノテーションを短く分割**: rbs-inline の記法上、分割が難しい場合がある。設定調整を優先する。

---

## 7. 型エラー抑制（# steep:ignore）

### Decision
Steep が false positive を報告する箇所に**限定**して `# steep:ignore` を使用する。使用時は理由を直後のコメントで明記し、コードレビューで乱用を防ぐ。

### Rationale
- FR-004: 型エラーゼロを達成しつつ、Rails 内部等の型不足による誤検知のみを抑制する。
- 理由の明記により、将来の Steep や rbs の改善で削除できるか判断しやすくする。

---

## 8. sig/ ディレクトリ構成

### Decision
- `sig/` 直下および `sig/jp_address_complement/` 以下: rbs-inline が生成する `.rbs` を配置。
- `sig/manual/`: 手動定義（`address_record.rbs` 等）を配置。rbs-inline はこのディレクトリを上書きしない。
- 既存の `sig/jp_address_complement.rbs` はコメントのみの最小ファイルのため、本機能で完全に置き換える（Assumptions 記載）。

### Rationale
- 自動生成と手動補完を分離することで、再生成時の意図しない上書きを防ぎ、FR-007 の AddressRecord 手書き定義を安全に維持する。

---

## 9. Repository インターフェースの RBS

### Decision
`Repositories::PostalCodeRepository` は抽象インターフェースとして RBS で定義する。実装では `find_by_code(code: String) -> Array[AddressRecord]` および `find_by_prefix(prefix: String) -> Array[AddressRecord]` のシグネチャを持つ（現行実装のメソッド名に合わせる）。

### Rationale
- FR-009 の「インターフェースとしての型定義」を満たす。実装クラス（`ActiveRecordPostalCodeRepository`）はこのインターフェースに従う形で rbs-inline によりシグネチャを生成する。

---

## 10. 未解決・フォロー事項

| 項目 | 対応 |
|------|------|
| Ruby 3.0/3.1 の Struct フォールバック | 本機能は Ruby 3.2+ を前提とする型定義を記載。3.0/3.1 用の別 RBS はスコープ外とする。 |
| CI での steep check | Phase 2（tasks）で CI 設定に `bundle exec rake steep` をゲートとして追加する。 |
| rbs-inline のバージョン | 導入時に 1.x 系の最新安定版を確認し、gemspec に固定する。 |
