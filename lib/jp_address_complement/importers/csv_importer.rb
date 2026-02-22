# frozen_string_literal: true
# rbs_inline: enabled

require 'csv'
require_relative '../address_record'
require_relative '../models/postal_code'

module JpAddressComplement
  module Importers
    # KEN_ALL.CSV を読み込み、jp_address_complement_postal_codes テーブルに upsert する
    # Shift_JIS 形式の CSV を自動で UTF-8 に変換して処理する
    class CsvImporter
      BATCH_SIZE = 1000 #: Integer

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

      # CSV を読み込んでバッチ upsert する
      # @rbs () -> Integer
      # @return [Integer] インポートされた行数
      def import
        raise ImportError, "CSV ファイルが見つかりません: #{@csv_path}" unless File.exist?(@csv_path)

        total = 0
        batch = [] #: Array[Hash[Symbol, untyped]]

        CSV.foreach(@csv_path, encoding: 'Windows-31J:UTF-8') do |row|
          record = parse_row(row)
          next if record.nil?

          batch << record
          if batch.size >= BATCH_SIZE
            upsert_batch(batch)
            total += batch.size
            batch.clear
          end
        end

        unless batch.empty?
          upsert_batch(batch)
          total += batch.size
        end

        total
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

      # @rbs (Array[Hash[Symbol, untyped]] batch) -> void
      def upsert_batch(batch)
        PostalCode.upsert_all(
          batch,
          unique_by: %i[postal_code pref_code city town]
        )
      end
    end
  end
end
