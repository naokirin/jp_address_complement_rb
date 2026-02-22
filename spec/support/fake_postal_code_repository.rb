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

    def add(record)
      @records << record
      self
    end

    def clear
      @records.clear
      self
    end
  end
end
