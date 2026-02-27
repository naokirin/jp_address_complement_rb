# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JpAddressComplement::AddressRecord do
  let(:valid_attrs) do
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

  describe '.new' do
    it 'postal_code・pref_code・pref・city・town を保持する' do
      record = described_class.new(**valid_attrs)
      expect(record.postal_code).to eq('1000001')
      expect(record.pref_code).to eq('13')
      expect(record.pref).to eq('東京都')
      expect(record.city).to eq('千代田区')
      expect(record.town).to eq('千代田')
    end

    it 'kana フィールドを保持する' do
      record = described_class.new(**valid_attrs)
      expect(record.kana_pref).to eq('トウキョウト')
      expect(record.kana_city).to eq('チヨダク')
      expect(record.kana_town).to eq('チヨダ')
    end

    it 'フラグフィールドを保持する' do
      record = described_class.new(**valid_attrs)
      expect(record.has_alias).to be false
      expect(record.is_partial).to be false
      expect(record.is_large_office).to be false
    end

    it 'town が nil のレコードを生成できる（大口事業所等）' do
      record = described_class.new(**valid_attrs, town: nil)
      expect(record.town).to be_nil
    end

    it '不変オブジェクトである' do
      record = described_class.new(**valid_attrs)
      expect(record).to be_frozen
    end
  end

  describe 'equality' do
    it '同じ属性を持つレコードは等しい' do
      record1 = described_class.new(**valid_attrs)
      record2 = described_class.new(**valid_attrs)
      expect(record1).to eq(record2)
    end

    it '異なる属性を持つレコードは等しくない' do
      record1 = described_class.new(**valid_attrs)
      record2 = described_class.new(**valid_attrs, postal_code: '1000002')
      expect(record1).not_to eq(record2)
    end
  end

  describe '#normalized_town' do
    it '括弧内の丁目・番地・その他等を除いた町域名を返す' do
      record = described_class.new(**valid_attrs, town: '大通西（１〜１９丁目）', kana_town: 'オオドオリニシ（１〜１９チョウメ）')
      expect(record.normalized_town).to eq('大通西')
    end

    it '「以下に掲載がない場合」を含む町域からは除去して返す' do
      record = described_class.new(**valid_attrs, town: '以下に掲載がない場合', kana_town: 'イカニケイサイガナイバアイ')
      expect(record.normalized_town).to be_nil
    end

    it '通常の町域名の場合はそのまま返す' do
      record = described_class.new(**valid_attrs)
      expect(record.normalized_town).to eq('千代田')
    end

    it 'town が nil のときは nil を返す' do
      record = described_class.new(**valid_attrs, town: nil, kana_town: nil)
      expect(record.normalized_town).to be_nil
    end
  end

  describe '#normalized_kana_town' do
    it '括弧内のチョウメ・バンチ・ソノタ等を除いた町域カナを返す' do
      record = described_class.new(**valid_attrs, town: '丸の内（１丁目）', kana_town: 'マルノウチ（１チョウメ）')
      expect(record.normalized_kana_town).to eq('マルノウチ')
    end

    it '通常の町域カナの場合はそのまま返す' do
      record = described_class.new(**valid_attrs)
      expect(record.normalized_kana_town).to eq('チヨダ')
    end

    it 'kana_town が nil のときは nil を返す' do
      record = described_class.new(**valid_attrs, town: nil, kana_town: nil)
      expect(record.normalized_kana_town).to be_nil
    end
  end
end
