# frozen_string_literal: true

require 'active_model'

module JpAddressComplement
  # ActiveModel::Validator を継承した郵便番号・住所整合性バリデーター
  #
  # @example
  #   class User
  #     include ActiveModel::Validations
  #     validates_with JpAddressComplement::AddressValidator,
  #                    postal_code_field: :postal_code,
  #                    address_field: :full_address
  #   end
  class AddressValidator < ActiveModel::Validator
    def validate(record)
      postal_code = record.public_send(postal_code_field)
      address = record.public_send(address_field)

      return if postal_code.blank? || address.blank?

      return if JpAddressComplement.valid_combination?(postal_code, address)

      record.errors.add(address_field, :invalid_combination,
                        message: 'と郵便番号の組み合わせが正しくありません')
    end

    private

    def postal_code_field
      options.fetch(:postal_code_field, :postal_code)
    end

    def address_field
      options.fetch(:address_field, :address)
    end
  end
end
