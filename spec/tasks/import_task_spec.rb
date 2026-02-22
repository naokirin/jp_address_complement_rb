# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'tempfile'
require 'csv'

RSpec.describe 'jp_address_complement:import', :db do
  before do
    Rake.application.rake_require('tasks/jp_address_complement', [File.expand_path('../../lib', __dir__)], [])
    Rake::Task.define_task(:environment)
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

  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end
