# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'normalizer'
require_relative 'repositories/postal_code_repository'

module JpAddressComplement
  # コア検索ロジック
  # Repository を注入して使用することで ActiveRecord への直接依存を排除する
  class Searcher
    # @rbs (Repositories::PostalCodeRepository repository) -> void
    def initialize(repository)
      @repository = repository
    end

    # 7桁郵便番号から住所レコードを検索する
    # @rbs (String? code) -> Array[AddressRecord]
    # @param code [String, nil] 郵便番号
    # @return [Array<AddressRecord>]
    def search_by_postal_code(code)
      normalized = Normalizer.normalize_postal_code(code)
      return [] if normalized.nil?

      @repository.find_by_code(normalized)
    end

    # 郵便番号プレフィックスから住所候補を検索する（4桁以上）
    # @rbs (String? prefix) -> Array[AddressRecord]
    # @param prefix [String, nil] 郵便番号の先頭部分
    # @return [Array<AddressRecord>]
    def search_by_postal_code_prefix(prefix)
      normalized = Normalizer.normalize_prefix(prefix)
      return [] if normalized.nil?

      @repository.find_by_prefix(normalized)
    end

    # 郵便番号と住所文字列の整合性を検証する
    # @rbs (String? postal_code, String? address) -> bool
    # @param postal_code [String, nil] 郵便番号
    # @param address [String, nil] 住所文字列
    # @return [Boolean]
    def valid_combination?(postal_code, address)
      return false if postal_code.nil? || address.nil?

      normalized = Normalizer.normalize_postal_code(postal_code)
      return false if normalized.nil?

      records = @repository.find_by_code(normalized)
      return false if records.empty?

      records.any? do |record|
        full_address = record.pref + record.city + record.town.to_s
        address.include?(full_address)
      end
    end
  end
end
