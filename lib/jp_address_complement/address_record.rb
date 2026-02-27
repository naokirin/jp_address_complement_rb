# frozen_string_literal: true
# rbs_inline: disabled — AddressRecord は Data.define のため sig/manual/address_record.rbs で手動定義

module JpAddressComplement
  # 郵便番号に対応する住所データの値オブジェクト
  # ActiveRecord インスタンスを返さないことでコアロジックの AR 依存を排除する
  ADDRESS_RECORD_ATTRIBUTES = %i[
    postal_code
    pref_code
    pref
    city
    town
    kana_pref
    kana_city
    kana_town
    has_alias
    is_partial
    is_large_office
  ].freeze

  # Ruby 3.2 以降を対象。Data.define で定義する。
  AddressRecord = Data.define(*ADDRESS_RECORD_ATTRIBUTES)

  # インスタンスメソッドは Steep の型解決のためクラス再オープンで定義（Data.define のブロック内だと self が正しく解釈されない）
  class AddressRecord
    # 通常住所に含まれない情報（括弧（）内の部分、「以下に掲載がない場合」等）を除いた町域名
    def normalized_town
      Normalizer.normalize_town_for_display(town)
    end

    # 通常住所に含まれない情報を除いた町域カナ
    def normalized_kana_town
      Normalizer.normalize_town_for_display(kana_town)
    end
  end
end
