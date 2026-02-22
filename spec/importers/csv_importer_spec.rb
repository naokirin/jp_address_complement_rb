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
    # 複数町域フラグ, 小字あり, 丁目フラグ, 複数町域フラグ2,
    # 大規模事業所フラグ, 廃止フラグ
    %w[13101 100 1000001 トウキョウト チヨダク チヨダ
       東京都 千代田区 千代田 0 0 0 0 0 0]
  end

  let(:valid_sjis_csv) do
    build_sjis_csv([valid_csv_row])
  end

  let(:row_a) { %w[13101 100 1000001 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0] }
  let(:row_b) { %w[13101 100 1000002 トウキョウト チヨダク マルノウチ 東京都 千代田区 丸の内 0 0 0 0 0 0] }
  let(:row_c) { %w[13101 100 1000003 トウキョウト チヨダク オオテマチ 東京都 千代田区 大手町 0 0 0 0 0 0] }

  # 複数行の KEN_ALL 形式 CSV を Shift_JIS で作成する
  def build_sjis_csv(rows)
    tf = Tempfile.new(['ken_all', '.csv'])
    tf.binmode
    rows.each do |row|
      line = "#{Array(row).join(',')}\r\n"
      tf.write(line.encode('Windows-31J', invalid: :replace, undef: :replace))
    end
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

    # --- 003: 消えたレコード削除 (US1) ---
    context 'when 新CSVに含まれないレコードがある場合（T004）' do
      it '今回のCSVにないレコードをストアから削除する' do
        csv_abc = build_sjis_csv([row_a, row_b, row_c])
        described_class.new(csv_abc.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(3)

        csv_ac = build_sjis_csv([row_a, row_c])
        described_class.new(csv_ac.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(JpAddressComplement::PostalCode.pluck(:postal_code, :town)).not_to include(%w[1000002 丸の内])
      end
    end

    context 'when 空CSV（有効行0件）の場合（T005）' do
      it 'ImportError を発生させ、既存データを変更しない' do
        described_class.new(valid_sjis_csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)

        empty_csv = build_sjis_csv([])
        expect do
          described_class.new(empty_csv.path).import
        end.to raise_error(JpAddressComplement::ImportError)
        expect(JpAddressComplement::PostalCode.count).to eq(1)
      end
    end

    context 'when 同じCSVで再インポートする場合（T006）' do
      it '冪等で削除が発生しない' do
        csv_ab = build_sjis_csv([row_a, row_b])
        importer = described_class.new(csv_ab.path)
        importer.import
        result2 = importer.import
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(result2.deleted).to eq(0)
      end
    end

    context 'when upsert 途中で失敗した場合（T007）' do
      it '削除フェーズを実行せず既存データを維持する' do
        csv_abc = build_sjis_csv([row_a, row_b, row_c])
        described_class.new(csv_abc.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(3)

        csv_ac = build_sjis_csv([row_a, row_c])
        stub_invalid = ActiveRecord::StatementInvalid.new('stub failure')
        allow(JpAddressComplement::PostalCode).to receive(:upsert_all).and_raise(stub_invalid)
        expect do
          described_class.new(csv_ac.path).import
        end.to raise_error(ActiveRecord::StatementInvalid)
        expect(JpAddressComplement::PostalCode.count).to eq(3)
      end
    end

    # --- 003: US2 同一インポートで削除・追加・更新（T012） ---
    context 'when 同一インポートで削除と追加を行う場合（T012）' do
      it '削除・追加・更新が一括で正しく反映され B,C のみ残る' do
        csv_ab = build_sjis_csv([row_a, row_b])
        described_class.new(csv_ab.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(2)

        csv_bc = build_sjis_csv([row_b, row_c])
        result = described_class.new(csv_bc.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(JpAddressComplement::PostalCode.pluck(:postal_code)).to contain_exactly('1000002', '1000003')
        expect(result.upserted).to eq(2)
        expect(result.deleted).to eq(1)
      end
    end
  end
end
