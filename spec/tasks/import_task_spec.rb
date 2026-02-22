# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'tempfile'
require 'csv'
require 'jp_address_complement/ken_all_downloader'

RSpec.describe 'jp_address_complement:import', :db do
  # タスクファイルは1回だけ読み込む（複数回だと同名タスクにブロックが積み重なり、1回の invoke で複数回実行される）
  # rubocop:disable RSpec/BeforeAfterAll -- タスク定義の重複登録を防ぐため意図的に before(:all)
  before(:all) do
    Rake.application.rake_require('tasks/jp_address_complement', [File.expand_path('../../lib', __dir__)], [])
  end
  # rubocop:enable RSpec/BeforeAfterAll

  before do
    Rake::Task.define_task(:environment)
    ENV.delete('CSV')
    ENV.delete('DOWNLOAD')
  end

  after do
    Rake::Task['jp_address_complement:import'].reenable if Rake::Task.task_defined?('jp_address_complement:import')
    ENV.delete('CSV')
    ENV.delete('DOWNLOAD')
  end

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

  let(:row_a) { %w[13101 100 1000001 トウキョウト チヨダク チヨダ 東京都 千代田区 千代田 0 0 0 0 0 0] }

  describe 'タスク実行時（T013）' do
    it '標準出力に upserted/deleted 件数が含まれる' do
      csv_file = build_sjis_csv([row_a])
      ENV['CSV'] = csv_file.path

      stdout = nil
      expect { stdout = capture_stdout { Rake::Task['jp_address_complement:import'].invoke } }.not_to raise_error
      expect(stdout).to include('インポート完了')
      expect(stdout).to match(/upsert.*件|削除.*件/)
    end
  end

  describe 'CSV 未指定時' do
    it 'CSV も DOWNLOAD も指定しないと ArgumentError を出す' do
      expect { Rake::Task['jp_address_complement:import'].invoke }.to raise_error(ArgumentError, /DOWNLOAD=1|CSV=/)
    end
  end

  describe 'DOWNLOAD=1 の場合' do
    it 'KenAllDownloader で取得した CSV をインポートし、download_and_extract は1度だけ呼ばれる' do
      csv_file = build_sjis_csv([row_a])
      downloader = instance_double(
        JpAddressComplement::KenAllDownloader,
        download_and_extract: csv_file.path
      )
      allow(JpAddressComplement::KenAllDownloader).to receive(:new).and_return(downloader)
      allow(downloader).to receive(:download_and_extract).and_return(csv_file.path)

      ENV['DOWNLOAD'] = '1'

      stdout = nil
      expect { stdout = capture_stdout { Rake::Task['jp_address_complement:import'].invoke } }.not_to raise_error
      expect(stdout).to include('ダウンロード中')
      expect(stdout).to include('インポート完了')
      expect(JpAddressComplement::KenAllDownloader).to have_received(:new).once
      expect(downloader).to have_received(:download_and_extract).once
    end
  end

  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end
