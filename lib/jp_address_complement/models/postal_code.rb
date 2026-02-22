# frozen_string_literal: true
# rbs_inline: enabled

require 'active_record'

module JpAddressComplement
  # 住所テーブル (jp_address_complement_postal_codes) に対応する ActiveRecord モデル
  # @rbs inherits ActiveRecord::Base
  class PostalCode < ActiveRecord::Base
    self.table_name = 'jp_address_complement_postal_codes'

    validates :postal_code, presence: true, format: { with: /\A\d{7}\z/ }
    validates :pref_code, presence: true
    validates :pref, presence: true
    validates :city, presence: true

    # Steep 用: ActiveRecord のクラスメソッド（rbs-inline で generated に含める）
    # @rbs (*untyped) -> untyped
    def self.where(*_args) = super
    # @rbs (Symbol column) -> untyped
  end
end
