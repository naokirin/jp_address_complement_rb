# frozen_string_literal: true
# rbs_inline: enabled

require 'csv'
require_relative '../address_record'
require_relative '../models/postal_code'

module JpAddressComplement
  module Importers
    # インポート結果（件数報告用）
    # @rbs type upserted = Integer
    # @rbs type deleted = Integer
    ImportResult = Data.define(:upserted, :deleted)

    # UTF-8 版 KEN_ALL（utf_ken_all.csv）を読み込み、jp_address_complement_postal_codes テーブルに upsert する
    # UTF-8 形式の CSV を前提として処理する
    class CsvImporter
      BATCH_SIZE = 1000 #: Integer

      # バッチ削除・ユニークキーとして使うカラム群
      KEY_COLUMNS = %i[postal_code pref_code city town kana_pref kana_city kana_town].freeze #: Array[Symbol]

      # SQLite のデフォルト式木深度制限（1000）対策。
      # reduce(:or) で N 件 OR 結合すると深さ ≈ N + 6 になるため、500 件に収める（深さ ≈ 506）。
      DELETE_CHUNK_SIZE = 500 #: Integer

      # 列インデックス（KEN_ALL.CSV 形式）
      COL_PREF_CODE = 0 #: Integer
      COL_POSTAL_CODE = 2 #: Integer
      COL_KANA_PREF = 3 #: Integer
      COL_KANA_CITY = 4 #: Integer
      COL_KANA_TOWN = 5 #: Integer
      COL_PREF = 6 #: Integer
      COL_CITY = 7 #: Integer
      COL_TOWN = 8 #: Integer
      COL_IS_PARTIAL = 9 #: Integer
      COL_HAS_ALIAS = 12 #: Integer
      COL_IS_LARGE_OFFICE = 13 #: Integer

      # @rbs (String csv_path) -> void
      def initialize(csv_path)
        @csv_path = csv_path
      end

      # CSV を読み込み、upsert 後に古いバージョンの行を一括削除する。戻り値は ImportResult。
      # バージョンは既存レコードの最大値+1 で、別テーブルでは管理しない。
      # @rbs () -> ImportResult
      # @return [ImportResult] upserted 件数と deleted 件数
      def import
        raise ImportError, "CSV ファイルが見つかりません: #{@csv_path}" unless File.exist?(@csv_path)

        import_version = (PostalCode.maximum(:version) || 0) + 1
        total_upserted, keys_in_csv = read_and_upsert(import_version)
        raise ImportError, '有効行が0件のためインポートを実行しません（空CSVは拒否します）' if keys_in_csv.empty?

        deleted = delete_obsolete(import_version)
        ImportResult.new(upserted: total_upserted, deleted: deleted)
      end

      private

      # @rbs (Array[String?] row) -> (Hash[Symbol, untyped] | nil)
      def parse_row(row)
        postal_code = row[COL_POSTAL_CODE]&.strip
        pref_code = row[COL_PREF_CODE]&.strip&.slice(0, 2)
        pref = row[COL_PREF]&.strip
        city = row[COL_CITY]&.strip

        return nil if postal_code.nil? || pref_code.nil? || pref.nil? || city.nil?
        return nil unless postal_code.match?(/\A\d{7}\z/)

        {
          postal_code: postal_code,
          pref_code: pref_code,
          pref: pref,
          city: city,
          town: row[COL_TOWN]&.strip,
          kana_pref: row[COL_KANA_PREF]&.strip,
          kana_city: row[COL_KANA_CITY]&.strip,
          kana_town: row[COL_KANA_TOWN]&.strip,
          has_alias: row[COL_HAS_ALIAS]&.strip == '1',
          is_partial: row[COL_IS_PARTIAL]&.strip == '1',
          is_large_office: row[COL_IS_LARGE_OFFICE]&.strip == '1'
        }
      end

      # @rbs (Integer import_version) -> [Integer, Hash[untyped, bool]]
      def read_and_upsert(import_version)
        keys_in_csv = {} #: Hash[untyped, bool]
        total_upserted = 0
        batch = [] #: Array[Hash[Symbol, untyped]]

        CSV.foreach(@csv_path, encoding: 'UTF-8') do |row|
          record = parse_row(row)
          next if record.nil?

          record = record.merge(version: import_version)
          keys_in_csv[row_key(record)] = true
          batch << record
          if batch.size >= BATCH_SIZE
            upsert_batch(batch)
            total_upserted += batch.size
            batch.clear
          end
        end

        if batch.any?
          upsert_batch(batch)
          total_upserted += batch.size
        end

        [total_upserted, keys_in_csv]
      end

      # @rbs (Array[Hash[Symbol, untyped]] batch) -> void
      def upsert_batch(batch)
        PostalCode.transaction do
          batch_delete(batch)
          PostalCode.upsert_all(batch)
        end
      end

      # バッチ内の全レコードを1クエリで一括削除する
      # Arel を使うことで NULL カラム（town 等）を IS NULL として正しく扱う
      # @rbs (Array[Hash[Symbol, untyped]] batch) -> void
      def batch_delete(batch)
        table = PostalCode.arel_table
        batch.each_slice(DELETE_CHUNK_SIZE) do |chunk|
          conditions = chunk.map do |record|
            KEY_COLUMNS.map { |col| table[col].eq(record[col]) }.reduce(:and)
          end.reduce(:or)
          PostalCode.where(conditions).delete_all
        end
      end

      # 郵便番号・都道府県・市区町村・町域（漢字）が同じでも読み（カナ）が異なれば別レコードとして扱う
      # @rbs (Hash[Symbol, untyped] record) -> Array[String]
      def row_key(record)
        [
          record[:postal_code].to_s,
          record[:pref_code].to_s,
          record[:city].to_s,
          (record[:town] || '').to_s,
          (record[:kana_pref] || '').to_s,
          (record[:kana_city] || '').to_s,
          (record[:kana_town] || '').to_s
        ]
      end

      # 今回のインポートより古いバージョンの行を一括削除し、削除件数を返す
      # @rbs (Integer import_version) -> Integer
      def delete_obsolete(import_version)
        PostalCode.where(version: ...import_version).delete_all
      end
    end
  end
end
