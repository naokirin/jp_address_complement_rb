# Contract: CSV インポート（CsvImporter と Rake タスク）

**Feature**: 003-csv-remove-obsolete  
**Contract Type**: インポート API と Rake タスクの入出力

---

## 1. `JpAddressComplement::Importers::CsvImporter`

### 1.1 コンストラクタ

- **シグネチャ**: `new(csv_path)`
- **引数**: `csv_path` — CSV ファイルのパス（String）
- **挙動**: 従来どおり。ファイル存在チェックは `import` 内で実施。

### 1.2 `#import`

- **シグネチャ**: `import → インポート結果（件数情報を持つオブジェクトまたは Hash）`
- **戻り値（本機能で拡張）**: 次のいずれかを満たすこと。
  - **必須**: 追加（新規）・更新・削除の件数を利用者コードから参照できること。
  - 例: `{ inserted: Integer, updated: Integer, deleted: Integer }` または `Data.define(:inserted, :updated, :deleted)` のインスタンス。
  - 簡易案: `{ upserted: Integer, deleted: Integer }`（upsert 総数と削除数のみ）。
- **例外**:
  - ファイルが存在しない: `JpAddressComplement::ImportError`（既存どおり）。
  - 空CSV（有効行が 0 件）: インポートを実行せず、`JpAddressComplement::ImportError`（または同等）を発生させる。既存データは変更しない。
- **処理順**: (1) 空CSVでないか確認（有効行が 1 件もない場合はエラー）、(2) CSV 走査でキー集合を蓄積しつつバッチ upsert、(3) upsert が全て成功したら、キー集合に含まれない行を削除、(4) 件数を返す。
- **冪等性**: 同じCSVを複数回流しても、最終状態が同じになること（既存と同様）。

### 1.3 一意キー

- upsert および削除対象の判定に使うキー: `(postal_code, pref_code, city, town)`（既存の `unique_by` と同一）。

---

## 2. Rake タスク `jp_address_complement:import`

- **起動**: `rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV`（既存どおり）。
- **環境変数**: `CSV` にファイルパスを指定。未指定の場合は既存どおりエラー。
- **出力（本機能で拡張）**: インポート完了時に、追加・更新・削除の件数を標準出力に表示する。
  - 例: `インポート完了: 追加 1000 件, 更新 500 件, 削除 200 件` または `インポート完了: upsert 1500 件, 削除 200 件`。
- **エラー時**: 空CSVやファイル不存在の場合は、既存と同様にエラーメッセージを出力し、既存データは変更しない。
