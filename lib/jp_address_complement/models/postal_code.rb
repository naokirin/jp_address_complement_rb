# frozen_string_literal: true

# rbs_inline: disabled — ActiveRecord::Base 継承のため型は sig/manual/ で手動管理
require 'active_record'

module JpAddressComplement
  # 住所テーブル (jp_address_complement_postal_codes) に対応する ActiveRecord モデル
  class PostalCode < ActiveRecord::Base
    self.table_name = 'jp_address_complement_postal_codes'

    validates :postal_code, presence: true, format: { with: /\A\d{7}\z/ }
    validates :pref_code, presence: true
    validates :pref, presence: true
    validates :city, presence: true
  end
end
