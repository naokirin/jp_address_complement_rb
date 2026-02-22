# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'jp_address_complement/version'
require_relative 'jp_address_complement/address_record'
require_relative 'jp_address_complement/normalizer'
require_relative 'jp_address_complement/configuration'
require_relative 'jp_address_complement/repositories/postal_code_repository'
require_relative 'jp_address_complement/searcher'

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

    private

    # @rbs () -> Repositories::ActiveRecordPostalCodeRepository
    def default_repository
      require_relative 'jp_address_complement/repositories/active_record_postal_code_repository'
      require_relative 'jp_address_complement/models/postal_code'
      Repositories::ActiveRecordPostalCodeRepository.new
    end
  end
end
