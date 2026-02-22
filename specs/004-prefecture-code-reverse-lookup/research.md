# Research: 都道府県コード変換・住所逆引き

**Branch**: `004-prefecture-code-reverse-lookup`  
**Date**: 2026-02-23

---

## 1. 都道府県コード⇔名称の保持場所

**Decision**: 47 都道府県のコード・名称マッピングは **gem 内の静的な定数（ハッシュまたは配列）** で保持する。DB や外部ファイルは使わない。

**Rationale**:
- JIS X 0401 の都道府県コード（01–47）は国で定められた固定データであり、郵便番号データの更新とは独立している。
- 47 件のみのためメモリ負荷は無視でき、参照も O(1) で 5ms 以下の応答を満たせる。
- DB に依存しないため、未インポート状態でもコード⇔名称だけは利用可能になり、利用者にとって分かりやすい。
- 既存の `postal_codes` テーブルの `pref_code` / `pref` と体系を揃えるため、JIS X 0401 の正式な 01–47 のマッピングを採用する。

**Alternatives considered**:
- **DB の distinct から取得**: 郵便番号データに依存し、未インポート時は使えない。また毎回クエリする必要があり、定数参照より遅い。
- **外部 YAML/JSON**: ファイル I/O とパースが発生し、定数より遅く、配布・バージョン管理も複雑になる。

---

## 2. 逆引きの実装経路（Repository 拡張）

**Decision**: 既存の `PostalCodeRepository` に **`find_postal_codes_by_address(pref:, city:, town: nil)`** を追加する。戻り値は郵便番号の配列（`Array<String>` または仕様に合わせて `Array<AddressRecord>` の postal_code のみ返すかは contracts で定義）。実装は `ActiveRecordPostalCodeRepository` で `WHERE pref = ? AND city = ? AND (town = ? OR town IS NULL)` のような完全一致クエリとする。

**Rationale**:
- 既存の「郵便番号→住所」と対になる逆方向の検索であり、同じ Repository に置くことで一貫したデータアクセス層を保てる。
- 仕様で「都道府県＋市区町村必須、町域は任意」「各フィールド完全一致」とあるため、1 メソッドで表現できる。
- Rails 非依存のコアを保つため、Repository インターフェースにだけ依存し、Searcher がそれを呼ぶ形は既存パターンと同じ。

**Alternatives considered**:
- **専用の ReverseLookupRepository**: 現時点では 1 クエリで完結するため、YAGNI の観点で既存 Repository の拡張で十分。
- **連結文字列で検索**: 仕様で分離入力・完全一致に決まっているため不採用。

---

## 3. 逆引きクエリのインデックス

**Decision**: 逆引きのパフォーマンス（SC-003: 50ms p99）を満たすため、**`(pref, city, town)` の複合インデックス**（または `(pref_code, city, town)`）を推奨する。既存の `postal_code` 単一インデックスと一意制約 `(postal_code, pref_code, city, town)` だけでは、逆引きはフルスキャンに近くなる可能性がある。

**Rationale**:
- 逆引きは `WHERE pref = ? AND city = ? AND (town = ? OR town IS NULL)` のような条件になるため、`pref, city, town` の順の複合インデックスが有効。
- 既存テーブルに対する追加インデックスは、マイグレーションまたは quickstart で「推奨インデックス」として案内する。001 で既存のマイグレーションに含めていないため、004 で「逆引き用推奨インデックス」をドキュメントと optional マイグレーションで提供するか、既存マイグレーションを変更しない場合は data-model と quickstart に記載のみとする（実装時に判断）。

**Alternatives considered**:
- **インデックスなし**: 12 万件程度ならフルスキャンでも 50ms を下回る可能性はあるが、保証は難しい。インデックスを推奨する方が安全。
- **全文検索**: 仕様は完全一致のため不要。

---

## 4. 戻り値の型（逆引き）

**Decision**: 逆引きの戻り値は **郵便番号の文字列の配列 `Array<String>`** とする。`AddressRecord` の配列でも要件は満たせるが、仕様が「郵便番号の候補一覧」としているため、呼び出し側がそのまま使える `["1000001", "1000002"]` の形を採用する。必要なら後から `Array<AddressRecord>` を返す API を追加可能。

**Rationale**:
- 仕様の「郵便番号の候補一覧」に素直に対応し、既存の `search_by_postal_code`（AddressRecord 配列）とは用途が違うため、シンプルに文字列配列で揃える。
- 一意化は仕様どおり「該当するすべての郵便番号を候補として返す」で、同一郵便番号が複数レコード（町域違い）で存在する場合は 1 つにまとめる。

**Alternatives considered**:
- **Array<AddressRecord>**: 将来的に住所詳細も必要になった場合の拡張用。現仕様では「郵便番号候補」のみなので、まずは `Array<String>` で十分。
