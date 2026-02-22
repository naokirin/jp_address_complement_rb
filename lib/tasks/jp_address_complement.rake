# frozen_string_literal: true

require 'jp_address_complement'
require 'jp_address_complement/importers/csv_importer'

# RBS 型定義の生成（research.md §5, FR-005）
# steep/rbs:generate は Rails 不要のため :environment 依存にしない（Rails/RakeEnvironment 除外理由）
namespace :rbs do
  desc 'rbs-inline で sig/ を生成する'
  task generate: [] do
    sh 'bundle exec rbs-inline --output sig/ lib/'
  end
end

# 型チェック（research.md §5, FR-006）
task steep: [] do
  sh 'bundle exec steep check'
end

namespace :jp_address_complement do
  desc 'KEN_ALL.CSV から住所データをインポートする（CSV=<ファイルパス>）'
  task import: :environment do
    csv_path = ENV.fetch('CSV', nil)
    if csv_path.nil?
      raise ArgumentError,
            'CSV 環境変数でファイルパスを指定してください（例: rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV）'
    end

    puts "インポート開始: #{csv_path}"
    result = JpAddressComplement::Importers::CsvImporter.new(csv_path).import
    puts "インポート完了: upsert #{result.upserted} 件, 削除 #{result.deleted} 件"
  end
end
