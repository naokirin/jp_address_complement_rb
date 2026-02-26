#!/usr/bin/env ruby
# frozen_string_literal: true
# rbs_inline: enabled

require 'csv'
require_relative 'postal_code_repository'
require_relative '../address_record'

module JpAddressComplement
  module Repositories
    # KEN_ALL 形式の CSV ファイルを直接読み込んで検索を行う Repository 実装
    #
    # - ActiveRecord や DB に依存せず、純粋に CSV から AddressRecord を構築する
    # - 初回アクセス時に CSV 全体を読み込み、インメモリでインデックスを構築する（2回目以降はメモリ検索のみ）
    # - CSV は日本郵便公式の KEN_ALL.CSV と同じ列構成を前提とする
    #
    # 典型的な利用例:
    #
    #   require 'jp_address_complement/repositories/csv_postal_code_repository'
    #
    #   JpAddressComplement.configure do |c|
    #     c.repository = JpAddressComplement::Repositories::CsvPostalCodeRepository.new('/path/to/KEN_ALL.CSV')
    #   end
    #
    class CsvPostalCodeRepository < PostalCodeRepository
      # 列インデックス（KEN_ALL.CSV 形式）
      COL_PREF_CODE = 0 # : Integer
      COL_POSTAL_CODE = 2 # : Integer
      COL_KANA_PREF = 3 # : Integer
      COL_KANA_CITY = 4 # : Integer
      COL_KANA_TOWN = 5 # : Integer
      COL_PREF = 6 # : Integer
      COL_CITY = 7 # : Integer
      COL_TOWN = 8 # : Integer
      COL_IS_PARTIAL = 9 # : Integer
      COL_HAS_ALIAS = 12 # : Integer
      COL_IS_LARGE_OFFICE = 13 # : Integer

      # @rbs (String csv_path) -> void
      # @param csv_path [String] 読み込む KEN_ALL 形式 CSV のパス
      def initialize(csv_path)
        super()
        @csv_path = csv_path
        @loaded = false
        @records = [] # : Array[AddressRecord]
        @by_code = Hash.new { |h, k| h[k] = [] } # : Hash[String, Array[AddressRecord]]
      end

      # @rbs (String code) -> Array[AddressRecord]
      def find_by_code(code)
        ensure_loaded
        @by_code[code] || []
      end

      # @rbs (String prefix) -> Array[AddressRecord]
      def find_by_prefix(prefix)
        ensure_loaded
        @records.select { |r| r.postal_code.start_with?(prefix) }
      end

      # @rbs (pref: String?, city: String?, ?town: String?) -> Array[AddressRecord]
      def find_postal_codes_by_address(pref:, city:, town: nil)
        ensure_loaded
        return [] if blank?(pref) || blank?(city)

        town_query = town&.to_s&.strip
        pref_s = pref.to_s
        city_s = city.to_s
        @records.select { |record| address_match?(record, pref_s, city_s, town_query) }
      end

      private

      # @rbs () -> void
      def ensure_loaded
        return if @loaded

        load_csv
        @loaded = true
      end

      # @rbs () -> void
      def load_csv
        validate_csv_path!
        @records.clear
        @by_code.clear
        each_csv_row { |row| append_record(row) }
      rescue Errno::ENOENT
        raise JpAddressComplement::Error, "CSV ファイルが見つかりません: #{@csv_path}"
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
        raise JpAddressComplement::Error, "CSV のエンコーディング変換に失敗しました: #{e.message}"
      end

      # @rbs () -> void
      def validate_csv_path!
        raise JpAddressComplement::Error, 'CSV ファイルが指定されていません' if @csv_path.nil? || @csv_path.to_s.empty?
        raise JpAddressComplement::Error, "CSV ファイルが見つかりません: #{@csv_path}" unless File.exist?(@csv_path)
      end

      # @rbs () { (Array[String?]) -> void } -> void
      def each_csv_row(&)
        CSV.foreach(@csv_path, encoding: 'Windows-31J:UTF-8', &)
      end

      # @rbs (Array[String?] row) -> void
      def append_record(row)
        record = build_record_from_row(row)
        return if record.nil?

        @records << record
        @by_code[record.postal_code] << record
      end

      # @rbs (AddressRecord record, String pref, String city, String? town_query) -> bool
      def address_match?(record, pref, city, town_query)
        return false unless record.pref == pref && record.city == city
        return true if town_query.nil? || town_query.empty?

        record.town.to_s.start_with?(town_query)
      end

      # @rbs (Array[String?] row) -> (AddressRecord | nil)
      def build_record_from_row(row)
        attrs = parse_row_attrs(row)
        return nil unless attrs

        AddressRecord.new(
          postal_code: attrs[:postal_code],
          pref_code: attrs[:pref_code],
          pref: attrs[:pref],
          city: attrs[:city],
          town: attrs[:town],
          kana_pref: attrs[:kana_pref],
          kana_city: attrs[:kana_city],
          kana_town: attrs[:kana_town],
          has_alias: attrs[:has_alias],
          is_partial: attrs[:is_partial],
          is_large_office: attrs[:is_large_office]
        )
      end

      # @rbs (Array[String?] row) -> (Hash[Symbol, untyped] | nil)
      def parse_row_attrs(row)
        required = extract_required_fields(row)
        return nil unless required && valid_postal_code_format?(required[0])

        build_row_attrs(row, required[0], required[1], required[2], required[3])
      end

      # @rbs (Array[String?] row) -> (Array[String] | nil)
      def extract_required_fields(row)
        postal_code = strip_cell(row[COL_POSTAL_CODE])
        pref_code = strip_cell(row[COL_PREF_CODE])&.slice(0, 2)
        pref = strip_cell(row[COL_PREF])
        city = strip_cell(row[COL_CITY])
        return nil if [postal_code, pref_code, pref, city].any?(&:nil?)

        # 上記ガードで nil は除外済み。型を Array[String] に合わせるため to_s で明示
        [postal_code.to_s, pref_code.to_s, pref.to_s, city.to_s]
      end

      # @rbs (String? cell) -> (String | nil)
      def strip_cell(cell)
        cell&.strip
      end

      # @rbs (String? postal_code) -> bool
      def valid_postal_code_format?(postal_code)
        !postal_code.nil? && postal_code.match?(/\A\d{7}\z/)
      end

      # @rbs (Array[String?], String, String, String, String) -> Hash[Symbol, untyped]
      def build_row_attrs(row, postal_code, pref_code, pref, city)
        {
          postal_code: postal_code,
          pref_code: pref_code,
          pref: pref,
          city: city,
          town: row[COL_TOWN]&.strip,
          kana_pref: row[COL_KANA_PREF]&.strip,
          kana_city: row[COL_KANA_CITY]&.strip,
          kana_town: row[COL_KANA_TOWN]&.strip,
          has_alias: flag?(row[COL_HAS_ALIAS]),
          is_partial: flag?(row[COL_IS_PARTIAL]),
          is_large_office: flag?(row[COL_IS_LARGE_OFFICE])
        }
      end

      # @rbs (String? cell) -> bool
      def flag?(cell)
        cell&.strip == '1'
      end

      # @rbs (untyped value) -> bool
      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
