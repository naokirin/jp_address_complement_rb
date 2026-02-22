# frozen_string_literal: true
# rbs_inline: disabled — AddressRecord は Data.define のため sig/manual/address_record.rbs で手動定義

module JpAddressComplement
  # 郵便番号に対応する住所データの値オブジェクト
  # ActiveRecord インスタンスを返さないことでコアロジックの AR 依存を排除する
  AddressRecord = if RUBY_VERSION >= '3.2'
                    Data.define(
                      :postal_code,
                      :pref_code,
                      :pref,
                      :city,
                      :town,
                      :kana_pref,
                      :kana_city,
                      :kana_town,
                      :has_alias,
                      :is_partial,
                      :is_large_office
                    )
                  else
                    Struct.new(
                      :postal_code,
                      :pref_code,
                      :pref,
                      :city,
                      :town,
                      :kana_pref,
                      :kana_city,
                      :kana_town,
                      :has_alias,
                      :is_partial,
                      :is_large_office,
                      keyword_init: true
                    ) do
                      def frozen?
                        true
                      end
                    end
                  end
end
