# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'jp_address_complement/version'
require_relative 'jp_address_complement/address_record'
require_relative 'jp_address_complement/normalizer'
require_relative 'jp_address_complement/configuration'
require_relative 'jp_address_complement/repositories/postal_code_repository'
require_relative 'jp_address_complement/searcher'
require_relative 'jp_address_complement/prefecture'

# Rails 環境でのみ Railtie をロード
require_relative 'jp_address_complement/railtie' if defined?(Rails)

module JpAddressComplement
  class Error < StandardError; end
  class ImportError < Error; end

  class << self
    # Gem の設定を行う
    # @rbs () { (Configuration) -> void } -> void
    # @yield [Configuration]
    def configure
      yield(configuration)
    end

    # 現在の設定を返す
    # @rbs () -> Configuration
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # 設定をリセットする（主にテスト用）
    # @rbs () -> void
    def reset_configuration!
      @configuration = Configuration.new
    end

    # 設定されたリポジトリを返す（デフォルトは ActiveRecord 実装）
    # @rbs () -> Repositories::PostalCodeRepository
    # @return [Repositories::PostalCodeRepository]
    def repository
      configuration.repository ||= default_repository
    end

    # 7桁郵便番号から住所レコードを検索する
    # @rbs (String) -> Array[AddressRecord]
    # @param code [String] 郵便番号（ハイフン・全角・〒 記号を自動正規化）
    # @return [Array<AddressRecord>]
    def search_by_postal_code(code)
      Searcher.new(repository).search_by_postal_code(code)
    end

    # 郵便番号の先頭4桁以上から住所候補を検索する
    # @rbs (String) -> Array[AddressRecord]
    # @param prefix [String] 郵便番号の先頭部分（4桁以上）
    # @return [Array<AddressRecord>]
    def search_by_postal_code_prefix(prefix)
      Searcher.new(repository).search_by_postal_code_prefix(prefix)
    end

    # 郵便番号と住所文字列の整合性を検証する
    # @rbs (String, String) -> bool
    # @param postal_code [String] 郵便番号（自動正規化）
    # @param address [String] 住所文字列
    # @return [Boolean]
    def valid_combination?(postal_code, address)
      Searcher.new(repository).valid_combination?(postal_code, address)
    end

    # 都道府県コード（JIS X 0401）から都道府県名を返す
    # @rbs (String | Integer?) -> String?
    # @param code [String, Integer, nil] 都道府県コード（01–47）
    # @return [String, nil] 都道府県名。該当なし時は nil
    def prefecture_name_from_code(code)
      Prefecture.name_from_code(code)
    end

    # 都道府県名（正式名称）から都道府県コードを2桁文字列で返す
    # @rbs (String?) -> String?
    # @param name [String, nil] 都道府県の正式名称
    # @return [String, nil] 2桁のコード（例: "13"）。該当なし時は nil
    def prefecture_code_from_name(name)
      Prefecture.code_from_name(name)
    end

    # 都道府県・市区町村・町域から郵便番号候補を取得する（逆引き）
    # @rbs (pref: String?, city: String?, ?town: String?) -> Array[String]
    # @param pref [String] 都道府県名（正式名称）
    # @param city [String] 市区町村名
    # @param town [String, nil] 町域名。省略可
    # @return [Array<String>] 郵便番号の配列。該当なし・入力不十分時は []
    def search_postal_codes_by_address(pref:, city:, town: nil)
      Searcher.new(repository).search_postal_codes_by_address(pref: pref, city: city, town: town)
    end

    private

    # @rbs () -> Repositories::ActiveRecordPostalCodeRepository
    def default_repository
      require_relative 'jp_address_complement/repositories/active_record_postal_code_repository'
      require_relative 'jp_address_complement/models/postal_code'
      Repositories::ActiveRecordPostalCodeRepository.new
    end
  end
end
