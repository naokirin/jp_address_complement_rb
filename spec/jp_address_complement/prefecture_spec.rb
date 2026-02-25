# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JpAddressComplement::Prefecture do
  describe '.name_from_code' do
    context 'when 有効な都道府県コード（文字列）の場合' do
      it '対応する都道府県名を返す' do
        expect(described_class.name_from_code('13')).to eq('東京都')
        expect(described_class.name_from_code('01')).to eq('北海道')
      end
    end

    context 'when 有効な都道府県コード（数値）の場合' do
      it '対応する都道府県名を返す' do
        expect(described_class.name_from_code(13)).to eq('東京都')
        expect(described_class.name_from_code(1)).to eq('北海道')
      end
    end

    context 'when ゼロパディングされた文字列の場合' do
      it '対応する都道府県名を返す' do
        expect(described_class.name_from_code('01')).to eq('北海道')
      end
    end

    context 'when 存在しないコードまたは範囲外の場合' do
      it 'nil を返し、例外は発生しない' do
        expect(described_class.name_from_code(99)).to be_nil
        expect(described_class.name_from_code('99')).to be_nil
        expect(described_class.name_from_code(0)).to be_nil
        expect(described_class.name_from_code(48)).to be_nil
      end
    end

    context 'when nil や空文字の場合' do
      it 'nil を返し、例外は発生しない' do
        expect(described_class.name_from_code(nil)).to be_nil
        expect(described_class.name_from_code('')).to be_nil
      end
    end

    # branch coverage: normalize_code の case で Integer/String 以外（else）を通るケース
    context 'when Integer でも String でもない型を渡した場合' do
      it 'nil を返す' do
        expect(described_class.name_from_code(13.0)).to be_nil
      end
    end

    context 'when 47都道府県すべてのコード⇔名称' do
      it '代表例で正しく動作する' do
        expect(described_class.name_from_code('01')).to eq('北海道')
        expect(described_class.name_from_code('13')).to eq('東京都')
        expect(described_class.name_from_code('27')).to eq('大阪府')
        expect(described_class.name_from_code('47')).to eq('沖縄県')
      end

      it '全47件でコードから名称が取得できる' do
        (1..47).each do |code|
          name = described_class.name_from_code(code)
          expect(name).not_to be_nil, "code=#{code} should return a name"
          expect(name).to be_a(String)
          expect(name).not_to be_empty
        end
      end
    end
  end

  describe '.code_from_name' do
    context 'when 正式な都道府県名の場合' do
      it '対応する2桁のコード文字列を返す' do
        expect(described_class.code_from_name('東京都')).to eq('13')
        expect(described_class.code_from_name('北海道')).to eq('01')
        expect(described_class.code_from_name('大阪府')).to eq('27')
      end
    end

    context 'when 省略表記や正式名称以外の場合' do
      it 'nil を返す' do
        expect(described_class.code_from_name('東京')).to be_nil
        expect(described_class.code_from_name('北海')).to be_nil
        expect(described_class.code_from_name('不明')).to be_nil
      end
    end

    context 'when 存在しない都道府県名や曖昧な文字列の場合' do
      it 'nil を返し、例外は発生しない' do
        expect(described_class.code_from_name('')).to be_nil
        expect(described_class.code_from_name('   ')).to be_nil
      end
    end

    context 'when nil や空文字の場合' do
      it 'nil を返し、例外は発生しない' do
        expect(described_class.code_from_name(nil)).to be_nil
        expect(described_class.code_from_name('')).to be_nil
      end
    end

    context 'when 47都道府県すべて名称→コード' do
      it '代表例で正しく動作する' do
        expect(described_class.code_from_name('北海道')).to eq('01')
        expect(described_class.code_from_name('東京都')).to eq('13')
        expect(described_class.code_from_name('沖縄県')).to eq('47')
      end

      it '全47件で名称からコードが取得できる' do
        described_class::CODE_TO_NAME.each do |code, name|
          expect(described_class.code_from_name(name)).to eq(code), "name=#{name} should return #{code}"
        end
      end
    end
  end
end
