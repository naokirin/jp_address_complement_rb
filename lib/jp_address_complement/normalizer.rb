# frozen_string_literal: true
# rbs_inline: enabled

module JpAddressComplement
  # 郵便番号の正規化処理を担当するクラス
  # 全角→半角変換・〒記号除去・ハイフン除去を行う
  class Normalizer
    # 半角数字以外の文字を除去するためのパターン
    DIGIT_ONLY = /\A\d{7}\z/ #: Regexp
    PREFIX_MIN_LENGTH = 4 #: Integer

    # 町域から除去する「通常住所に含まれない」固定文字列（漢字・かな両方）
    TOWN_DISPLAY_REMOVAL_STRINGS = [
      '以下に掲載がない場合',
      'イカニケイサイガナイバアイ' # 以下に掲載がない場合（カナ）
    ].freeze

    class << self
      # 郵便番号文字列を正規化して7桁の半角数字文字列を返す
      # @rbs (String?) -> String?
      # @param code [String, nil] 郵便番号文字列（ハイフン・全角・〒記号を自動除去）
      # @return [String, nil] 正規化後の7桁郵便番号。不正な場合は nil
      def normalize_postal_code(code)
        return nil if code.blank?

        normalized = normalize_string(code)
        return nil unless normalized.match?(DIGIT_ONLY)

        normalized
      end

      # 郵便番号プレフィックスを正規化する
      # @rbs (String?) -> String?
      # @param prefix [String, nil] 郵便番号の先頭部分（4桁以上）
      # @return [String, nil] 正規化後の数字文字列。4桁未満または不正な場合は nil
      def normalize_prefix(prefix)
        return nil if prefix.blank?

        normalized = normalize_string(prefix)
        return nil if normalized.empty?
        return nil unless normalized.match?(/\A\d+\z/)
        return nil if normalized.length < PREFIX_MIN_LENGTH

        normalized
      end

      # 町域文字列から「通常住所に含まれない情報」を除いた表示用文字列を返す
      # 除去対象: 「以下に掲載がない場合」、全角括弧（）で囲まれた部分全体
      # @rbs (String?) -> String?
      # @param town_str [String, nil] 町域（漢字）または町域カナ
      # @return [String, nil] 除去後の文字列。nil または空になった場合は nil
      def normalize_town_for_display(town_str)
        return nil if town_str.nil?

        s = town_str.to_s.strip
        return nil if s.empty?

        # 全角括弧（）で囲まれた部分をすべて除去
        s = s.gsub(/（[^）]*）/, '')
        TOWN_DISPLAY_REMOVAL_STRINGS.each { |rem| s = s.gsub(rem, '') }
        s = s.strip
        s.empty? ? nil : s
      end

      private

      # @rbs (String) -> String
      def normalize_string(str)
        str
          .tr('〒', '')
          .tr('０-９', '0-9')
          .tr('-ー－', '')
          .strip
      end
    end
  end
end
