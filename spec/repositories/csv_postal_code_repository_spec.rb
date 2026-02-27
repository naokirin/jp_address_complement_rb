#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'jp_address_complement/repositories/csv_postal_code_repository'

RSpec.describe JpAddressComplement::Repositories::CsvPostalCodeRepository do
  # KEN_ALL 形式の1行を表す配列（UTF-8 で書き出す）
  let(:row_tokyo) do
    %w[13101 100 1000001 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0]
  end

  let(:row_marunouchi) do
    %w[13101 100 1000002 トウキョウト チヨダク マルノウチ 東京都 千代田区 丸の内 0 0 0 0 0 0]
  end

  # 複数行の KEN_ALL 形式 CSV を UTF-8 で作成する
  def build_utf8_csv(rows)
    tf = Tempfile.new(['utf_ken_all_repo', '.csv'])
    tf.binmode
    Array(rows).each do |row|
      line = "#{Array(row).join(',')}\r\n"
      tf.write(line)
    end
    tf.close
    tf
  end

  describe 'CSV パス検証' do
    it 'CSV パスが空文字のとき初回検索で Error を発生させる' do
      repo = described_class.new('')
      expect { repo.find_by_code('1000001') }.to raise_error(JpAddressComplement::Error, 'CSV ファイルが指定されていません')
    end

    it 'CSV ファイルが存在しないとき初回検索で Error を発生させる' do
      repo = described_class.new('/nonexistent/ken_all.csv')
      expect { repo.find_by_code('1000001') }.to raise_error(JpAddressComplement::Error, /CSV ファイルが見つかりません/)
    end

    it 'CSV のエンコーディングが不正なとき初回検索で Error を発生させる' do
      # UTF-8 として解釈すると不正なバイト列を含むファイル
      tf = Tempfile.new(['invalid_enc', '.csv'])
      tf.binmode
      tf.write("\xFF\xFE\x00\x00") # UTF-32LE BOM など、UTF-8 では不正
      tf.close
      repo = described_class.new(tf.path)
      expect { repo.find_by_code('1000001') }.to raise_error(JpAddressComplement::Error, /エンコーディング/)
    end

    it 'CSV 読み込みで Encoding エラーが発生した場合は rescue して Error を発生させる' do
      csv = build_utf8_csv([row_tokyo])
      repo = described_class.new(csv.path)
      allow(CSV).to receive(:foreach).and_raise(Encoding::UndefinedConversionError.new)
      expect { repo.find_by_code('1000001') }.to raise_error(JpAddressComplement::Error, /エンコーディング/)
    end

    it 'CSV 読み込みで ENOENT が発生した場合は rescue して Error を発生させる' do
      csv = build_utf8_csv([row_tokyo])
      repo = described_class.new(csv.path)
      allow(CSV).to receive(:foreach).and_raise(Errno::ENOENT)
      expect { repo.find_by_code('1000001') }.to raise_error(JpAddressComplement::Error, /見つかりません/)
    end
  end

  describe '#find_by_code', :us1 do
    it '郵便番号完全一致で AddressRecord の配列を返す' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_by_code('1000001')
      expect(results).to be_an(Array).and have_attributes(size: 1)
      record = results.first
      expect(record).to be_a(JpAddressComplement::AddressRecord).and(
        have_attributes(postal_code: '1000001', pref: '東京都', city: '千代田区', town: '千代田')
      )
    end

    it '存在しない郵便番号では空配列を返す' do
      csv = build_utf8_csv([row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_by_code('9999999')).to eq([])
    end
  end

  describe '#find_by_prefix', :us2 do
    it '先頭4桁以上のプレフィックスで前方一致検索できる' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_by_prefix('1000')
      expect(results.map(&:postal_code)).to contain_exactly('1000001', '1000002')
    end

    it '一致しないプレフィックスでは空配列を返す' do
      csv = build_utf8_csv([row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_by_prefix('9999')).to eq([])
    end
  end

  describe '#find_postal_codes_by_address', :us3 do
    it 'pref + city + town で該当レコードを返す' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代田')
      expect(results).to all(be_a(JpAddressComplement::AddressRecord))
      expect(results.map(&:postal_code)).to contain_exactly('1000001')
    end

    it '町域を前方一致で検索できる' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '千代')
      expect(results.map(&:postal_code)).to include('1000001')
    end

    it 'town を省略した場合は pref + city に属する全レコードを返す' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)

      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: nil)
      expect(results.map(&:postal_code)).to contain_exactly('1000001', '1000002')
    end

    it '入力不十分（pref または city が空）の場合は空配列を返す' do
      csv = build_utf8_csv([row_tokyo])
      repo = described_class.new(csv.path)

      expect(repo.find_postal_codes_by_address(pref: '東京都', city: nil)).to eq([])
      expect(repo.find_postal_codes_by_address(pref: nil, city: '千代田区')).to eq([])
      expect(repo.find_postal_codes_by_address(pref: '東京都', city: '')).to eq([])
    end

    it '該当する住所が存在しない場合は空配列を返す' do
      csv = build_utf8_csv([row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_postal_codes_by_address(pref: '東京都', city: '存在しない区')).to eq([])
    end

    it '町域を指定したが前方一致するレコードが無い場合は空配列を返す' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)
      expect(repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '存在しない町')).to eq([])
    end

    it '町域に空文字を指定した場合は pref + city に属する全レコードを返す' do
      csv = build_utf8_csv([row_tokyo, row_marunouchi])
      repo = described_class.new(csv.path)
      results = repo.find_postal_codes_by_address(pref: '東京都', city: '千代田区', town: '')
      expect(results.map(&:postal_code)).to contain_exactly('1000001', '1000002')
    end
  end

  describe '無効行のスキップ' do
    it '必須列不足の行はスキップし有効行のみ読み込む' do
      short_row = %w[13101 100] # 郵便番号・都道府県・市区町村なし
      csv = build_utf8_csv([short_row, row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_by_code('1000001').size).to eq(1)
    end

    it '郵便番号が7桁でない行はスキップする' do
      invalid_postal_row = %w[13101 100 12345 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0]
      csv = build_utf8_csv([invalid_postal_row, row_tokyo])
      repo = described_class.new(csv.path)
      expect(repo.find_by_code('1000001').size).to eq(1)
      expect(repo.find_by_code('12345')).to eq([])
    end

    it '複数町域フラグ等が 1 の行も正しく読み込む' do
      # has_alias=1, is_partial=1, is_large_office=1 の行（KEN_ALL 形式の列14〜16は 0 0 0 の次がフラグ）
      row_with_flags = %w[13101 100 1000003 トウキョウト チヨダク ヒトツブ 東京都 千代田区 一ツ橋 1 0 0 1 1 0]
      csv = build_utf8_csv([row_with_flags])
      repo = described_class.new(csv.path)
      record = repo.find_by_code('1000003').first
      expect(record).not_to be_nil
      expect(record.has_alias).to be true
      expect(record.is_partial).to be true
      expect(record.is_large_office).to be true
    end
  end
end
