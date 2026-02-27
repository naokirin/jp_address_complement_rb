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
        full_address = record.pref + record.city + record.normalized_town.to_s
        address.include?(full_address)
      end
    end

    # 都道府県・市区町村・町域から郵便番号候補を取得する（逆引き）。町域は前方一致。
    # @rbs (pref: String?, city: String?, ?town: String?) -> Array[[String, AddressRecord]]
    # @param pref [String] 都道府県名（正式名称）
    # @param city [String] 市区町村名
    # @param town [String, nil] 町域名。省略時は都道府県＋市区町村のみ。指定時は前方一致で候補を返す
    # @return [Array<[String, AddressRecord]>] [郵便番号, AddressRecord] の配列。該当なし・入力不十分時は []
    def search_postal_codes_by_address(pref:, city:, town: nil)
      return [] if pref.nil? || pref.to_s.strip.empty?
      return [] if city.nil? || city.to_s.strip.empty?

      records = @repository.find_postal_codes_by_address(pref: pref, city: city, town: town)
      records.map { |r| [r.postal_code, r] }
    end
  end
end
