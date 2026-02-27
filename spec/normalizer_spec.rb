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

    # branch coverage: normalize_prefix で normalized.empty? が true になるケース
    context 'when 〒やハイフン・空白のみで正規化後に空になる場合' do
      let(:input) { '〒　－ー' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    context 'when 〒のみで正規化後に空になる場合' do
      let(:input) { '〒' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end

    # branch coverage: normalize_prefix で数字以外が含まれるケース
    context 'when 数字以外の文字を含む場合' do
      let(:input) { '100a' }

      it 'nil を返す' do
        expect(result).to be_nil
      end
    end
  end

  describe '.normalize_town_for_display' do
    it '全角括弧（）で囲まれた部分を除いた町域名を返す（漢字）' do
      expect(described_class.normalize_town_for_display('大通西（１〜１９丁目）')).to eq('大通西')
      expect(described_class.normalize_town_for_display('常盤（その他）')).to eq('常盤')
      expect(described_class.normalize_town_for_display('常盤（１〜１３１番地）')).to eq('常盤')
      expect(described_class.normalize_town_for_display('藤野（４００、４００−２番地）')).to eq('藤野')
      expect(described_class.normalize_town_for_display('丸の内（１丁目）')).to eq('丸の内')
    end

    it '全角括弧（）で囲まれた部分を除いた町域名を返す（カナ）' do
      expect(described_class.normalize_town_for_display('藤野（その他）')).to eq('藤野')
      expect(described_class.normalize_town_for_display('マルノウチ（１チョウメ）')).to eq('マルノウチ')
      expect(described_class.normalize_town_for_display('トキワ（ソノタ）')).to eq('トキワ')
    end

    it '「以下に掲載がない場合」を除去する' do
      expect(described_class.normalize_town_for_display('以下に掲載がない場合')).to be_nil
      expect(described_class.normalize_town_for_display('某某町以下に掲載がない場合')).to eq('某某町')
    end

    it '「イカニケイサイガナイバアイ」を除去する' do
      expect(described_class.normalize_town_for_display('イカニケイサイガナイバアイ')).to be_nil
    end

    it '括弧を含まない通常の町域名はそのまま返す' do
      expect(described_class.normalize_town_for_display('千代田')).to eq('千代田')
      expect(described_class.normalize_town_for_display('渋谷')).to eq('渋谷')
    end

    it 'nil のとき nil を返す' do
      expect(described_class.normalize_town_for_display(nil)).to be_nil
    end

    it '空文字のとき nil を返す' do
      expect(described_class.normalize_town_for_display('')).to be_nil
    end
  end
end
