# frozen_string_literal: true

module JpAddressComplement
  # Gem の設定を保持するクラス
  # configure ブロックを通じて repository アダプターを注入する
  class Configuration
    attr_accessor :repository

    def initialize
      @repository = nil
    end
  end
end
