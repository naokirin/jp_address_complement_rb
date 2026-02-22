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
end
