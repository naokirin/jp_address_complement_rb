# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'tempfile'
require 'jp_address_complement/importers/csv_importer'
require 'jp_address_complement/models/postal_code'

RSpec.describe JpAddressComplement::Importers::CsvImporter, :db do
  let(:valid_csv_row) do
    # KEN_ALL.CSV の列順: 全国地方公共団体コード, (旧)郵便番号, 郵便番号,
    # 都道府県名カナ, 市区町村名カナ, 町域名カナ, 都道府県名, 市区町村名, 町域名,
    # 複数町域フラグ, 小字あり, 丁目フラグ, 複数町域フラグ2, 大規模事業所フラグ, 廃止フラグ
    %w[13101 100 1000001 トウキョウト チヨダク チヨダ
       東京都 千代田区 千代田 0 0 0 0 0 0]
  end

  let(:valid_sjis_csv) do
    tf = Tempfile.new(['ken_all', '.csv'])
    tf.binmode
    row = "#{valid_csv_row.join(',')}\r\n"
    tf.write(row.encode('Windows-31J', invalid: :replace, undef: :replace))
    tf.close
    tf
  end

  describe '#import' do
    context 'when 有効な Shift_JIS CSV の場合' do
      it 'UTF-8 に変換してレコードをインポートする' do
        described_class.new(valid_sjis_csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)
        record = JpAddressComplement::PostalCode.first
        expect(record.postal_code).to eq('1000001')
        expect(record.pref).to eq('東京都')
      end

      it '同じ CSV を2回インポートしても冪等（重複しない）' do
        importer = described_class.new(valid_sjis_csv.path)
        importer.import
        importer.import
        expect(JpAddressComplement::PostalCode.count).to eq(1)
      end
    end

    context 'when CSV ファイルが存在しない場合' do
      it 'ImportError を発生させる' do
        expect do
          described_class.new('/nonexistent/path/to/ken_all.csv').import
        end.to raise_error(JpAddressComplement::ImportError)
      end
    end
  end
end
