# frozen_string_literal: true
# rbs_inline: enabled

module JpAddressComplement
  # Gem の設定を保持するクラス
  # configure ブロックを通じて repository アダプター・PostalCode の継承元などを注入する
  class Configuration
    attr_accessor :repository #: Repositories::PostalCodeRepository?
    # PostalCode モデルの継承元。nil のときは ActiveRecord::Base。initializer で ApplicationRecord 等に変更可能。
    attr_accessor :postal_code_model_base #: Class?

    # @rbs () -> void
    def initialize
      @repository = nil
      @postal_code_model_base = nil
    end
  end
end
