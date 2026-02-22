# frozen_string_literal: true
# rbs_inline: enabled

require_relative 'postal_code_repository'
require_relative '../address_record'

module JpAddressComplement
  module Repositories
    # ActiveRecord を使用した PostalCodeRepository の実装
    # Rails 環境向けにバンドルされる標準実装
    class ActiveRecordPostalCodeRepository < PostalCodeRepository
      # @rbs (String code) -> Array[AddressRecord]
      # @param code [String] 正規化済み7桁郵便番号
      # @return [Array<AddressRecord>]
      def find_by_code(code)
        postal_code_model.where(postal_code: code).map { |ar| to_record(ar) } # steep:ignore
      end

      # @rbs (String prefix) -> Array[AddressRecord]
      # @param prefix [String] 4桁以上の郵便番号プレフィックス
      # @return [Array<AddressRecord>]
      def find_by_prefix(prefix)
        postal_code_model.where('postal_code LIKE ?', "#{prefix}%").map { |ar| to_record(ar) } # steep:ignore
      end

      # @rbs (String? pref, String? city, String? town) -> Array[String]
      def find_postal_codes_by_address(pref:, city:, town: nil)
        return [] if pref.nil? || pref.to_s.strip.empty?
        return [] if city.nil? || city.to_s.strip.empty?

        relation = postal_code_model.where(pref: pref, city: city)
        relation = relation.where(town: town) if town.present?
        relation.distinct.pluck(:postal_code)
      end

      private

      # @rbs () -> singleton(PostalCode)
      def postal_code_model
        JpAddressComplement::PostalCode
      end

      # ActiveRecord の動的属性のため Steep の型が不足する。理由明記で抑制（research §7）
      # @rbs (untyped postal_code_ar) -> AddressRecord
      def to_record(postal_code_ar)
        AddressRecord.new(
          postal_code: postal_code_ar.postal_code,
          pref_code: postal_code_ar.pref_code,
          pref: postal_code_ar.pref,
          city: postal_code_ar.city,
          town: postal_code_ar.town,
          kana_pref: postal_code_ar.kana_pref,
          kana_city: postal_code_ar.kana_city,
          kana_town: postal_code_ar.kana_town,
          has_alias: postal_code_ar.has_alias,
          is_partial: postal_code_ar.is_partial,
          is_large_office: postal_code_ar.is_large_office
        )
      end
    end
  end
end
