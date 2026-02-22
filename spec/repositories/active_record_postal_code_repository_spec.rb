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
      pref: '東京都',
      city: '千代田区',
      town: '千代田',
      kana_pref: 'トウキョウト',
      kana_city: 'チヨダク',
      kana_town: 'チヨダ',
      has_alias: false,
      is_partial: false,
      is_large_office: false
    }
  end

  before do
    JpAddressComplement::PostalCode.create!(record_attrs)
  end

  describe '#find_by_code', :us1 do
    context 'when 一致する郵便番号がある場合' do
      it 'AddressRecord の配列を返す' do
        results = repo.find_by_code('1000001')
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first).to be_a(JpAddressComplement::AddressRecord)
        expect(results.first.postal_code).to eq('1000001')
        expect(results.first.pref).to eq('東京都')
      end
    end

    context 'when 一致しない郵便番号の場合' do
      it '空配列を返す' do
        expect(repo.find_by_code('9999999')).to eq([])
      end
    end
  end

  describe '#find_by_prefix', :us2 do
    before do
      JpAddressComplement::PostalCode.create!(
        record_attrs.merge(postal_code: '1000002', town: '丸の内（１丁目）')
      )
    end

    context 'when 先頭4桁が一致するレコードがある場合' do
      it '複数の AddressRecord を返す' do
        results = repo.find_by_prefix('1000')
        expect(results.size).to be >= 2
        expect(results).to all(be_a(JpAddressComplement::AddressRecord))
      end
    end

    context 'when 一致しないプレフィックスの場合' do
      it '空配列を返す' do
        expect(repo.find_by_prefix('9999')).to eq([])
      end
    end

    context 'when 7桁完全一致の場合' do
      it '1件のみ返す' do
        results = repo.find_by_prefix('1000001')
        expect(results.size).to eq(1)
        expect(results.first.postal_code).to eq('1000001')
      end
    end
  end

  describe '#find_postal_codes_by_address', :us3 do
    context 'when pref + city + town を指定した場合' do
      it '該当する郵便番号の配列を返す（重複除く）' do
        results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代田')
        expect(results).to be_an(Array)
        expect(results).to all(be_a(String))
        expect(results).to include('1000001')
        expect(results.uniq).to eq(results)
      end
    end

    context 'when pref + city のみ（town 省略）の場合' do
      it 'その都道府県・市区町村に属する郵便番号を返す' do
        results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: nil)
        expect(results).to be_an(Array)
        expect(results).to include('1000001')
      end
    end

    context 'when 入力不十分（pref または city が空）の場合' do
      it '空配列を返す' do
        expect(repo.find_postal_codes_by_address(pref: '東京都', city: nil)).to eq([])
        expect(repo.find_postal_codes_by_address(pref: nil, city: '千代田区')).to eq([])
        expect(repo.find_postal_codes_by_address(pref: '東京都', city: '')).to eq([])
      end
    end

    context 'when 該当する住所が存在しない場合' do
      it '空配列を返す' do
        expect(repo.find_postal_codes_by_address(pref: '東京都', city: '存在しない区')).to eq([])
      end
    end
  end
end
