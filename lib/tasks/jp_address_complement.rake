# frozen_string_literal: true

require 'jp_address_complement'
require 'jp_address_complement/importers/csv_importer'

namespace :jp_address_complement do
  desc 'KEN_ALL.CSV から住所データをインポートする（CSV=<ファイルパス>）'
  task import: :environment do
    csv_path = ENV.fetch('CSV', nil)
    if csv_path.nil?
      raise ArgumentError,
            'CSV 環境変数でファイルパスを指定してください（例: rake jp_address_complement:import CSV=/path/to/KEN_ALL.CSV）'
    end

    puts "インポート開始: #{csv_path}"
    count = JpAddressComplement::Importers::CsvImporter.new(csv_path).import
    puts "インポート完了: #{count} 件"
  end
end
