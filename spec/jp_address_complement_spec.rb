# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JpAddressComplement do
  before { described_class.reset_configuration! }

  after { described_class.reset_configuration! }

  describe '.configure' do
    it '設定ブロックで repository を注入できる' do
      fake_repo = JpAddressComplement::FakePostalCodeRepository.new
      described_class.configure { |c| c.repository = fake_repo }
      expect(described_class.repository).to eq(fake_repo)
    end
  end

  describe '.search_by_postal_code', :us1 do
    let(:record) do
      JpAddressComplement::AddressRecord.new(
        postal_code: '1000001', pref_code: '13', pref: '東京都',
        city: '千代田区', town: '千代田', kana_pref: nil,
        kana_city: nil, kana_town: nil, has_alias: false,
        is_partial: false, is_large_office: false
      )
    end

    before do
      fake_repo = JpAddressComplement::FakePostalCodeRepository.new([record])
      described_class.configure { |c| c.repository = fake_repo }
    end

    it '郵便番号から住所レコードを返す' do
      results = described_class.search_by_postal_code('1000001')
      expect(results).to eq([record])
    end

    it '存在しない郵便番号では空配列を返す' do
      expect(described_class.search_by_postal_code('0000000')).to eq([])
    end

    it 'nil 入力では空配列を返す' do
      expect(described_class.search_by_postal_code(nil)).to eq([])
    end
  end

  describe '.search_by_postal_code_prefix', :us2 do
    let(:record) do
      JpAddressComplement::AddressRecord.new(
        postal_code: '1000001', pref_code: '13', pref: '東京都',
        city: '千代田区', town: '千代田', kana_pref: nil,
        kana_city: nil, kana_town: nil, has_alias: false,
        is_partial: false, is_large_office: false
      )
    end

    before do
      fake_repo = JpAddressComplement::FakePostalCodeRepository.new([record])
      described_class.configure { |c| c.repository = fake_repo }
    end

    it '先頭4桁以上で候補を返す' do
      results = described_class.search_by_postal_code_prefix('1000')
      expect(results).to include(record)
    end

    it '先頭3桁以下では空配列を返す' do
      expect(described_class.search_by_postal_code_prefix('100')).to eq([])
    end
  end

  describe '.valid_combination?', :us3 do
    let(:record) do
      JpAddressComplement::AddressRecord.new(
        postal_code: '1000001', pref_code: '13', pref: '東京都',
        city: '千代田区', town: '千代田', kana_pref: nil,
        kana_city: nil, kana_town: nil, has_alias: false,
        is_partial: false, is_large_office: false
      )
    end

    before do
      fake_repo = JpAddressComplement::FakePostalCodeRepository.new([record])
      described_class.configure { |c| c.repository = fake_repo }
    end

    it '整合する場合は true を返す' do
      expect(described_class.valid_combination?('1000001', '東京都千代田区千代田1-1')).to be true
    end

    it '不整合の場合は false を返す' do
      expect(described_class.valid_combination?('1000001', '大阪府大阪市北区')).to be false
    end
  end

  describe '.search_postal_codes_by_address', :us3 do
    let(:record) do
      JpAddressComplement::AddressRecord.new(
        postal_code: '1000001', pref_code: '13', pref: '東京都',
        city: '千代田区', town: '千代田', kana_pref: nil,
        kana_city: nil, kana_town: nil, has_alias: false,
        is_partial: false, is_large_office: false
      )
    end

    before do
      fake_repo = JpAddressComplement::FakePostalCodeRepository.new([record])
      described_class.configure { |c| c.repository = fake_repo }
    end

    it '都道府県・市区町村・町域から [郵便番号, AddressRecord] の配列を返す' do
      results = described_class.search_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代田')

      expect(results).to be_an(Array).and(satisfy(&:any?))
      expect(results).to all(satisfy { |pair|
        pair.is_a?(Array) && pair.size == 2 &&
          pair[0].is_a?(String) && pair[1].is_a?(JpAddressComplement::AddressRecord)
      })
      expect(results.map(&:first)).to include('1000001')
      expect(results.find { |code, _r| code == '1000001' }[1].town).to eq('千代田')
    end

    it '町域を省略した場合は都道府県・市区町村に属する候補を返す' do
      results = described_class.search_postal_codes_by_address(pref: '東京都', city: '千代田区')
      expect(results.map(&:first)).to include('1000001')
    end

    it '該当なし・pref/city が nil/空の場合は空配列を返す' do
      expect(described_class.search_postal_codes_by_address(pref: '東京都', city: '存在しない区')).to eq([])
      expect(described_class.search_postal_codes_by_address(pref: '東京都', city: nil)).to eq([])
      expect(described_class.search_postal_codes_by_address(pref: nil, city: '千代田区')).to eq([])
    end
  end
end
