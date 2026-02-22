# frozen_string_literal: true

require 'spec_helper'
require 'jp_address_complement/repositories/active_record_postal_code_repository'
require 'jp_address_complement/models/postal_code'

RSpec.describe JpAddressComplement::Repositories::ActiveRecordPostalCodeRepository, :db do
  subject(:repo) { described_class.new }

  let(:record_attrs) do
    {
      postal_code: '1000001',
      pref_code: '13',
      pref: '\u6771\u4eac\u90fd',
      city: '\u5343\u4ee3\u7530\u533a',
      town: '\u5343\u4ee3\u7530',
      kana_pref: '\u30c8\u30a6\u30ad\u30e7\u30a6\u30c8',
      kana_city: '\u30c1\u30e8\u30c0\u30af',
      kana_town: '\u30c1\u30e8\u30c0',
      has_alias: false,
      is_partial: false,
      is_large_office: false
    }
  end

  before do
    JpAddressComplement::PostalCode.create!(record_attrs)
  end

  describe '#find_by_code', :us1 do
    context 'when \u4e00\u81f4\u3059\u308b\u90f5\u4fbf\u756a\u53f7\u304c\u3042\u308b\u5834\u5408' do
      it 'AddressRecord \u306e\u914d\u5217\u3092\u8fd4\u3059' do
        results = repo.find_by_code('1000001')
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first).to be_a(JpAddressComplement::AddressRecord)
        expect(results.first.postal_code).to eq('1000001')
        expect(results.first.pref).to eq('\u6771\u4eac\u90fd')
      end
    end

    context 'when \u4e00\u81f4\u3057\u306a\u3044\u90f5\u4fbf\u756a\u53f7\u306e\u5834\u5408' do
      it '\u7a7a\u914d\u5217\u3092\u8fd4\u3059' do
        expect(repo.find_by_code('9999999')).to eq([])
      end
    end
  end

  describe '#find_by_prefix', :us2 do
    before do
      JpAddressComplement::PostalCode.create!(
        record_attrs.merge(postal_code: '1000002', town: '\u4e38\u306e\u5185\uff081\u4e01\u76ee\uff09')
      )
    end

    context 'when \u5148\u982d4\u6841\u304c\u4e00\u81f4\u3059\u308b\u30ec\u30b3\u30fc\u30c9\u304c\u3042\u308b\u5834\u5408' do
      it '\u8907\u6570\u306e AddressRecord \u3092\u8fd4\u3059' do
        results = repo.find_by_prefix('1000')
        expect(results.size).to be >= 2
        expect(results).to all(be_a(JpAddressComplement::AddressRecord))
      end
    end

    context 'when \u4e00\u81f4\u3057\u306a\u3044\u30d7\u30ec\u30d5\u30a3\u30c3\u30af\u30b9\u306e\u5834\u5408' do
      it '\u7a7a\u914d\u5217\u3092\u8fd4\u3059' do
        expect(repo.find_by_prefix('9999')).to eq([])
      end
    end

    context 'when 7\u6841\u5b8c\u5168\u4e00\u81f4\u306e\u5834\u5408' do
      it '1\u4ef6\u306e\u307f\u8fd4\u3059' do
        results = repo.find_by_prefix('1000001')
        expect(results.size).to eq(1)
        expect(results.first.postal_code).to eq('1000001')
      end
    end
  end
end
