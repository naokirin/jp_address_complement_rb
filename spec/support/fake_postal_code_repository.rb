# frozen_string_literal: true

require 'jp_address_complement/address_record'
require 'jp_address_complement/repositories/postal_code_repository'

module JpAddressComplement
  # テスト用インメモリ Repository 実装
  # DB なしでコアロジックを高速テストするために使用する
  class FakePostalCodeRepository < Repositories::PostalCodeRepository
    def initialize(records = [])
      super()
      @records = records
    end

    def find_by_code(code)
      @records.select { |r| r.postal_code == code }
    end

    def find_by_prefix(prefix)
      @records.select { |r| r.postal_code.start_with?(prefix) }
    end

    def find_postal_codes_by_address(pref:, city:, town: nil)
      return [] if blank?(pref) || blank?(city)

      selected = @records.select { |r| address_match?(r, pref, city, town) }
      selected.map(&:postal_code).uniq
    end

    def add(record)
      @records << record
      self
    end

    def clear
      @records.clear
      self
    end

    private

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def address_match?(record, pref, city, town)
      return false unless record.pref == pref && record.city == city
      return true if town.nil? || town.to_s.strip.empty?

      record.town == town
    end
  end
end
