# frozen_string_literal: true

module JpAddressComplement
  module Repositories
    # データアクセスを抽象化するインターフェース基底クラス
    # 具体的な実装は ActiveRecordPostalCodeRepository またはユーザー定義アダプターで行う
    class PostalCodeRepository
      # 7桁郵便番号で完全一致検索する
      # @param code [String] 正規化済み7桁郵便番号
      # @return [Array<AddressRecord>]
      def find_by_code(code)
        raise NotImplementedError, "#{self.class}#find_by_code を実装してください"
      end

      # 郵便番号プレフィックスで前方一致検索する
      # @param prefix [String] 4桁以上の郵便番号プレフィックス
      # @return [Array<AddressRecord>]
      def find_by_prefix(prefix)
        raise NotImplementedError, "#{self.class}#find_by_prefix を実装してください"
      end
    end
  end
end
