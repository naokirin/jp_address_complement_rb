# frozen_string_literal: true

# rbs_inline: disabled — 継承元が base_record_class で可変のため型は sig/manual/ で手動管理
require 'active_record'

module JpAddressComplement
  # 住所テーブルに対応する ActiveRecord モデル
  # 継承元は JpAddressComplement.base_record_class（未設定時は ActiveRecord::Base）
  # テーブル名は JpAddressComplement.postal_code_table_name（未設定時は 'jp_address_complement_postal_codes'）。initializer で変更可能。
  class PostalCode < base_record_class
    # initializer がモデル読み込み後に実行されるため、参照のたびに設定を読む
    def self.table_name
      JpAddressComplement.postal_code_table_name
    end

    validates :postal_code, presence: true, format: { with: /\A\d{7}\z/ }
    validates :pref_code, presence: true
    validates :pref, presence: true
    validates :city, presence: true
  end
end
