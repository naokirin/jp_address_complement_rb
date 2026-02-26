#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'jp_address_complement/repositories/csv_postal_code_repository'

RSpec.describe JpAddressComplement::Repositories::CsvPostalCodeRepository do
  # KEN_ALL 形式の1行を表す配列（Shift_JIS で書き出す）
  let(:row_tokyo) do
    %w[13101 100 1000001 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0]
  end

  let(:row_marunouchi) do
    %w[13101 100 1000002 トウキョウト チヨダク マルノウチ 東京都 千代田区 丸の内 0 0 0 0 0 0]
  end

  # 複数行の KEN_ALL 形式 CSV を Shift_JIS で作成する
  def build_sjis_csv(rows)
    tf = Tempfile.new(['ken_all_repo', '.csv'])
    tf.binmode
    Array(rows).each do |row|
      line = "#{Array(row).join(',')}\r\n"
      tf.write(line.encode('Windows-31J', invalid: :replace, undef: :replace))
    end
    tf.close
    tf
  end

  describe '#find_by_code', :us1 do
    it '郵便番号完全一致で AddressRecord の配列を返す' do
      csv = build_sjis_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_by_code('1000001')
      expect(results).to be_an(Array).and have_attributes(size: 1)
      record = results.first
      expect(record).to be_a(JpAddressComplement::AddressRecord).and(
        have_attributes(postal_code: '1000001', pref: '東京都', city: '千代田区', town: '千代田')
      )
    end

    it '存在しない郵便番号では空配列を返す' do
      csv = build_sjis_csv([row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_by_code('9999999')).to eq([])
    end
  end

  describe '#find_by_prefix', :us2 do
    it '先頭4桁以上のプレフィックスで前方一致検索できる' do
      csv = build_sjis_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_by_prefix('1000')
      expect(results.map(&:postal_code)).to contain_exactly('1000001', '1000002')
    end

    it '一致しないプレフィックスでは空配列を返す' do
      csv = build_sjis_csv([row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_by_prefix('9999')).to eq([])
    end
  end

  describe '#find_postal_codes_by_address', :us3 do
    it 'pref + city + town で該当レコードを返す' do
      csv = build_sjis_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代田')
      expect(results).to all(be_a(JpAddressComplement::AddressRecord))
      expect(results.map(&:postal_code)).to contain_exactly('1000001')
    end

    it '町域を前方一致で検索できる' do
      csv = build_sjis_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代')
      expect(results.map(&:postal_code)).to include('1000001')
    end

    it 'town を省略した場合は pref + city に属する全レコードを返す' do
      csv = build_sjis_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: nil)
      expect(results.map(&:postal_code)).to contain_exactly('1000001', '1000002')
    end

    it '入力不十分（pref または city が空）の場合は空配列を返す' do
      csv = build_sjis_csv([row_tokyo])
      repo = described_class.new(csv.path)

      expect(repo.find_postal_codes_by_address(pref: '東京都', city: nil)).to eq([])
      expect(repo.find_postal_codes_by_address(pref: nil, city: '千代田区')).to eq([])
      expect(repo.find_postal_codes_by_address(pref: '東京都', city: '')).to eq([])
    end
  end
end
