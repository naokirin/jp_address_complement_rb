# frozen_string_literal: true

module JpAddressComplement
  # 郵便番号の正規化処理を担当するクラス
  # 全角→半角変換・〒記号除去・ハイフン除去を行う
  class Normalizer
    # 半角数字以外の文字を除去するためのパターン
    DIGIT_ONLY = /\A\d{7}\z/
    PREFIX_MIN_LENGTH = 4

    class << self
      # 郵便番号文字列を正規化して7桁の半角数字文字列を返す
      # @param code [String, nil] 郵便番号文字列（ハイフン・全角・〒記号を自動除去）
      # @return [String, nil] 正規化後の7桁郵便番号。不正な場合は nil
      def normalize_postal_code(code)
        return nil if code.blank?

        normalized = normalize_string(code)
        return nil unless normalized.match?(DIGIT_ONLY)

        normalized
      end

      # 郵便番号プレフィックスを正規化する
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

      private

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
