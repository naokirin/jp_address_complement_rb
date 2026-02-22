# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JpAddressComplement::Searcher do
  subject(:searcher) { described_class.new(fake_repo) }

  let(:tokyo_record) do
    JpAddressComplement::AddressRecord.new(
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
    )
  end

  let(:osaka_record) do
    JpAddressComplement::AddressRecord.new(
      postal_code: '5300001',
      pref_code: '27',
      pref: '大阪府',
      city: '大阪市北区',
      town: '梅田',
      kana_pref: 'オオサカフ',
      kana_city: 'オオサカシキタク',
      kana_town: 'ウメダ',
      has_alias: false,
      is_partial: false,
      is_large_office: false
    )
  end

  let(:nil_town_record) do
    JpAddressComplement::AddressRecord.new(
      postal_code: '1060032',
      pref_code: '13',
      pref: '東京都',
      city: '港区',
      town: nil,
      kana_pref: nil,
      kana_city: nil,
      kana_town: nil,
      has_alias: false,
      is_partial: false,
      is_large_office: true
    )
  end

  let(:fake_repo) do
    JpAddressComplement::FakePostalCodeRepository.new([tokyo_record, osaka_record, nil_town_record])
  end

  describe '#search_by_postal_code', :us1 do
    context 'when 有効な7桁郵便番号の場合' do
      it 'AddressRecord の配列を返す' do
        results = searcher.search_by_postal_code('1000001')
        expect(results).to eq([tokyo_record])
      end
    end

    context 'when ハイフンあり郵便番号の場合' do
      it 'ハイフンを除去して検索する' do
        results = searcher.search_by_postal_code('100-0001')
        expect(results).to eq([tokyo_record])
      end
    end

    context 'when 〒記号付き郵便番号の場合' do
      it '〒を除去して検索する' do
        results = searcher.search_by_postal_code('〒100-0001')
        expect(results).to eq([tokyo_record])
      end
    end

    context 'when 存在しない郵便番号の場合' do
      it '空配列を返す' do
        expect(searcher.search_by_postal_code('0000000')).to eq([])
      end
    end

    context 'when nil の場合' do
      it '空配列を返す' do
        expect(searcher.search_by_postal_code(nil)).to eq([])
      end
    end

    context 'when 空文字の場合' do
      it '空配列を返す' do
        expect(searcher.search_by_postal_code('')).to eq([])
      end
    end

    context 'when 不正な入力の場合' do
      it '空配列を返す' do
        expect(searcher.search_by_postal_code('abc')).to eq([])
      end
    end
  end

  describe '#search_by_postal_code_prefix', :us2 do
    context 'when 先頭4桁以上の場合' do
      it '一致する AddressRecord の配列を返す' do
        results = searcher.search_by_postal_code_prefix('1000')
        expect(results).to include(tokyo_record)
      end
    end

    context 'when 先頭3桁以下の場合' do
      it '空配列を返す（過大結果防止）' do
        expect(searcher.search_by_postal_code_prefix('100')).to eq([])
      end
    end

    context 'when nil の場合' do
      it '空配列を返す' do
        expect(searcher.search_by_postal_code_prefix(nil)).to eq([])
      end
    end
  end

  describe '#valid_combination?', :us3 do
    context 'when 郵便番号と住所が一致する場合' do
      it 'true を返す' do
        expect(searcher.valid_combination?('1000001', '東京都千代田区千代田1-1')).to be true
      end
    end

    context 'when 番地なしでも一致する場合' do
      it 'true を返す' do
        expect(searcher.valid_combination?('1000001', '東京都千代田区千代田')).to be true
      end
    end

    context 'when 郵便番号と住所が一致しない場合' do
      it 'false を返す' do
        expect(searcher.valid_combination?('1000001', '大阪府大阪市北区梅田')).to be false
      end
    end

    context 'when 存在しない郵便番号の場合' do
      it 'false を返す' do
        expect(searcher.valid_combination?('0000000', '東京都千代田区千代田')).to be false
      end
    end

    context 'when nil の場合' do
      it 'false を返す' do
        expect(searcher.valid_combination?(nil, '東京都千代田区千代田')).to be false
      end
    end

    context 'when town が nil のレコードの場合' do
      it 'NoMethodError を発生させず false を返す' do
        expect(searcher.valid_combination?('1060032', '東京都港区')).to be true
      end
    end
  end

  describe '#search_postal_codes_by_address', :us3 do
    context 'when pref・city・town を指定した場合' do
      it '[郵便番号, AddressRecord] の配列を返す' do
        results = searcher.search_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代田')

        expect(results).to be_an(Array).and(satisfy(&:any?))
        expect(results).to all(satisfy { |pair|
          pair.is_a?(Array) && pair.size == 2 &&
            pair[0].is_a?(String) && pair[1].is_a?(JpAddressComplement::AddressRecord)
        })
        expect(results.map(&:first)).to include('1000001')
        expect(results.find { |code, _r| code == '1000001' }[1].town).to eq('千代田')
      end
    end

    context 'when 町域を前方一致で指定した場合' do
      it '町域が前方一致する候補を [郵便番号, AddressRecord] の配列で返す' do
        results = searcher.search_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代')
        expect(results.map(&:first)).to include('1000001')
        expect(results.find { |code, _r| code == '1000001' }[1].town).to eq('千代田')
      end
    end

    context 'when pref・city のみ（town 省略）の場合' do
      it 'その都道府県・市区町村に属する [郵便番号, AddressRecord] の配列を返す' do
        results = searcher.search_postal_codes_by_address(pref: '東京都', city: '千代田区')
        expect(results.map(&:first)).to include('1000001')
      end
    end

    context 'when 該当する住所が存在しない場合' do
      it '空配列を返す' do
        expect(searcher.search_postal_codes_by_address(pref: '東京都', city: '存在しない区')).to eq([])
      end
    end

    context 'when pref または city が nil/空の場合' do
      it '例外を発生させず空配列を返す' do
        expect(searcher.search_postal_codes_by_address(pref: '東京都', city: nil)).to eq([])
        expect(searcher.search_postal_codes_by_address(pref: nil, city: '千代田区')).to eq([])
        expect(searcher.search_postal_codes_by_address(pref: '東京都', city: '')).to eq([])
      end
    end
  end
end
