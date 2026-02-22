# クイックスタート: RBS 型注釈（開発者向け）

**対象**: 本 gem のコントリビューター  
**前提**: Ruby 3.2 以上、`bundle install` 済み

---

## セットアップ（初回）

開発依存に `rbs-inline`・`steep`・`rbs-rails`・`gem_rbs_collection` が含まれていることを確認し、以下で型定義を生成・型チェックを実行できるようにする。

```bash
bundle install
bundle exec rake rbs:generate   # sig/ を生成
bundle exec rake steep          # 型チェック（エラーゼロが目標）
```

---

## 日常の開発フロー

### 1. 実装を書いたら rbs-inline アノテーションを付ける

メソッドの**直上**に `# @rbs` でシグネチャを書く。

```ruby
# @rbs def search_by_postal_code(code: String) -> Array[AddressRecord]
def search_by_postal_code(code)
  # ...
end
```

- 引数: `名前: 型`。複数ある場合は `(a: String, b: Integer)` のようにカンマ区切り。
- 返り値: `-> 型`。配列は `Array[AddressRecord]`、nil 許容は `String?`。

### 2. シグネチャを再生成する

```bash
bundle exec rake rbs:generate
```

`sig/` 直下および `sig/jp_address_complement/` 以下が更新される。`sig/manual/` は変更されない。

### 3. 型チェックを実行する

```bash
bundle exec rake steep
```

- エラーゼロで終了すれば OK。
- エラーが出た場合は、該当する `.rb` のアノテーションか、`sig/manual/` の手動定義を修正する。

### 4. 誤検知（false positive）のみ抑制したい場合

どうしても Steep の誤検知だけを抑えたい箇所では、**理由をコメントで明記**した上で `# steep:ignore` を使う。

```ruby
# Steep が Rails 内部の型不足で誤検知するため抑制（理由）
# steep:ignore
some_rails_internal_call
```

乱用は避け、レビューで確認する。

---

## 手動 RBS（AddressRecord など）

`Data.define` で定義した `AddressRecord` は、rbs-inline が十分な型を出さないため `sig/manual/address_record.rbs` で手書きする。

- 編集するのは `sig/manual/` 内のみ。
- `rake rbs:generate` では `sig/manual/` は上書きされない。
- フィールド追加・変更時はここを忘れずに更新する。

---

## CI での型チェック

PR では `bundle exec rake steep` が通ることがマージ条件となる（Phase 2 で CI に組み込み）。ローカルでマージ前に必ず実行すること。

```bash
bundle exec rake steep
```

終了コードが 0 でない場合は型エラーが残っているので修正する。

---

## トラブルシューティング

| 現象 | 対処 |
|------|------|
| `rbs-inline: command not found` | `bundle exec rbs-inline` を使う。Rake タスクは `bundle exec` 経由で実行すること。 |
| `sig/` が空のまま | `bundle exec rake rbs:generate` を実行。`lib/` に `# @rbs` が付いているか確認。 |
| Steep が Rails で大量にエラー | `rbs-rails` と `gem_rbs_collection` が入っているか確認。Steepfile の `library` や `ignore` で対象を絞る。 |
| AddressRecord の型が untyped になる | `sig/manual/address_record.rbs` を正しく定義し、Steep が `sig/` を参照しているか確認。 |
| RuboCop が rbs コメントで怒る | `.rubocop.yml` で該当ルールを調整し、理由をコメントで明記（`rubocop:disable` は使わない）。 |

---

## 参照

- 型の全体像: [data-model.md](./data-model.md)
- 公開 API の RBS 契約: [contracts/rbs-public-api.md](./contracts/rbs-public-api.md)
- 調査結果: [research.md](./research.md)
