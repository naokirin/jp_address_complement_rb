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

  let(:valid_utf8_csv) do
    build_utf8_csv([valid_csv_row])
  end

  let(:row_a) { %w[13101 100 1000001 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0] }
  let(:row_b) { %w[13101 100 1000002 トウキョウト チヨダク マルノウチ 東京都 千代田区 丸の内 0 0 0 0 0 0] }
  let(:row_c) { %w[13101 100 1000003 トウキョウト チヨダク オオテマチ 東京都 千代田区 大手町 0 0 0 0 0 0] }

  # 複数行の KEN_ALL 形式 CSV を UTF-8 で作成する
  def build_utf8_csv(rows)
    tf = Tempfile.new(['utf_ken_all', '.csv'])
    tf.binmode
    rows.each do |row|
      line = "#{Array(row).join(',')}\r\n"
      tf.write(line)
    end
    tf.close
    tf
  end

  describe '#import' do
    context 'when 有効な UTF-8 CSV の場合' do
      it 'UTF-8 CSV を読み込んでレコードをインポートする' do
        described_class.new(valid_utf8_csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)
        record = JpAddressComplement::PostalCode.first
        expect(record.postal_code).to eq('1000001')
        expect(record.pref).to eq('東京都')
      end

      it '同じ CSV を2回インポートしても冪等（重複しない）' do
        importer = described_class.new(valid_utf8_csv.path)
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
        csv_abc = build_utf8_csv([row_a, row_b, row_c])
        described_class.new(csv_abc.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(3)

        csv_ac = build_utf8_csv([row_a, row_c])
        described_class.new(csv_ac.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(JpAddressComplement::PostalCode.pluck(:postal_code, :town)).not_to include(%w[1000002 丸の内])
      end
    end

    context 'when 空CSV（有効行0件）の場合（T005）' do
      it 'ImportError を発生させ、既存データを変更しない' do
        described_class.new(valid_utf8_csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)

        empty_csv = build_utf8_csv([])
        expect do
          described_class.new(empty_csv.path).import
        end.to raise_error(JpAddressComplement::ImportError)
        expect(JpAddressComplement::PostalCode.count).to eq(1)
      end
    end

    context 'when 同じCSVで再インポートする場合（T006）' do
      it '冪等で削除が発生しない' do
        csv_ab = build_utf8_csv([row_a, row_b])
        importer = described_class.new(csv_ab.path)
        importer.import
        result2 = importer.import
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(result2.deleted).to eq(0)
      end
    end

    # 同一郵便番号・都道府県・市区町村・町域（漢字）でも読み（カナ）が異なれば別レコードとして扱う
    context 'when 漢字は同じで読み（カナ）だけが異なる行が含まれる場合' do
      it '読みが異なる行を別レコードとしてインポートする' do
        # 兵庫県明石市和坂: カニガサカ と ワサカ の2通り
        row_kanigasaki = %w[28102 673 6730012 ヒョウゴケン アカシシ カニガサカ 兵庫県 明石市 和坂 0 0 0 0 0 0]
        row_wasaka = %w[28102 673 6730012 ヒョウゴケン アカシシ ワサカ 兵庫県 明石市 和坂 0 0 0 0 0 0]
        csv = build_utf8_csv([row_kanigasaki, row_wasaka])
        described_class.new(csv.path).import

        expect(JpAddressComplement::PostalCode.count).to eq(2)
        records = JpAddressComplement::PostalCode.where(postal_code: '6730012', city: '明石市',
                                                        town: '和坂').order(:kana_town)
        expect(records.pluck(:kana_town)).to eq(%w[カニガサカ ワサカ])
      end
    end

    context 'when upsert 途中で失敗した場合（T007）' do
      it '削除フェーズを実行せず既存データを維持する' do
        csv_abc = build_utf8_csv([row_a, row_b, row_c])
        described_class.new(csv_abc.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(3)

        csv_ac = build_utf8_csv([row_a, row_c])
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
        csv_ab = build_utf8_csv([row_a, row_b])
        described_class.new(csv_ab.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(2)

        csv_bc = build_utf8_csv([row_b, row_c])
        result = described_class.new(csv_bc.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(JpAddressComplement::PostalCode.pluck(:postal_code)).to contain_exactly('1000002', '1000003')
        expect(result.upserted).to eq(2)
        expect(result.deleted).to eq(1)
      end
    end

    context 'when バージョン番号付与と古いバージョン一括削除を行う場合' do
      it 'インポートごとにインクリメンタルなバージョンが付与され、古いバージョンのみ一括削除される' do
        csv_ab = build_utf8_csv([row_a, row_b])
        described_class.new(csv_ab.path).import
        expect(JpAddressComplement::PostalCode.distinct.pluck(:version)).to eq([1])

        csv_bc = build_utf8_csv([row_b, row_c])
        result = described_class.new(csv_bc.path).import
        expect(JpAddressComplement::PostalCode.distinct.pluck(:version)).to eq([2])
        expect(JpAddressComplement::PostalCode.count).to eq(2)
        expect(result.deleted).to eq(1) # version 1 の A のみ削除（B は version 2 に更新）
      end
    end

    # branch coverage: parse_row で必須列が nil の行・郵便番号形式不正の行はスキップされ、オプション列が nil の行は取り込まれる
    context 'when 無効行と有効行が混在する CSV の場合' do
      it '必須列不足行と郵便番号形式不正行はスキップし、有効行のみインポートする' do
        # 7列のみの行（city が nil）→ parse_row が nil
        short_row = %w[13101 100 1000001 トウキョウト チヨダク チヨダ 東京都]
        # 郵便番号が7桁でない行 → parse_row が nil
        invalid_postal_row = %w[13101 100 12345 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0]
        # 9列のみ（オプション列が nil になる行）→ 有効
        row_9_cols = %w[13101 100 1000004 トウキョウト チヨダク ヒトツブ 東京都 千代田区 一ツ橋]
        csv = build_utf8_csv([short_row, invalid_postal_row, row_9_cols])
        described_class.new(csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)
        expect(JpAddressComplement::PostalCode.first.postal_code).to eq('1000004')
      end
    end

    # branch coverage: parse_row で row[COL_TOWN] 等が nil になる行（8列のみ）の &._ else ブランチ
    context 'when 8列のみの有効行（町域以降が nil）を含む CSV の場合' do
      it '町域等が nil として取り込まれる' do
        # 8列: 団体コード,旧郵便,郵便番号,都道府県カナ,市区町村カナ,町域カナ,都道府県,市区町村 → row[8]=nil
        row_8_cols = %w[13101 100 1000005 トウキョウト チヨダク チヨダ 東京都 千代田区]
        csv = build_utf8_csv([row_8_cols])
        described_class.new(csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)
        rec = JpAddressComplement::PostalCode.first
        expect(rec.postal_code).to eq('1000005')
        expect(rec.town).to be_nil
      end
    end

    # branch coverage: parse_row で各列が nil の行（row[i]&.strip の else）を通すため、長さ0〜2の行を混在させる
    context 'when 列数が不足した無効行が含まれる場合' do
      it '必須列不足行はスキップし有効行のみインポートする' do
        row_0_cols = []                                                    # row[0]〜nil
        row_1_col = %w[13101]                                              # row[1]〜nil
        row_2_cols = %w[13101 100]                                         # row[2]〜nil
        valid_row = %w[13101 100 1000006 トウキョウト チヨダク サンシ 東京都 千代田区 三崎町 0 0 0 0 0 0]
        csv = build_utf8_csv([row_0_cols, row_1_col, row_2_cols, valid_row])
        described_class.new(csv.path).import
        expect(JpAddressComplement::PostalCode.count).to eq(1)
        expect(JpAddressComplement::PostalCode.first.postal_code).to eq('1000006')
      end
    end
  end
end
