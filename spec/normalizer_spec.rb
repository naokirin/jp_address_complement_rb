# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JpAddressComplement::Normalizer do
  describe '.normalize_postal_code' do
    subject(:result) { described_class.normalize_postal_code(input) }

    context 'when 正常な7桁郵便番号の場合' do
      let(:input) { '1000001' }

      it 'そのまま返す' do
        expect(result).to eq('1000001')
      end
    end

    context 'when ハイフンあり郵便番号の場合' do
      let(:input) { '100-0001' }

      it 'ハイフンを除去して返す' do
        expect(result).to eq('1000001')
      end
    end

    context 'when 〒記号付きの場合' do
      let(:input) { '〒100-0001' }

      it '〒とハイフンを除去して返す' do
        expect(result).to eq('1000001')
      end
    end

    context 'when 全角数字の場合' do
      let(:input) { '１００００0１' }

      it '半角数字に変換して返す' do
        expect(result).to eq('1000001')
      end
    end

    context 'when 全角数字・ハイフンあり・〒付きの場合' do
      let(:input) { '〒１００-００01' }

      it '正規化して7桁の数字を返す' do
        expect(result).to eq('1000001')
      end
    end

    context 'when nil の場合' do
      let(:input) { nil }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    context 'when 空文字の場合' do
      let(:input) { '' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    context 'when 不正な文字を含む場合' do
      let(:input) { 'abc-defg' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    context 'when 桁数不足の場合' do
      let(:input) { '12345' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    context 'when 8桁以上の場合' do
      let(:input) { '12345678' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end
  end

  describe '.normalize_prefix' do
    subject(:result) { described_class.normalize_prefix(input) }

    context 'when 4桁以上の数字の場合' do
      let(:input) { '1000' }

      it 'そのまま返す' do
        expect(result).to eq('1000')
      end
    end

    context 'when 先頭3桁以下の場合' do
      let(:input) { '100' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    context 'when 全角数字の場合' do
      let(:input) { '１０００' }

      it '半角に変換して返す' do
        expect(result).to eq('1000')
      end
    end

    context 'when nil の場合' do
      let(:input) { nil }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end
  end
end
