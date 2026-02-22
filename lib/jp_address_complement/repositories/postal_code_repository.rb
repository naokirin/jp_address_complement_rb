# frozen_string_literal: true
# rbs_inline: enabled

module JpAddressComplement
  module Repositories
    # データアクセスを抽象化するインターフェース基底クラス
    # 具体的な実装は ActiveRecordPostalCodeRepository またはユーザー定義アダプターで行う
    class PostalCodeRepository
      # 7桁郵便番号で完全一致検索する
      # @rbs (String code) -> Array[AddressRecord]
      # @param code [String] 正規化済み7桁郵便番号
      # @return [Array<AddressRecord>]
      def find_by_code(code)
        raise NotImplementedError, "#{self.class}#find_by_code を実装してください"
      end

      # 郵便番号プレフィックスで前方一致検索する
      # @rbs (String prefix) -> Array[AddressRecord]
      # @param prefix [String] 4桁以上の郵便番号プレフィックス
      # @return [Array<AddressRecord>]
      def find_by_prefix(prefix)
        raise NotImplementedError, "#{self.class}#find_by_prefix を実装してください"
      end

      # 都道府県・市区町村・町域で完全一致検索し、郵便番号の配列を返す（逆引き）
      # @rbs (String? pref, String? city, String? town) -> Array[String]
      # @param pref [String] 都道府県名（正式名称）
      # @param city [String] 市区町村名
      # @param town [String, nil] 町域名。省略時は都道府県＋市区町村のみで検索
      # @return [Array<String>] 郵便番号（7桁文字列）の配列。重複除く。該当なし・入力不十分時は []
      def find_postal_codes_by_address(pref:, city:, town: nil)
        raise NotImplementedError, "#{self.class}#find_postal_codes_by_address を実装してください"
      end
    end
  end
end
