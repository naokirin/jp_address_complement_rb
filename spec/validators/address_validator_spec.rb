# frozen_string_literal: true

require 'spec_helper'
require 'active_model'
require 'jp_address_complement/validators/address_validator'

class ValidatableModel
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :postal_code, :address

  validates :postal_code, :address, presence: true
  validates_with JpAddressComplement::AddressValidator,
                 postal_code_field: :postal_code,
                 address_field: :address

  def initialize(postal_code: nil, address: nil)
    @postal_code = postal_code
    @address = address
  end
end

RSpec.describe JpAddressComplement::AddressValidator, :us4 do
  let(:tokyo_record) do
    JpAddressComplement::AddressRecord.new(
      postal_code: '1000001', pref_code: '13', pref: '東京都',
      city: '千代田区', town: '千代田', kana_pref: nil,
      kana_city: nil, kana_town: nil, has_alias: false,
      is_partial: false, is_large_office: false
    )
  end

  let(:fake_repo) { JpAddressComplement::FakePostalCodeRepository.new([tokyo_record]) }

  before do
    JpAddressComplement.configure { |c| c.repository = fake_repo }
  end

  after { JpAddressComplement.reset_configuration! }

  context 'when 郵便番号と住所が整合する場合' do
    subject(:model) { ValidatableModel.new(postal_code: '1000001', address: '東京都千代田区千代田1-1') }

    it 'バリデーションが通る' do
      expect(model).to be_valid
    end
  end

  context 'when 郵便番号と住所が不整合の場合' do
    subject(:model) { ValidatableModel.new(postal_code: '1000001', address: '大阪府大阪市北区梅田') }

    it 'バリデーションエラーになる' do
      expect(model).not_to be_valid
      expect(model.errors[:address]).not_to be_empty
    end
  end

  context 'when 郵便番号が空の場合' do
    subject(:model) { ValidatableModel.new(postal_code: nil, address: '東京都千代田区千代田') }

    it 'address バリデーターでは検証しない（presence チェックに委譲）' do
      model.valid?
      expect(model.errors[:postal_code]).to include("can't be blank")
    end
  end
end
